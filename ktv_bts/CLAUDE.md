# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter-based ticket selling application (KTV-BTS) specifically designed for selling tickets to 新天鵝堡 (Neuschwanstein Castle). The app serves as a complete ticket purchasing and verification system.

## Core Business Logic

The application follows this ticket purchase flow:

1. **Landing Page**: Users input their information:
   - User identification
   - Age verification (adult/minor)
   - Destination selection (上無常/下無常 - upper/lower sections)

2. **Payment Processing**:
   - Credit card transactions handled via Stripe API integration

3. **Ticket Generation & Verification**:
   - System sends purchase details to backend
   - Backend emails the shop owner for verification
   - Owner validates and sends back approved tickets
   - App displays the returned tickets to users

## Common Development Commands

```bash
# Run the application
flutter run

# Run on specific platform
flutter run -d chrome  # Web
flutter run -d macos   # macOS
flutter run -d ios     # iOS simulator

# Build for production
flutter build apk      # Android
flutter build ios      # iOS
flutter build web      # Web

# Run tests
flutter test
flutter test test/widget_test.dart  # Run specific test

# Analyze code
flutter analyze

# Format code
dart format .

# Get dependencies
flutter pub get

# Upgrade dependencies
flutter pub upgrade
```

## Project Structure

The project currently uses a simple Flutter structure with:
- `lib/main.dart` - Entry point with basic counter app (to be replaced)
- Platform-specific folders (android/, ios/, web/, etc.) for native code
- `test/` for widget and unit tests

## Key Implementation Considerations

### Stripe API Integration
When implementing the payment system, the Stripe API will need:
- Proper API key management (use environment variables)
- Secure HTTPS communication
- Error handling for payment failures
- Transaction logging

### Email-based Ticket Verification System
The ticket verification flow requires:
- Backend API to handle email sending to owner
- Polling mechanism to check for ticket responses
- State management for pending/approved tickets
- Proper error handling for timeout scenarios

### Scheduled Polling
For checking ticket approval status:
- Consider using Timer.periodic() or background_fetch package
- Implement exponential backoff for polling intervals
- Handle app lifecycle (background/foreground) appropriately
- Store pending ticket status locally for resilience

## State Management Approach

Given the app's requirements for:
- User form data persistence
- Payment transaction state
- Ticket approval status tracking
- Polling mechanism state

Consider implementing a structured state management solution (Provider, Riverpod, or Bloc) rather than relying solely on StatefulWidgets.

## Security Considerations for Implementation

- Stripe API credentials must never be hardcoded
- Use secure storage for sensitive user data
- Implement proper SSL pinning for API calls
- Validate all user inputs before processing
- Implement rate limiting for polling requests