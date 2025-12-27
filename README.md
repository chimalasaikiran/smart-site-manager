# 🚀 Smart Site Task Manager

An intelligent task management system that automatically classifies and prioritizes tasks using keyword-based analysis. Built with Flutter for the frontend and Node.js/Express with Supabase for the backend.

## 📋 Table of Contents

- [Project Overview](#-project-overview)
- [Tech Stack](#-tech-stack)
- [Setup Instructions](#-setup-instructions)
- [API Documentation](#-api-documentation)
- [Database Schema](#-database-schema)
- [Screenshots](#-screenshots)
- [Architecture Decisions](#-architecture-decisions)
- [What I'd Improve](#-what-id-improve)

---

## 🎯 Project Overview

### What I Built

**Smart Site Task Manager** is a full-stack task management application designed for construction site managers and teams. The app goes beyond simple CRUD operations by incorporating **intelligent auto-classification** that analyzes task descriptions and automatically:

- **Categorizes tasks** into relevant categories (Scheduling, Finance, Technical, Safety, General)
- **Assigns priority levels** based on urgency keywords (High, Medium, Low)
- **Suggests next actions** to help users get started quickly

### Why I Built It

Traditional task managers require manual categorization, which is time-consuming and inconsistent. This application solves that by:

1. **Reducing manual work** – Auto-classification eliminates repetitive tagging
2. **Improving consistency** – Keyword-based rules ensure uniform categorization
3. **Enhancing productivity** – Suggested actions provide immediate next steps
4. **Enabling better filtering** – Automatic categories make finding tasks easier

### Key Features

| Feature | Description |
|---------|-------------|
| ✨ Smart Classification | Auto-categorize tasks based on keywords |
| 🎯 Priority Detection | Detect urgency from task descriptions |
| 📱 Beautiful UI | Material 3 design with smooth animations |
| 🔍 Advanced Filtering | Filter by status, category, priority |
| 🔄 Real-time Updates | Instant sync with backend |
| 📊 Task Statistics | Dashboard with task counts by status |

---

## 🛠 Tech Stack

### Frontend (Mobile App)

| Technology | Purpose |
|------------|---------|
| **Flutter 3.x** | Cross-platform mobile framework |
| **Dart** | Programming language |
| **Provider** | State management |
| **Dio** | HTTP client for API calls |
| **Intl** | Date formatting |
| **Material 3** | UI design system |

### Backend (API Server)

| Technology | Purpose |
|------------|---------|
| **Node.js** | Runtime environment |
| **Express.js** | Web framework |
| **Supabase** | PostgreSQL database & auth |
| **Zod** | Schema validation |
| **CORS** | Cross-origin resource sharing |
| **Dotenv** | Environment configuration |

### Database

| Technology | Purpose |
|------------|---------|
| **PostgreSQL** | Primary database (via Supabase) |
| **Supabase** | Database hosting & real-time subscriptions |

### Development Tools

| Tool | Purpose |
|------|---------|
| **VS Code** | IDE |
| **Android Studio** | Android emulator |
| **Postman** | API testing |
| **Git** | Version control |

---

## ⚙️ Setup Instructions

### Prerequisites

- **Node.js** v18+ installed
- **Flutter** 3.x installed and configured
- **Supabase** account with a project created
- **Android Studio** or physical device for testing

### 1. Clone the Repository

```bash
git clone <repository-url>
cd smart_manager_app
```

### 2. Backend Setup

```bash
# Navigate to backend directory
cd smart-task-backend/backend

# Install dependencies
npm install

# Create environment file
cp .env.example .env
```

Edit `.env` with your Supabase credentials:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-anon-key
```

Start the server:

```bash
npm start
# or for development with auto-reload
npm run dev
```

The server will run on `http://localhost:3000`

### 3. Database Setup (Supabase)

Run this SQL in your Supabase SQL Editor:

```sql
-- Create tasks table
CREATE TABLE tasks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    category VARCHAR(50) DEFAULT 'general',
    priority VARCHAR(20) DEFAULT 'low',
    status VARCHAR(20) DEFAULT 'pending',
    assigned_to VARCHAR(255),
    extracted_entities JSONB,
    suggested_actions TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create task_history table for audit logging
CREATE TABLE task_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    task_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
    action VARCHAR(50) NOT NULL,
    old_value JSONB,
    new_value JSONB,
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better query performance
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_category ON tasks(category);
CREATE INDEX idx_tasks_priority ON tasks(priority);
CREATE INDEX idx_task_history_task_id ON task_history(task_id);
```

### 4. Flutter App Setup

```bash
# Navigate to Flutter app directory
cd smart_task_app

# Get dependencies
flutter pub get

# Run on Android emulator (make sure emulator is running)
flutter run
```

**Important:** The app is configured to connect to `http://10.0.2.2:3000/api` which is the Android emulator's way of accessing `localhost` on your machine.

### 5. Verify Setup

1. Backend should show: `Server running on port 3000`
2. Flutter app should display the task list (empty initially)
3. Try creating a task with "urgent meeting tomorrow" - it should auto-classify as "scheduling" with "high" priority

---

## 📡 API Documentation

### Base URL

```
http://localhost:3000/api
```

### Endpoints

#### 1. Get All Tasks

```http
GET /tasks
```

**Query Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `status` | string | Filter by status (pending, in_progress, completed) |
| `category` | string | Filter by category |
| `priority` | string | Filter by priority |
| `search` | string | Search in task titles |
| `limit` | number | Results per page (default: 10) |
| `offset` | number | Pagination offset |
| `sortBy` | string | Sort field (default: created_at) |
| `order` | string | Sort order: asc/desc (default: desc) |

**Response:**

```json
{
  "tasks": [
    {
      "id": "uuid-here",
      "title": "Schedule team meeting",
      "description": "Urgent meeting with team today",
      "category": "scheduling",
      "priority": "high",
      "status": "pending",
      "assigned_to": null,
      "extracted_entities": ["team", "today"],
      "suggested_actions": ["Block calendar", "Send invite"],
      "created_at": "2025-12-27T10:00:00.000Z"
    }
  ],
  "pagination": {
    "total": 15,
    "limit": 10,
    "offset": 0
  }
}
```

#### 2. Create Task

```http
POST /tasks
```

**Request Body:**

```json
{
  "title": "Fix server bug",
  "description": "Critical bug in production server needs immediate fix",
  "category": "technical",
  "priority": "high",
  "status": "pending",
  "assigned_to": "John Doe"
}
```

**Response (201 Created):**

```json
{
  "task": {
    "id": "new-uuid",
    "title": "Fix server bug",
    "description": "Critical bug in production server needs immediate fix",
    "category": "technical",
    "priority": "high",
    "status": "pending",
    "assigned_to": "John Doe",
    "created_at": "2025-12-27T10:30:00.000Z"
  },
  "classification": {
    "auto_category": "technical",
    "auto_priority": "high"
  }
}
```

#### 3. Classify Task (Preview)

```http
POST /tasks/classify
```

**Request Body:**

```json
{
  "title": "Pay invoice",
  "description": "Process payment for contractor invoice ASAP"
}
```

**Response:**

```json
{
  "category": "finance",
  "priority": "high",
  "extracted_entities": {
    "dates": [],
    "persons": ["contractor"],
    "locations": [],
    "actions": []
  },
  "suggested_actions": [
    "Check budget",
    "Get approval",
    "Generate invoice",
    "Update records",
    "Review costs"
  ]
}
```

#### 4. Get Single Task with History

```http
GET /tasks/:id
```

**Response:**

```json
{
  "task": {
    "id": "uuid-here",
    "title": "Task title",
    "description": "Task description",
    "category": "general",
    "priority": "low",
    "status": "pending",
    "created_at": "2025-12-27T10:00:00.000Z"
  },
  "history": [
    {
      "id": "history-uuid",
      "task_id": "uuid-here",
      "action": "created",
      "old_value": null,
      "new_value": { "...task data..." },
      "changed_at": "2025-12-27T10:00:00.000Z"
    }
  ]
}
```

#### 5. Update Task

```http
PUT /tasks/:id
```

or

```http
PATCH /tasks/:id
```

**Request Body:**

```json
{
  "status": "completed",
  "priority": "low"
}
```

**Response:**

```json
{
  "task": {
    "id": "uuid-here",
    "title": "Task title",
    "status": "completed",
    "priority": "low",
    "...": "other fields"
  }
}
```

#### 6. Delete Task

```http
DELETE /tasks/:id
```

**Response:**

```json
{
  "message": "Task deleted successfully"
}
```

### Error Responses

All endpoints return errors in this format:

```json
{
  "error": "Error message here",
  "details": { "...additional info..." }
}
```

| Status Code | Description |
|-------------|-------------|
| 400 | Bad Request - Validation failed |
| 404 | Not Found - Task doesn't exist |
| 500 | Internal Server Error |

---

## 🗄 Database Schema

### Entity Relationship Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                          TASKS                               │
├─────────────────────────────────────────────────────────────┤
│ id                 UUID          PK, DEFAULT gen_random_uuid │
│ title              VARCHAR(255)  NOT NULL                    │
│ description        TEXT          NOT NULL                    │
│ category           VARCHAR(50)   DEFAULT 'general'           │
│ priority           VARCHAR(20)   DEFAULT 'low'               │
│ status             VARCHAR(20)   DEFAULT 'pending'           │
│ assigned_to        VARCHAR(255)  NULLABLE                    │
│ extracted_entities JSONB         NULLABLE                    │
│ suggested_actions  TEXT[]        NULLABLE                    │
│ created_at         TIMESTAMPTZ   DEFAULT NOW()               │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ 1:N
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      TASK_HISTORY                            │
├─────────────────────────────────────────────────────────────┤
│ id                 UUID          PK, DEFAULT gen_random_uuid │
│ task_id            UUID          FK → tasks.id ON DELETE CASCADE │
│ action             VARCHAR(50)   NOT NULL                    │
│ old_value          JSONB         NULLABLE                    │
│ new_value          JSONB         NULLABLE                    │
│ changed_at         TIMESTAMPTZ   DEFAULT NOW()               │
└─────────────────────────────────────────────────────────────┘
```

### Table Descriptions

#### Tasks Table

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | Unique identifier |
| `title` | VARCHAR(255) | NOT NULL | Task title |
| `description` | TEXT | NOT NULL | Detailed description |
| `category` | VARCHAR(50) | DEFAULT 'general' | Auto-classified category |
| `priority` | VARCHAR(20) | DEFAULT 'low' | Task priority level |
| `status` | VARCHAR(20) | DEFAULT 'pending' | Current status |
| `assigned_to` | VARCHAR(255) | NULLABLE | Person responsible |
| `extracted_entities` | JSONB | NULLABLE | AI-extracted entities |
| `suggested_actions` | TEXT[] | NULLABLE | Suggested next steps |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |

#### Task History Table

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | Unique identifier |
| `task_id` | UUID | FOREIGN KEY | Reference to task |
| `action` | VARCHAR(50) | NOT NULL | Action performed |
| `old_value` | JSONB | NULLABLE | Previous state |
| `new_value` | JSONB | NULLABLE | New state |
| `changed_at` | TIMESTAMPTZ | DEFAULT NOW() | When change occurred |

### Enum Values

**Category:**
- `scheduling` - Meetings, deadlines, calendar events
- `finance` - Payments, invoices, budgets
- `technical` - Bugs, installations, maintenance
- `safety` - Inspections, compliance, hazards
- `general` - Everything else

**Priority:**
- `high` - Urgent, requires immediate attention
- `medium` - Important but not urgent
- `low` - Can be done when time permits

**Status:**
- `pending` - Not started
- `in_progress` - Currently being worked on
- `completed` - Finished

---

## 📱 Screenshots

### Home Screen - Task List
<img width="633" height="1107" alt="image" src="https://github.com/user-attachments/assets/1bdf0d9f-0e8d-4513-a701-97caea8ef0c5" />


### Create Task Dialog
<img width="615" height="1116" alt="image" src="https://github.com/user-attachments/assets/f5b415f1-615f-418f-b86c-6584ad27a565" />


### Task Detail View
<img width="597" height="1111" alt="image" src="https://github.com/user-attachments/assets/5eee02e9-6fa6-4417-8b8c-2bc50acdd006" />

### Seraching Task
 <img width="599" height="1105" alt="image" src="https://github.com/user-attachments/assets/9804620c-6ccf-4d01-a06a-024d6650338b" />


---

## 🏗 Architecture Decisions

### 1. State Management: Provider

**Why Provider over Riverpod/Bloc?**

- **Simplicity**: Provider is lightweight and easy to understand
- **Flutter Native**: Recommended by Flutter team for simple-medium apps
- **Less Boilerplate**: Compared to Bloc, requires minimal setup
- **Good Enough**: For this scale, Provider handles state efficiently

```dart
// Clean separation of concerns
class TaskProvider extends ChangeNotifier {
  final ApiService _apiService;
  List<Task> _tasks = [];
  
  Future<void> loadTasks() async {
    _tasks = await _apiService.getTasks();
    notifyListeners();
  }
}
```

### 2. API Client: Dio

**Why Dio over http package?**

- **Interceptors**: Easy logging and error handling
- **Timeout Configuration**: Built-in timeout support
- **Request Cancellation**: Cancel in-flight requests
- **Better Error Types**: More detailed error information

### 3. Backend: Express + Supabase

**Why not Firebase?**

- **PostgreSQL Power**: Complex queries, joins, full SQL support
- **Self-hostable**: Can migrate to own PostgreSQL if needed
- **Better Pricing**: More generous free tier for small projects
- **Real-time Built-in**: WebSocket subscriptions available

**Why Express over Fastify?**

- **Ecosystem**: Larger community and more middleware
- **Familiarity**: Widely known, easier for others to contribute
- **Stability**: Battle-tested in production

### 4. Validation: Zod

**Why Zod over Joi?**

- **TypeScript-first**: Better type inference
- **Smaller Bundle**: Lighter weight
- **Modern API**: Cleaner syntax

```javascript
const taskSchema = z.object({
  title: z.string().min(1),
  description: z.string().min(1),
  status: z.enum(["pending", "in_progress", "completed"]).optional(),
});
```

### 5. Classification: Keyword-Based

**Why not ML/AI?**

- **Simplicity**: Works offline, no API costs
- **Speed**: Instant results, no network latency
- **Predictability**: Deterministic outputs
- **Customizable**: Easy to add new keywords

```javascript
const categoryKeywords = {
  scheduling: ['meeting', 'schedule', 'deadline'],
  finance: ['payment', 'invoice', 'budget'],
  // ...
};
```

### 6. Project Structure

```
smart_task_app/
├── lib/
│   ├── main.dart           # App entry, UI components
│   ├── models/
│   │   └── task.dart       # Data models
│   ├── providers/
│   │   └── task_provider.dart  # State management
│   └── services/
│       └── api_service.dart    # API layer

smart-task-backend/
├── backend/
│   ├── index.js            # Express app setup
│   ├── supabase.js         # Database client
│   ├── routes/
│   │   └── tasks.js        # API endpoints
│   └── utils/
│       └── classify.js     # Classification logic
```

---

## 🚀 What I'd Improve

Given more time, here's what I would add:

### 1. Authentication & Authorization

```javascript
// JWT-based auth with Supabase Auth
app.use('/api/tasks', authenticateToken, taskRoutes);
```

- User registration and login
- Role-based access (Admin, Manager, Worker)
- Task ownership and permissions

### 2. Real-time Updates

```dart
// Supabase real-time subscriptions
supabase
  .from('tasks')
  .stream(primaryKey: ['id'])
  .listen((data) => updateTasks(data));
```

- Live task updates across devices
- Collaborative editing indicators
- Push notifications for assignments

### 3. Offline Support

```dart
// Local database with Hive or SQLite
class TaskRepository {
  final LocalDB _local;
  final ApiService _remote;
  
  Future<List<Task>> getTasks() async {
    try {
      final tasks = await _remote.getTasks();
      await _local.cacheTasks(tasks);
      return tasks;
    } catch (e) {
      return _local.getCachedTasks();
    }
  }
}
```

- Cache tasks locally
- Queue offline changes
- Sync when connection restored

### 4. Advanced Classification (ML)

- TensorFlow Lite for on-device ML
- Fine-tuned model for construction domain
- Learn from user corrections
- Entity recognition (dates, names, amounts)

### 5. Enhanced Features

| Feature | Description |
|---------|-------------|
| **Attachments** | Upload photos, documents |
| **Comments** | Discussion threads on tasks |
| **Subtasks** | Break down complex tasks |
| **Recurring Tasks** | Daily/weekly/monthly schedules |
| **Time Tracking** | Log hours spent on tasks |
| **Reports** | Analytics and productivity insights |
| **Calendar View** | Visualize tasks on calendar |
| **Team Management** | Create teams, assign roles |

### 6. Testing

```dart
// Unit tests
test('Task.fromJson parses correctly', () {
  final json = {'id': '1', 'title': 'Test'};
  final task = Task.fromJson(json);
  expect(task.title, 'Test');
});

// Widget tests
testWidgets('TaskCard displays title', (tester) async {
  await tester.pumpWidget(TaskCard(task: mockTask));
  expect(find.text('Mock Task'), findsOneWidget);
});

// Integration tests
testWidgets('Create task flow', (tester) async {
  // Test full create task journey
});
```

### 7. CI/CD Pipeline

```yaml
# GitHub Actions
name: CI/CD
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter test
      - run: flutter build apk
```

### 8. Performance Optimizations

- Pagination with infinite scroll
- Image lazy loading
- Response caching
- Database query optimization
- Flutter widget optimization (const, keys)

---

## 📄 License

This project is licensed under the MIT License.

---

## 👤 Author

Built with ❤️ as a demonstration of full-stack mobile development skills.

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Supabase for the excellent backend platform
- The open-source community for inspiration
