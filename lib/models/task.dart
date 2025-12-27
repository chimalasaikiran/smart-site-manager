class Task {
  final String id;
  final String title;
  final String description;
  final String category;
  final String priority;
  final String status;
  final String? assignedTo;
  final DateTime? dueDate;
  final Map<String, dynamic>? extractedEntities;
  final List<String>? suggestedActions;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    this.assignedTo,
    this.dueDate,
    this.extractedEntities,
    this.suggestedActions,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    // Handle extracted_entities which can be a Map or List
    Map<String, dynamic>? entities;
    if (json['extracted_entities'] is Map) {
      entities = Map<String, dynamic>.from(json['extracted_entities']);
    } else if (json['extracted_entities'] is List) {
      entities = {'items': json['extracted_entities']};
    }

    // Handle suggested_actions
    List<String>? actions;
    if (json['suggested_actions'] is List) {
      actions = List<String>.from(json['suggested_actions']);
    }

    return Task(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'general',
      priority: json['priority'] ?? 'low',
      status: json['status'] ?? 'pending',
      assignedTo: json['assigned_to'],
      dueDate:
          json['due_date'] != null ? DateTime.tryParse(json['due_date']) : null,
      extractedEntities: entities,
      suggestedActions: actions,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'status': status,
      'assigned_to': assignedTo,
      'due_date': dueDate?.toIso8601String(),
    };
  }
}
