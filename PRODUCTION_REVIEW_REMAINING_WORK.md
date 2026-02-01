# AR-Sci Production Readiness Review (Remaining Work)

## Overall goal
Make the app production-ready by:
- Removing hardcoded/sample data and placeholder UI behaviors.
- Ensuring all user-facing data comes from Firebase (Firestore/Auth/Storage).
- Enforcing role-based access control (student/teacher/admin) via security rules and/or custom claims.
- Implementing missing functionality flows end-to-end.

> Note: **AR integration is excluded** from this review since it is currently being worked on.

---

## AI implementation status (Assessment generation)

### What works now
- **AI question generation can work** in the Create Assessment screen as long as:
  - You run the app with `--dart-define=TOGETHER_API_KEY=YOUR_KEY`.
  - The Together API is reachable.
- Generated questions are normalized into the existing quiz schema and saved to Firestore:
  - `quizzes/{id}.questions[]` with fields: `id`, `question`, `type`, `options`, `correctAnswer`, `points`.

### What is NOT production-ready yet
- **API key security**: the Together API key is still used from the client app.
  - In production, this key must not be shipped in the mobile app.
  - Recommended: use a Firebase Cloud Function (Callable/HTTPS) as a proxy and store the key in server-side secrets.
- **No end-to-end quiz-taking/submission flow**:
  - The student UI currently only displays questions; it does not allow answering/submitting.
  - There is no confirmed code writing `quiz_results` from the student side.

### Files involved
- `lib/utils/ai_assessment_service.dart`
- `lib/screens/admin/admin_create_quiz_screen.dart`
- `lib/models/quiz_model.dart`
- `lib/screens/student/quiz_detail_screen.dart`

---

# Remaining work by interface

## Student interface (remaining work)

### 1) Implement quiz-taking + submission (core)
- Add a **Take Assessment** flow:
  - Render MCQ / True-False / Fill-in-blank.
  - Timer support (based on `quizzes.duration`).
  - Validate answers and compute score.
  - Save attempt results to Firestore (e.g. `quiz_results`).
  - Prevent multiple submissions if required (policy decision).

**Files**
- `lib/screens/student/quiz_detail_screen.dart` (currently read-only display)
- `lib/screens/student/student_dashboard.dart` (Quizzes tab and Progress tab depend on quiz_results)
- `lib/models/quiz_model.dart`

### 2) Lesson Detail: remove hardcoded content + placeholder progress
- Remove hardcoded volcano topic blocks and placeholders.
- Replace hardcoded progress (`65%`) and static sections with real student progress data.
- Define and implement a progress model, e.g.:
  - `lesson_progress/{studentId}_{lessonId}` or `users/{studentId}/lesson_progress/{lessonId}`
- Implement bookmark/save and continue learning behaviors.

**Files**
- `lib/screens/student/lesson_detail_screen.dart` (contains hardcoded content and placeholder UI)

### 3) Notifications: replace sample list
- Replace sample notifications with Firestore-backed notifications.
- Implement:
  - mark-as-read
  - clear
  - per-role notification types
  - optional Cloud Function triggers (lesson published, quiz published, etc.)

**Files**
- `lib/screens/common/notifications_screen.dart`

### 4) Profile: remove placeholder settings + complete features
- Remove hardcoded controller defaults (`Grade 9`, `Physics`).
- Add display/edit for student `section`.
- Implement:
  - profile photo upload (Firebase Storage)
  - change password flow
  - persistent notification toggle (Firestore)
  - language settings persisted (Firestore or local)

**Files**
- `lib/screens/common/profile_screen.dart`
- `lib/models/user_model.dart`

### 5) Data filtering by student context
- Lessons/quizzes should be filtered by:
  - student grade level
  - student section (if quizzes are assigned per section)
- Current logic shows all published lessons/quizzes.

**Files**
- `lib/screens/student/student_dashboard.dart`

---

## Teacher interface (remaining work)

### 1) Teacher profile/metadata must be real (no placeholders)
- Teachers currently register without a subject, but teacher dashboard displays a subject.
- Decide required teacher fields:
  - `subject` or `subjects[]`
  - `sectionsHandled[]`
- Add onboarding/edit UI and enforce presence.

**Files**
- `lib/screens/common/register_screen.dart`
- `lib/screens/common/profile_screen.dart`
- `lib/screens/teacher/teacher_dashboard.dart`

### 2) Teacher content ownership + scoping
- Teachers should only manage their own learning materials and assessments.
- Ensure `lessons.createdBy` and `quizzes.createdBy` are set and used for filtering.
- Add teacher-specific create screens or permission checks.

**Files**
- `lib/screens/teacher/teacher_dashboard.dart` (`_LessonsManagement`, `_QuizzesManagement` list all)
- `lib/screens/admin/admin_create_lesson_screen.dart` (reused by teacher routes currently)
- `lib/screens/admin/admin_create_quiz_screen.dart` (reused by teacher routes currently)

### 3) Assignments to sections/grades + scheduling
- Add fields to quizzes/lessons for targeting:
  - `assignedSections[]`
  - `assignedGradeLevels[]`
  - `availableFrom`, `dueAt`
