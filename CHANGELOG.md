# Changelog

## [1.0.0] - 2026-01-23

### Added
- **Credit Card Support**: Dedicated logic for credit card accounts.
    - Card balances are treated as liabilities (Debt).
    - Expenses increase debt, Income/Transfer-In decreases debt.
    - Added `creditLimit` field to Account entity.
- **Detailed Transactions**: Complete details in transaction lists and calendar popup.
    - Shows Category, Subcategory, Account Name, Date, and Time.
- **Custom Branding**: Integrated new particular logo assets.
    - Updated app icons for Android and iOS.
    - Themed app with brand colors from the logo.
- **Dashboard**: "Net Total" balance now correctly accounts for liabilities.

### Fixed
- **UI Overflow**: Fixed keyboard covering fields in "Add Account" sheet.
- **Calendar Details**: Fixed missing details in Calendar transaction popup.
- **List View Errors**: Fixed compilation issues in Transaction List View.

### Changed
- Refactored `TransactionCalendarView` for better state handling.
- Updated `README.md` with professional documentation and structure.
