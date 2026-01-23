# Changelog

## [1.0.0] - 2026-01-23

### Added
- **Data Management**: Added Backup and Restore functionality.
    - Export all app data (Accounts, Transactions, Categories, Settings) to a secure JSON file.
    - Restore data from a backup file (overwrites current data).
    - Auto Backup toggle (simulated/ready for background implementation).
- **Transaction Management**: Added ability to **Edit** and **Delete** transactions.
    - Updates and Deletions automatically adjust account balances.
    - **UI**: Swipe to Delete (with confirmation), Tap to Edit.
- **Credit Card Support**: Dedicated logic for credit card accounts.
    - Card balances are treated as liabilities (Debt).
    - Expenses increase debt, Income/Transfer-In decreases debt.
    - Added `creditLimit` field to Account entity.
- **Detailed Transactions**: Complete details in transaction lists and calendar popup.
    - Shows Category, Subcategory, Account Name, Date, and Time.
- **Custom Branding**: Integrated new particular logo assets.
    - Updated app icons for Android and iOS using `logo_icon.png` (transparent background).
    - Themed app with brand colors from the logo.
- **Dashboard**: "Net Total" balance now correctly accounts for liabilities.

### Fixed
- **UI Overflow**: Fixed keyboard covering fields in "Add Account" sheet.
- **Calendar Details**: Fixed missing details in Calendar transaction popup.
- **List View Errors**: Fixed compilation issues in Transaction List View.

### Changed
- Refactored `TransactionCalendarView` for better state handling.
- Updated `README.md` with professional documentation and structure.
