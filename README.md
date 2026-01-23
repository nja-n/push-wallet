🪙 Expense Tracker Pro
A professional Flutter accounting application designed for high maintainability, scalability, and local-first performance. This project utilizes Clean Architecture, Domain-Driven Design (DDD), and SOLID principles to ensure a robust codebase.

📑 Table of Contents
Architecture

Key Features

Project Structure

Tech Stack

Getting Started

Principles Followed

🏛 Architecture
The project follows Clean Architecture with a Feature-First organization. This separates the core business logic from UI and external framework dependencies, making it easier to swap local storage for a cloud backend later.

Domain Layer: The heart of the app. Contains Entities, Use Cases, and Repository interfaces. It has zero dependencies on other layers.

Data Layer: Handles data persistence and external APIs. Implements the repository interfaces defined in the Domain.

Presentation Layer: Pure UI and State Management (BLoC/Cubit). Widgets here are "dumb" and only reflect the current state.

✨ Key Features
Local-First Persistence: Lightning-fast accounting records using the Isar database.

Transaction Management: Track income and expenses with detailed categorization.

Account Tracking: Manage multiple accounts (Cash, Bank, Credit Cards) with real-time balance updates.

Reactive UI: Real-time state updates using the BLoC pattern.

📁 Project Structure
Plaintext
lib/
├── core/                # Shared utilities, common errors, and base classes
├── features/            # Bounded Contexts (DDD)
│   ├── transactions/    # Income and Expense feature
│   │   ├── domain/      # Business logic (Entities, UseCases)
│   │   ├── data/        # Infrastructure (Models, Repositories, DB)
│   │   └── presentation/# UI (BLoC, Pages, Widgets)
│   └── accounts/        # Account management feature
└── main.dart            # App entry point & Dependency Injection setup
🛠 Tech Stack
Framework: Flutter

State Management: flutter_bloc

Local Database: Isar

Dependency Injection: GetIt

Data Models: Freezed (Immutability & Union Types)

Functional Programming: Dartz (Either for Error Handling)

🚀 Getting Started
Prerequisites
Flutter SDK (v3.x or higher)

Dart SDK (v3.x or higher)

Installation
Clone the repository:

Bash
git clone https://github.com/yourusername/expense-tracker.git
Install dependencies:

Bash
flutter pub get
Run code generation (for Freezed/Isar models):

Bash
dart run build_runner build --delete-conflicting-outputs
Run the application:

Bash
flutter run
💎 Principles Followed
SOLID: Every class has a single responsibility and depends on abstractions rather than concrete implementations.

Unidirectional Data Flow: Data flows from Data Source → Repository → Use Case → BLoC → UI.

Immutability: All domain entities are immutable to prevent unintended state side-effects.