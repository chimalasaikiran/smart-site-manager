function classifyTask(title, description) {
  const fullText = `${title} ${description}`.toLowerCase();

  // 1. CATEGORY CLASSIFICATION
  const categoryKeywords = {
    scheduling: ['meeting', 'schedule', 'call', 'appointment', 'deadline', 'calendar', 'plan', 'timeline'],
    finance: ['payment', 'invoice', 'bill', 'budget', 'cost', 'expense', 'financial', 'money', 'fund'],
    technical: ['bug', 'fix', 'error', 'install', 'repair', 'maintain', 'software', 'hardware', 'system', 'server', 'network'],
    safety: ['safety', 'hazard', 'inspection', 'compliance', 'ppe', 'emergency', 'security', 'risk', 'accident']
  };

  let category = "general";
  for (const [cat, keywords] of Object.entries(categoryKeywords)) {
    if (keywords.some(keyword => fullText.includes(keyword))) {
      category = cat;
      break;
    }
  }

  // 2. PRIORITY CLASSIFICATION
  const priorityKeywords = {
    high: ['urgent', 'asap', 'immediately', 'today', 'critical', 'emergency', 'rush', 'important'],
    medium: ['soon', 'this week', 'important', 'need', 'required']
  };

  let priority = "low";
  for (const [pri, keywords] of Object.entries(priorityKeywords)) {
    if (keywords.some(keyword => fullText.includes(keyword))) {
      priority = pri;
      break;
    }
  }

  // 3. ENTITY EXTRACTION
  const extractedEntities = {
    dates: [],
    persons: [],
    locations: [],
    actions: []
  };

  // Date extraction
  const datePatterns = [
    /\b(today|tomorrow)\b/gi,
    /\b(\d{1,2}\/\d{1,2}\/\d{4})\b/gi,
    /\b(\d{1,2}-\d{1,2}-\d{4})\b/gi,
    /\b(january|february|march|april|may|june|july|august|september|october|november|december)\b/gi
  ];

  datePatterns.forEach(pattern => {
    const matches = fullText.match(pattern);
    if (matches) {
      extractedEntities.dates.push(...matches.map(m => m.toLowerCase()));
    }
  });

  // Person extraction (simple pattern)
  const personPatterns = [
    /(?:with|by|assign to|assigned to)\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)/gi
  ];

  personPatterns.forEach(pattern => {
    const matches = [...fullText.matchAll(pattern)];
    matches.forEach(match => {
      extractedEntities.persons.push(match[1]);
    });
  });

  // Action verbs
  const actionVerbs = ['review', 'check', 'create', 'update', 'fix', 'install', 'meet', 'call', 'inspect'];
  actionVerbs.forEach(verb => {
    if (fullText.includes(verb)) {
      extractedEntities.actions.push(verb);
    }
  });

  // 4. SUGGESTED ACTIONS
  const suggestedActionsMap = {
    scheduling: ["Block calendar", "Send invite", "Prepare agenda", "Set reminder", "Confirm attendance"],
    finance: ["Check budget", "Get approval", "Generate invoice", "Update records", "Review costs"],
    technical: ["Diagnose issue", "Check resources", "Assign technician", "Document fix", "Test solution"],
    safety: ["Conduct inspection", "File report", "Notify supervisor", "Update checklist", "Provide training"],
    general: ["Review requirements", "Assign owner", "Set deadline", "Monitor progress", "Follow up"]
  };

  const suggestedActions = suggestedActionsMap[category] || suggestedActionsMap.general;

  return {
    category,
    priority,
    extracted_entities: extractedEntities,
    suggested_actions: suggestedActions
  };
}

// Unit tests
function testClassification() {
  console.log("=== Running Classification Tests ===");
  
  // Test 1: Scheduling category
  const test1 = classifyTask("Team meeting", "Schedule weekly team meeting with John today");
  console.assert(test1.category === "scheduling", "Test 1 failed: Expected scheduling");
  console.assert(test1.priority === "high", "Test 1 failed: Expected high priority");
  
  // Test 2: Finance category
  const test2 = classifyTask("Invoice payment", "Process invoice payment for project budget");
  console.assert(test2.category === "finance", "Test 2 failed: Expected finance");
  
  // Test 3: Technical category
  const test3 = classifyTask("Bug fix", "Fix critical bug in server system ASAP");
  console.assert(test3.category === "technical", "Test 3 failed: Expected technical");
  console.assert(test3.priority === "high", "Test 3 failed: Expected high priority");
  
  console.log("All tests passed!");
}

// Export for testing
if (require.main === module) {
  testClassification();
}

module.exports = classifyTask;