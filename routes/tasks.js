const express = require("express");
const router = express.Router();
const { z } = require("zod");
const supabase = require("../supabase");
const classifyTask = require("../utils/classify");

// Validation Schemas
const taskSchema = z.object({
  title: z.string().min(1, "Title is required"),
  description: z.string().min(1, "Description is required"),
  status: z.enum(["pending", "in_progress", "completed"]).optional(),
  category: z.string().optional(),
  priority: z.string().optional(),
  assigned_to: z.string().optional().nullable(),
  due_date: z.string().optional().nullable(),
});

// Save task history
async function saveHistory(taskId, action, oldValue, newValue) {
  try {
    await supabase.from("task_history").insert([
      {
        task_id: taskId,
        action,
        old_value: oldValue,
        new_value: newValue,
        changed_at: newValue?.updated_at || new Date().toISOString(),
      },
    ]);
  } catch (e) {
    console.error("Failed to save history:", e);
  }
}

// ======================
// CLASSIFY TASK (PREVIEW)
// ======================
router.post("/classify", async (req, res) => {
  try {
    const { title, description } = req.body;
    if (!title && !description) {
      return res.status(400).json({ error: "Title or description required" });
    }

    const classification = classifyTask(title || "", description || "");
    res.json(classification);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ======================
// CREATE TASK
// ======================
router.post("/", async (req, res) => {
  try {
    console.log("Create task request body:", JSON.stringify(req.body, null, 2));
    
    const validatedData = taskSchema.parse(req.body);
    const { title, description, status, category, priority, assigned_to, due_date } = validatedData;

    // Auto-classification
    let classification;
    try {
      classification = classifyTask(title, description);
    } catch (classifyError) {
      console.error("Classification error:", classifyError);
      classification = {
        category: "general",
        priority: "low",
        extracted_entities: {},
        suggested_actions: []
      };
    }

    const taskData = {
      title,
      description,
      category: category || classification.category,
      priority: priority || classification.priority,
      status: status || "pending",
      assigned_to: assigned_to || null,
    };

    console.log("Inserting task data:", JSON.stringify(taskData, null, 2));

    const { data, error } = await supabase
      .from("tasks")
      .insert([taskData])
      .select()
      .single();

    if (error) {
      console.error("Supabase Insert Error:", error);
      return res.status(500).json({ error: error.message, details: error });
    }

    console.log("Task created successfully:", data.id);

    res.status(201).json({ 
      task: data,
      classification: {
        auto_category: classification.category,
        auto_priority: classification.priority
      }
    });
  } catch (error) {
    console.error("Create Task Error:", error);
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: error.errors[0].message });
    }
    res.status(500).json({ error: error.message });
  }
});

// ======================
// GET ALL TASKS
// ======================
router.get("/", async (req, res) => {
  try {
    const { status, category, priority, search, limit = 10, offset = 0, sortBy = 'created_at', order = 'desc' } = req.query;

    let query = supabase.from("tasks").select("*", { count: 'exact' });

    // Filtering
    if (status && status !== 'all') query = query.eq("status", status);
    if (category && category !== 'all') query = query.eq("category", category);
    if (priority && priority !== 'all') query = query.eq("priority", priority);
    if (search) query = query.ilike("title", `%${search}%`);

    // Pagination & Sorting
    query = query
      .order(sortBy, { ascending: order === 'asc' })
      .range(parseInt(offset), parseInt(offset) + parseInt(limit) - 1);

    const { data, error, count } = await query;

    if (error) {
      console.error("Supabase Fetch Error:", error);
      throw error;
    }

    res.json({
      tasks: data || [],
      pagination: {
        total: count || 0,
        limit: parseInt(limit),
        offset: parseInt(offset)
      }
    });
  } catch (error) {
    console.error("Get Tasks Error:", error);
    res.status(500).json({ error: error.message });
  }
});

// ======================
// GET TASK DETAILS WITH HISTORY
// ======================
router.get("/:id", async (req, res) => {
  try {
    const { id } = req.params;

    const { data: task, error: taskError } = await supabase
      .from("tasks")
      .select("*")
      .eq("id", id)
      .single();

    if (taskError) return res.status(404).json({ error: "Task not found" });

    const { data: history, error: historyError } = await supabase
      .from("task_history")
      .select("*")
      .eq("task_id", id)
      .order("changed_at", { ascending: false });

    res.json({
      task,
      history: history || []
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ======================
// UPDATE TASK (PUT/PATCH)
// ======================
const updateHandler = async (req, res) => {
  try {
    const { id } = req.params;
    const validatedData = taskSchema.partial().parse(req.body);

    // Get old task for history
    const { data: oldTask, error: fetchError } = await supabase
      .from("tasks")
      .select("*")
      .eq("id", id)
      .single();

    if (fetchError) return res.status(404).json({ error: "Task not found" });

    const updateData = {
      ...validatedData,
      updated_at: new Date().toISOString()
    };

    const { data, error } = await supabase
      .from("tasks")
      .update(updateData)
      .eq("id", id)
      .select()
      .single();

    if (error) throw error;

    // Determine action type
    let action = "updated";
    if (validatedData.status && validatedData.status !== oldTask.status) {
      action = validatedData.status === "completed" ? "completed" : "status_changed";
    }

    await saveHistory(id, action, oldTask, data);

    res.json({ task: data });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ error: error.errors[0].message });
    }
    res.status(500).json({ error: error.message });
  }
};

router.put("/:id", updateHandler);
router.patch("/:id", updateHandler);

// ======================
// DELETE TASK
// ======================
router.delete("/:id", async (req, res) => {
  try {
    const { id } = req.params;

    // Delete history first (or let DB handle via cascade if configured)
    await supabase.from("task_history").delete().eq("task_id", id);

    const { error } = await supabase
      .from("tasks")
      .delete()
      .eq("id", id);

    if (error) throw error;

    res.json({ message: "Task deleted successfully" });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
