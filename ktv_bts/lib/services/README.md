# Stripe Payment Service for KTV Booking

This service provides a complete interface for handling Stripe payments for KTV (Karaoke) bookings.

## Features

- ✅ Create payment intents for KTV bookings
- ✅ Confirm payments with payment methods
- ✅ Cancel payments
- ✅ Check payment status
- ✅ Automatic pricing calculation based on customer type and time
- ✅ Support for both adult and child pricing
- ✅ Morning and evening session pricing

## Environment Configuration

The service uses environment variables for API keys. Create a `.env` file in the project root:

```env
# Stripe API Keys - Replace with your actual keys
STRIPE_PUBLIC_KEY=your_stripe_public_key_here
STRIPE_SECRET_KEY=your_stripe_secret_key_here

# Environment
ENVIRONMENT=development
```

**Security Note**: The `.env` file is automatically excluded from version control via `.gitignore`.

## Pricing Structure

| Customer Type | Time Slot | Price (EUR) |
|---------------|-----------|-------------|
| Adult         | Morning   | 20          |
| Adult         | Afternoon | 20          |
| Child         | Morning   | 0           |
| Child         | Afternoon | 0           |

## Usage

### 1. Initialize the Service

```dart
final paymentService = StripePaymentService();
await paymentService.initialize();
```

### 2. Create Payment Request

```dart
final paymentRequest = PaymentRequest(
  customerName: '張三',
  isAdult: true,
  time: 'Morning', // "Morning" or "Afternoon"
  currency: 'EUR', // Fixed to EUR
  description: 'KTV Morning Session for Adult',
);
```

### 3. Create Payment Intent

```dart
final response = await paymentService.createPaymentIntent(paymentRequest);

if (response.success) {
  print('Payment Intent ID: ${response.paymentIntentId}');
  print('Client Secret: ${response.clientSecret}');
  print('Amount: ${response.amount} ${response.currency}');
} else {
  print('Error: ${response.errorMessage}');
}
```

### 4. Confirm Payment

```dart
final confirmResponse = await paymentService.confirmPayment(
  paymentIntentId: paymentIntentId,
  paymentMethodId: paymentMethodId,
);
```

### 5. Check Payment Status

```dart
final statusResponse = await paymentService.getPaymentStatus(paymentIntentId);
```

### 6. Cancel Payment

```dart
final cancelResponse = await paymentService.cancelPayment(paymentIntentId);
```

## Models

### PaymentRequest

- `customerName`: String - Name of the customer
- `isAdult`: bool - Whether the customer is an adult
- `time`: String - Time slot ("Morning" or "Afternoon")
- `amount`: double - Payment amount (will be calculated automatically)
- `currency`: String - Currency code (fixed: 'EUR')
- `description`: String? - Optional description

### PaymentResponse

- `success`: bool - Whether the operation was successful
- `paymentIntentId`: String? - Stripe payment intent ID
- `clientSecret`: String? - Client secret for frontend integration
- `errorMessage`: String? - Error message if operation failed
- `status`: String? - Payment status
- `amount`: double? - Payment amount
- `currency`: String? - Currency code

## Error Handling

The service includes comprehensive error handling for:

- Network connectivity issues
- Stripe API errors
- Invalid payment requests
- Payment confirmation failures

## Security Notes

- API keys are stored in environment variables for security
- The `.env` file is excluded from version control
- Never commit actual API keys to the repository
- Use `.env.example` as a template for other developers
- In production, use secure key management services

## Example Implementation

See `lib/examples/payment_example.dart` for complete usage examples including:

- Adult morning booking
- Child evening booking
- Complete payment flow
- Payment status checking
- Payment cancellation
