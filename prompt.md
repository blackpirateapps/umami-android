**Role:** You are a Lead Software Architect specializing in Flutter systems design, reactive programming, and secure API integration.

**Objective:** 
Architect the core logic and backend integration for an Android application that interfaces with the **Umami Analytics REST API v2**. The goal is to build a high-performance, type-safe, and offline-capable data engine using **Clean Architecture** principles. This implementation must prioritize data consistency, efficient memory management, and strict separation of concerns.

---

### 1. Core Technical Stack
The implementation must strictly adhere to these libraries and patterns:
*   **Architecture:** Clean Architecture (Domain, Data, and Presentation layers).
*   **State Management:** `flutter_riverpod` using `@riverpod` code generation for high-performance dependency injection and reactive caching.
*   **Networking:** `dio` with a centralized singleton client.
*   **Data Modeling:** `freezed` for immutable data classes and `json_serializable` for type-safe JSON parsing.
*   **Persistence:** `drift` (SQLite) or `hive` for local caching of analytics data to support offline viewing.
*   **Security:** `flutter_secure_storage` for encrypted storage of JWTs and API endpoints.

---

### 2. Architectural Layer Requirements

#### A. Data Layer (Infrastructure)
*   **Repository Pattern:** Implement repositories that abstract the data source (Remote vs. Local). Use a "Cache-First, Network-Update" strategy.
*   **API Client:** Create a robust `Dio` wrapper.
    *   **Interceptors:** Must include an `AuthInterceptor` to refresh tokens and a `RetryInterceptor` for transient network failures (using exponential backoff).
    *   **Transformers:** Implement a custom transformer if large JSON payloads from Umami (like raw pageview logs) cause UI jank.
*   **Mappers:** Provide explicit `Mapper` classes to convert DTOs (Data Transfer Objects) from the API into Domain Entities used by the business logic.

#### B. Domain Layer (Business Logic)
*   **Entities:** Define pure Dart classes for `Website`, `SessionStats`, `MetricReport`, and `RealtimeData`.
*   **Use Cases (Interactors):** Define granular classes for specific actions (e.g., `GetWebsiteStatsUseCase`, `AuthenticateUserUseCase`, `SyncWebsiteDataUseCase`). This ensures the logic is testable in isolation.

#### C. State Layer (Application Logic)
*   **Reactive Providers:** Utilize Riverpod's `AsyncNotifier` to handle the lifecycle of data fetching.
*   **Data Pagination:** Implement logic for fetching "Top Pages" or "Referrers" using a cursor-based or offset-based approach as required by the Umami API.

---

### 3. API & Data Logic Specification
Implement logic for the following Umami v2 endpoints with strict error handling:
*   **Auth Flow:** `/api/auth/login` to retrieve the JWT. Logic must handle token expiration and re-authentication without user intervention.
*   **Aggregated Stats:** `/api/websites/{websiteId}/stats` (unique visitors, pageviews, bounce rate).
*   **TimeSeries Data:** `/api/websites/{websiteId}/pageviews` for graphing. The logic must normalize timestamps to the user's local timezone.
*   **Metrics:** `/api/websites/{websiteId}/metrics` (filtering by `url`, `referrer`, `browser`, `os`, `device`, and `country`).

---

### 4. Technical Constraints & Decisions
*   **Strict Typing:** Avoid `Map<String, dynamic>` in the business logic. Use Freezed models exclusively.
*   **Concurrency:** Use `Future.wait()` for concurrent API calls (e.g., fetching stats and metrics simultaneously) to reduce dashboard load times.
*   **Memory Management:** Ensure streams are closed and listeners are disposed of. Use Riverpod's `.autoDispose` to clear data from memory when the user navigates away from a specific website's dashboard.
*   **Global Error Handling:** Implement a functional error-handling pattern (e.g., an `Either<Failure, Success>` type) to ensure exceptions don't crash the app and are handled gracefully at the UI level.


---

### Design
Use the shadcn-ui-flutter skill to make the app design. It should follow the shadcn ui. 
---


### 5. Expected Deliverables
Provide a structured codebase including:
1.  **Directory Structure:** A clear separation of `domain/`, `data/`, and `application/` folders.
2.  **Model Definitions:** Freezed classes for the Umami API responses.
3.  **The ApiService:** A complete Dio implementation with interceptors.
4.  **The Repository Implementation:** Logic for fetching from the API and caching to the local database.
5.  **State Management:** A Riverpod provider that orchestrates a multi-endpoint fetch to build a complete "Dashboard State."

---

### Finalization
- Generate an AI handoff document for future agents so they do not have to analyze the code. 
- Make a githhub workflow file that builds the release apk with a generated keystore. 
- Flutter is not installed here so you have to make the scaffolding in the workflow as well. 
- commit all the changes including local changes and push. 
