# Gavthan Bar & Restro

Offline-first Flutter app for table management, customer-wise draft orders, final billing, date-wise revenue and basic stock management.

## Core flow

**Table → Customer → Add Items → Draft → Add More Items → Finalize → Payment → Bill → Revenue + Stock Update**

## Current MVP

- Splash screen
- Dashboard
- Table status: FREE / OPEN
- Multiple customers on one table
- Separate draft order per customer
- Add more items to an existing draft
- Categories and serving sizes
- Final billing with Cash / UPI / Card
- Date-wise revenue
- Sales history
- Basic stock tracking
- Low-stock and out-of-stock indicators
- PDF bill generation / print / share through the device print/share sheet
- Local SQLite database
- No login/authentication
- Works offline after dependencies are installed

The data model extends the SRS model with `customers` and `stock_transactions` so the requested customer-wise drafts and stock history can be handled locally.

## Setup

1. Install Flutter (stable channel).
2. Extract this project.
3. Open the project folder in Android Studio or VS Code.
4. Run:

```bash
flutter pub get
flutter run
```

Release APK:

```bash
flutter build apk --release
```

APK output:

`build/app/outputs/flutter-apk/app-release.apk`

## Project structure

```text
lib/
  main.dart
  models/
    models.dart
  services/
    database_service.dart
    pdf_service.dart
  screens/
    splash_screen.dart
    home_screen.dart
    tables_screen.dart
    table_order_screen.dart
    add_order_screen.dart
    final_bill_screen.dart
    bill_success_screen.dart
    history_screen.dart
    reports_screen.dart
    menu_screen.dart
    settings_screen.dart
  widgets/
    common.dart
```

## SQLite

Main local tables:

- `tables`
- `customers`
- `categories`
- `products`
- `orders`
- `order_items`
- `payments`
- `stock_transactions`

Completed bills remain after app restart. Draft orders do not reduce stock. Stock is reduced inside the finalization transaction.

## Seed data

The first run creates:

- 8 tables
- Whisky, Beer, Food, Beverages and Soft Drinks categories
- Example items such as Royal Stag, Blender Pride, Beer and Snacks
- Opening stock values

Edit/delete/stock-update screens can be expanded from the Menu and Settings sections.

## Notes

This project intentionally keeps authentication, cloud sync, supplier management, customer accounts and advanced inventory outside the first version.
