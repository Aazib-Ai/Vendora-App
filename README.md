# Vendora - Multi-Vendor E-Commerce App

A comprehensive Flutter mobile application for a multi-vendor e-commerce platform with separate views for Buyers, Sellers, and Admins.

## Project Structure

```
lib/
├── core/
│   ├── routes/
│   │   └── app_routes.dart          # Route definitions and navigation
│   ├── theme/
│   │   └── app_theme.dart           # Material 3 theme configuration
│   └── widgets/
│       ├── bottom_navigation_bar.dart
│       ├── custom_button.dart
│       ├── custom_text_field.dart
│       └── vendora_logo.dart
├── features/
│   ├── common/
│   │   └── presentation/
│   │       └── screens/
│   │           ├── splash_screen.dart
│   │           ├── onboarding_screen.dart
│   │           ├── role_selection_screen.dart
│   │           ├── login_screen.dart
│   │           ├── signup_screen.dart
│   │           ├── forgot_password_screen.dart
│   │           └── reset_password_screen.dart
│   ├── buyer/
│   │   └── presentation/
│   │       └── screens/
│   │           ├── home_screen.dart
│   │           ├── product_details_screen.dart
│   │           ├── cart_screen.dart
│   │           ├── checkout_screen.dart
│   │           ├── order_complete_screen.dart
│   │           ├── profile_screen.dart
│   │           ├── settings_screen.dart
│   │           ├── help_center_screen.dart
│   │           └── contact_us_screen.dart
│   ├── seller/
│   │   └── presentation/
│   │       └── screens/
│   │           └── dashboard_screen.dart
│   └── admin/
│       └── presentation/
│           └── screens/
│               ├── admin_dashboard_screen.dart
│               ├── manage_sellers_screen.dart
│               ├── manage_products_screen.dart
│               ├── manage_users_screen.dart
│               └── manage_admins_screen.dart
└── main.dart
```
How to run 

flutter run -d emulator-5554

flutter build apk --release
## Features

### Common Pages
- ✅ Splash Screen
- ✅ Onboarding (2 screens)
- ✅ Role Selection (Buyer/Seller/Admin)
- ✅ Login
- ✅ Sign Up
- ✅ Forgot Password
- ✅ Reset Password

### Buyer/User View
- ✅ Home Screen with product listings
- ✅ Product Details
- ✅ Shopping Cart
- ✅ Checkout
- ✅ Order Complete
- ✅ Profile
- ✅ Settings
- ✅ Help Center
- ✅ Contact Us

### Seller View
- ✅ Dashboard with stats
- ✅ Product management
- ✅ Order management

### Admin View
- ✅ Admin Dashboard
- ✅ Manage Sellers
- ✅ Manage Products
- ✅ Manage Users
- ✅ Manage Admins

## Getting Started

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd vendora
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Dependencies

- `google_fonts`: For custom typography
- `flutter_svg`: For SVG support
- `cached_network_image`: For image caching
- `flutter_rating_bar`: For rating displays

## Design System

The app uses Material 3 design principles with:
- Custom color palette (black, white, grey tones)
- Rounded corners (12-16px radius)
- Consistent spacing and padding
- Modern typography using Inter font family

## Navigation

Navigation is handled through `AppRoutes` class with named routes. All routes are defined in `lib/core/routes/app_routes.dart`.

## Theme

The app theme is configured in `lib/core/theme/app_theme.dart` with Material 3 support. Both light and dark themes are available.

## Contributing

1. Create a feature branch
2. Make your changes
3. Submit a pull request

## License

This project is private and proprietary.

