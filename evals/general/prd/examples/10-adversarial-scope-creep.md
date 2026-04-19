# Scope Decomposition: To-Do List Application

The request lists 35+ features spanning at least 6 independent subsystems. Shipping all of this as a single PRD would be unmanageable — no clear priorities, no phased delivery, and no way to measure success incrementally. Below is a scope decomposition into independent PRDs, followed by the first PRD (Core Task Management).

## Scope Map

| PRD | Subsystem | Features | Dependencies |
|-----|-----------|----------|-------------|
| **PRD-001** | Core Task Management | Tasks, subtasks, due dates, reminders, recurring tasks, tags, projects | None — foundation |
| PRD-002 | Collaboration | Shared lists, comments on tasks, file attachments, team workspaces | PRD-001 |
| PRD-003 | Views & Visualization | Calendar view, Kanban board, Gantt chart | PRD-001 |
| PRD-004 | Productivity Tools | Time tracking, Pomodoro timer, focus mode with ambient sounds | PRD-001 |
| PRD-005 | Personal Wellness | Habit tracking, goal setting, daily journaling, mood tracking | PRD-001 (loose) |
| PRD-006 | AI & Automation | AI task prioritization, natural language task creation, email-to-task | PRD-001 |
| PRD-007 | Integrations | Slack, Zapier, browser extension, third-party API | PRD-001 |
| PRD-008 | Platform & Security | Offline mode, E2E encryption, RBAC, audit logs, SSO, mobile apps | PRD-001, PRD-002 |

**Recommendation**: Ship PRD-001 first — everything else depends on it. PRD-002 and PRD-003 are the next highest-value items (collaboration and views are table-stakes for any modern task app). PRDs 004–008 are differentiators that can be prioritized based on user feedback after launch.

**Scope concern**: PRD-005 (Personal Wellness) is a different product category entirely — habit tracking, journaling, and mood tracking have different personas, retention loops, and success metrics than task management. Consider whether this belongs in this product or is a separate app.

---

# PRD-001: Core Task Management

- **ID**: PRD-001
- **Status**: Draft
- **Author**: —
- **Created**: 2026-04-19
- **Last Updated**: 2026-04-19

## Problem

People manage tasks across scattered tools — sticky notes, email drafts, spreadsheets, generic note apps — because existing to-do apps are either too simple (no subtasks, no recurring tasks) or too complex (project management tools with steep learning curves). Users lose track of tasks, miss deadlines, and waste time context-switching between tools. They need a task manager that handles the complexity of real work (nested tasks, recurring schedules, flexible organization) without the overhead of enterprise project management.

## Personas & Use Cases

- **Individual Professional** (manages personal and work tasks): Juggles 20–50 active tasks across work projects and personal errands. Needs subtasks to break down complex items, recurring tasks for routines (weekly reports, bill payments), and reminders to surface time-sensitive work. Currently uses a mix of apps and loses tasks between them.
- **Freelancer/Contractor** (manages tasks across multiple clients): Organizes work by project (one per client). Needs tags to cross-cut projects (e.g., tag "invoicing" spans multiple client projects). Needs due dates and reminders that account for multiple concurrent deadlines.
- **Student** (manages coursework and personal tasks): Organizes by course/subject. Heavy use of due dates and reminders for assignments. Needs subtasks to break down multi-step projects (research → outline → draft → submit). Budget-conscious — free tier must be functional.

## Goals & Scope

- **Must have**: Create, edit, delete, and complete tasks. Subtasks (one level of nesting). Due dates with date and optional time. Reminders — at least one reminder per task, triggered by time. Recurring tasks — daily, weekly, monthly, custom intervals. Tags — user-created, multiple per task. Projects — group tasks into projects; a task belongs to one project. Inbox — uncategorized tasks land here for later triage.
- **Should have**: Task notes/description field (plain text). Drag-and-drop reordering within a project. Bulk actions (complete, move, tag multiple tasks). Quick-add — create a task with minimal friction (title only, refine later).
- **Non-goals**: Shared lists and collaboration — PRD-002. Comments and file attachments — PRD-002. Calendar, Kanban, and Gantt views — PRD-003. Time tracking and Pomodoro — PRD-004. AI features — PRD-006. Integrations — PRD-007. Offline mode, encryption, SSO — PRD-008.

## User Stories

