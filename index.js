

const express = require("express");
const cors = require("cors");
const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Import task routes
const taskRoutes = require("./routes/tasks");

// Use task routes
app.use("/api/tasks", taskRoutes);

// Test route
app.get("/", (req, res) => {
  res.send("Smart Task Backend is running 🚀");
});

const PORT = 3000;
app.listen(3000, "0.0.0.0", () => {
  console.log("Server running on port 3000");
});