- Update student feeds to show only assigned items.

**Files**
- `lib/screens/admin/admin_create_lesson_screen.dart`
- `lib/screens/admin/admin_create_quiz_screen.dart`
- `lib/screens/student/student_dashboard.dart`

### 4) AI generation should be teacher-safe
- If teachers can generate assessments, enforce role checks.
- Move AI request to backend for key security.
- Add rate limiting / usage logging.

**Files**
- `lib/utils/ai_assessment_service.dart`
- (recommended new) Firebase Cloud Function

### 5) Student approvals workflow clarification
- Decide: **Admin-only approval** vs **Teacher approval by section**.
- Implement consistent UX and enforce server-side.

**Files**
- `lib/screens/teacher/student_approval_screen.dart`
- `lib/screens/admin/account_verification_screen.dart`

### 6) Reports should be filtered/scoped
- Score reports currently pull all students and all results.
- Should filter to teacher’s handled students/sections.

**Files**
- `lib/screens/teacher/score_reports_screen.dart`

---

## Admin interface (remaining work)

### 1) Remove hardcoded admin login
- Current admin login is hardcoded (`admin@arsci.com` / `admin123`).
- Replace with Firebase Auth admin accounts.
- Recommended: use **custom claims** (`admin=true`) and enforce in security rules.

**Files**
- `lib/screens/common/login_screen.dart`

### 2) Remove hardcoded dashboard stats
- Admin dashboard uses hardcoded totals and distribution.
- Replace with:
  - Firestore queries or
  - aggregated stats via Cloud Functions (recommended for performance)

**Files**
- `lib/screens/admin/admin_dashboard.dart`

### 3) User deletion must be server-side
- Client cannot reliably delete Firebase Auth users.
- Implement Cloud Function admin endpoint:
  - delete Auth user
  - delete Firestore profile
  - optionally delete related records

**Files**
- `lib/screens/admin/admin_dashboard.dart` (`_deleteUser`)
- (recommended new) Firebase Cloud Function

### 4) Account verification: implement Reject + audit metadata
- Reject button is UI-only (not functional).
- Implement reject behavior (policy decision):
  - delete account, or
  - set `rejectedAt`, `rejectedReason`, prevent login.
- Add search/filter and include grade/section in the UI.

**Files**
- `lib/screens/admin/account_verification_screen.dart`

### 5) Admin Settings page is placeholder
- Academic year is hardcoded (`2025-2026`).
- Implement settings stored in Firestore, e.g. `app_config/current`.

**Files**
- `lib/screens/admin/admin_dashboard.dart` (`_SettingsPage`)

### 6) Content management naming consistency
- UI mixes “Quiz” vs “Assessment” in several places.
- Standardize terminology across admin/teacher/student.

**Files**
- `lib/screens/admin/admin_dashboard.dart`
- `lib/screens/admin/admin_create_quiz_screen.dart`
- `lib/screens/teacher/teacher_dashboard.dart`

---

# Cross-cutting production readiness tasks

## A) Firestore Security Rules + indexes (required)
- Repository currently lacks Firestore rules files.
- Add rules to enforce:
  - Only admins can verify accounts / manage users
  - Teachers can create/update only their own lessons/quizzes
  - Students can only read assigned/published content
  - Students can only write their own `quiz_results`

**Files**
- (missing) `firestore.rules`
- (missing) Firebase project config

## B) Remove legacy/unused constants and secrets
- `AppConstants` includes unrelated/legacy fields and a hardcoded Google API key.
- Remove unused constants and any keys from source; use environment config.

**Files**
- `lib/utils/constants.dart`

## C) Use server timestamps + consistent date formats
- Many places use `DateTime.now().toIso8601String()`.
- Prefer `FieldValue.serverTimestamp()` for createdAt/updatedAt.

**Files**
- `lib/screens/common/register_screen.dart`
- `lib/screens/admin/admin_create_lesson_screen.dart`
- `lib/screens/admin/admin_create_quiz_screen.dart`
- `lib/screens/admin/account_verification_screen.dart`

## D) Notifications + activity feeds should be real
- Teacher/Admin “activity” should not scan entire collections without scoping.
- Implement a proper `notifications` collection and/or `activity_logs`.

**Files**
- `lib/screens/common/notifications_screen.dart`
- `lib/screens/teacher/teacher_dashboard.dart`

## E) Clean up placeholder UI and empty handlers
- Remove/implement empty `onTap` / `onPressed` and placeholder widgets (download, image placeholder, etc.).

**Files**
- `lib/screens/student/lesson_detail_screen.dart`
- `lib/screens/common/profile_screen.dart`
- `lib/screens/common/notifications_screen.dart`

---

## Suggested next deliverables (recommended order)
1) Implement quiz-taking + submission + `quiz_results` writes (student).
2) Replace hardcoded admin login and move privileged actions to admin accounts.
3) Add Firestore security rules + Cloud Functions for privileged actions.
4) Replace all remaining hardcoded dashboard stats and placeholder screens.
5) Replace AppConstants lesson seeds with real Firestore content only.