- As an **Individual Professional**, I want to create a task with subtasks so that I can break down a complex item into actionable steps and track progress.
  - **Acceptance**: A task can have 0–20 subtasks. Completing all subtasks does not auto-complete the parent (user controls when it's done). Parent task shows progress (e.g., "3/5 subtasks complete"). Subtasks cannot have their own subtasks (one level only).
  - **Scenario**: User creates task "Prepare quarterly review." Adds subtasks: "Gather metrics," "Draft slides," "Schedule meeting room," "Send invite." Completes "Gather metrics" — parent shows 1/4. Completes all four subtasks, then manually marks the parent task complete.

- As a **Freelancer**, I want to set up a recurring task so that weekly routines appear automatically without me recreating them.
  - **Acceptance**: Recurring options: daily, weekly (specific days), monthly (specific date), custom interval (every N days). When a recurring task is completed, the next occurrence is automatically created with the same title, project, tags, and subtask structure. Due date advances by the recurrence interval.
  - **Scenario**: Freelancer creates "Send weekly invoice" recurring every Friday. Completes this Friday's instance. A new task "Send weekly invoice" appears due next Friday with the same project ("Client A") and tag ("invoicing"). Subtasks ("Export hours," "Generate PDF," "Email client") are recreated uncompleted.

- As a **Student**, I want to set a reminder for a task so that I'm alerted before the deadline.
  - **Acceptance**: At least one reminder per task, configured as a specific date/time or relative to due date (e.g., "1 day before"). Reminder triggers a notification (delivery channel defined in PRD-008). If no due date, reminder is absolute time only.
  - **Scenario**: Student creates task "Submit essay" due Friday at 11:59 PM. Sets reminder for Thursday at 6 PM. Thursday at 6 PM, receives a notification: "Reminder: Submit essay — due tomorrow at 11:59 PM." 

- As an **Individual Professional**, I want to tag tasks across projects so that I can view all tasks related to a topic regardless of which project they belong to.
  - **Acceptance**: Tags are user-created, freeform text. A task can have 0–10 tags. Filtering by tag shows tasks across all projects. Tags are not hierarchical.
  - **Scenario**: User has projects "Work" and "Personal." Tags task "Renew passport" (Personal) and "Update employee records" (Work) both with tag "admin." Filters by "admin" tag — sees both tasks from different projects in one list.

## Behavioral Boundaries

- **Task limits**: Maximum 10,000 active (non-completed) tasks per account. At 9,000, show a notice: "Approaching task limit — consider completing or archiving tasks." At 10,000, task creation is blocked with: "Task limit reached. Complete or archive existing tasks to create new ones."
- **Subtask depth**: One level only. Attempting to add a subtask to a subtask shows: "Subtasks can't have their own subtasks. Consider making this a separate task instead."
- **Recurring task generation**: Only the next occurrence is generated (not an infinite series). The next occurrence is created when the current one is completed — never generates more than one future instance.
- **Tag limits**: Maximum 10 tags per task. Maximum 500 unique tags per account.
- **Project limits**: Maximum 50 active projects per account.

## Non-Functional Requirements

- **Performance**: Task list loads in < 1 second with up to 500 visible tasks. Task creation (including with subtasks, tags, and recurrence) completes in < 500ms. Search across all tasks returns results in < 1 second.
- **Reliability**: Data durability — no task data loss under any circumstance. If the app crashes mid-edit, the last saved state is preserved.
- **Scalability**: Support up to 100,000 users, each with up to 10,000 active tasks (1 billion task ceiling).

## Risks & Open Questions

- **Risk**: One level of subtask nesting may frustrate power users who want deeper hierarchies — likelihood: M — mitigation: monitor feature requests post-launch; one level covers 90% of use cases without UX complexity. Deeper nesting can be a future PRD.
- **Risk**: Recurring task behavior varies across competitors — users bring expectations from other apps — likelihood: M — mitigation: document recurring behavior clearly in the UI; start with simple patterns and expand.
- [ ] Should completed tasks be archived automatically after N days, or only manually? Auto-archive keeps the active list clean but may surprise users.
- [ ] Should tags have colors? Useful for visual scanning but adds UI complexity.
- [ ] Should "Inbox" be a real project or a virtual view of unassigned tasks?

## Success Metrics

- Activation: 50% of new signups create ≥ 5 tasks in their first week
- Retention: 30-day retention ≥ 40% for users who create a project and recurring task
- Engagement: Average daily active tasks per user ≥ 10 after 30 days
- Core usage: ≥ 30% of users use subtasks; ≥ 20% use recurring tasks within first month
