# 🪙 Expense Tracker Pro

A professional, local-first accounting application built with Flutter. Designed for maintainability, scalability, and performance using Clean Architecture and Domain-Driven Design (DDD).

---

## 🏛 Architecture

We follow **Clean Architecture** with a Feature-First organization, ensuring decoupling and testability.

- **Domain Layer**: Core Business Logic (Entities, UseCases). Zero external dependencies.
- **Data Layer**: Repositories, Data Sources, APIs, and DB implementation.
- **Presentation Layer**: UI Widgets, Pages, and State Management (BLoC).

## ✨ Key Features

- **Local-First Persistence**: Powered by [Isar](https://isar.dev) for lightning-fast database performance.
- **Smart Accounting**: Track multiple accounts including **Cash**, **Bank**, and **Credit Cards** (with liability logic).
- **Transaction Management**: Detailed Income, Expense, and Transfer tracking.
- **Analytics**: Real-time Dashboard and Monthly Calendar views.
- **Theming**: Elegant UI with custom Light/Dark mode support (System Default).

## 📁 Project Structure

```
lib/
├── core/                # Shared utilities, extensions, failures
├── features/            # Feature modules (DDD)
│   ├── transaction/     # Transaction logic & UI
│   ├── account/         # Account management
│   ├── category/        # Category management
│   ├── home/            # Dashboard & Navigation
│   └── settings/        # App preferences
└── main.dart            # Entry point & DI
```

## 🛠 Tech Stack

| Component | Technology |
|-----------|------------|
| **Framework** | [Flutter](https://flutter.dev) |
| **State Management** | [flutter_bloc](https://pub.dev/packages/flutter_bloc) |
| **Database** | [Isar](https://pub.dev/packages/isar) |
| **DI** | [GetIt](https://pub.dev/packages/get_it) |
| **FP** | [fpdart](https://pub.dev/packages/fpdart) & [dartz](https://pub.dev/packages/dartz) |
| **Code Gen** | [build_runner](https://pub.dev/packages/build_runner), [hive](https://pub.dev/packages/hive) |

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.x+)
- Dart SDK (3.x+)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/expense-tracker.git
   cd expense-tracker
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate Code** (required for Hive/Isar adapters)
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run**
   ```bash
   flutter run
   ```

## 💎 Design Principles

- **SOLID Principles**: Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, Dependency Inversion.
- **Unidirectional Data Flow**: UI -> Event -> BLoC -> UseCase -> Repository -> Data.
- **Immutability**: Entities and States are immutable.

---
*Built with ❤️ by Aeither Dev and AI Assistant.*