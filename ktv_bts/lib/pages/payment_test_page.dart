import 'package:flutter/material.dart';
import '../models/payment_request.dart';
import '../models/payment_response.dart';
import '../services/stripe_payment_service.dart';

class PaymentTestPage extends StatefulWidget {
  const PaymentTestPage({super.key});

  @override
  State<PaymentTestPage> createState() => _PaymentTestPageState();
}

class _PaymentTestPageState extends State<PaymentTestPage> {
  final StripePaymentService _paymentService = StripePaymentService();
  bool _isLoading = false;
  String _result = '';
  PaymentResponse? _lastResponse;

  // Hardcoded test parameters
  final String _testCustomerName = 'John Doe';
  final bool _testIsAdult = true;
  final String _testTime = 'Morning';

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      await _paymentService.initialize();
      setState(() {
        _result = '✅ Stripe service initialized successfully\n';
      });
    } catch (e) {
      setState(() {
        _result = '❌ Stripe service initialization failed: $e\n';
      });
    }
  }

  Future<void> _testCreatePaymentIntent() async {
    setState(() {
      _isLoading = true;
      _result += '\n🔄 Starting test create payment intent...\n';
    });

    try {
      // Create test payment request
      final request = PaymentRequest(
        customerName: _testCustomerName,
        isAdult: _testIsAdult,
        time: _testTime,
        currency: 'EUR',
        description: 'KTV Test Payment - ${_testTime} Session',
      );

      _result += '📝 Payment request parameters:\n';
      _result += '  Customer Name: ${request.customerName}\n';
      _result += '  Is Adult: ${request.isAdult}\n';
      _result += '  Time Slot: ${request.time}\n';
      _result += '  Amount: ${request.isAdult ? "20.0" : "0.0"} EUR\n';
      _result += '  Currency: ${request.currency}\n\n';

      // Call our service
      final response = await _paymentService.createPaymentIntent(request);

      setState(() {
        _lastResponse = response;
        _result += '📊 Stripe API Response:\n';
        _result += '  Success: ${response.success}\n';
        _result += '  Payment Intent ID: ${response.paymentIntentId ?? 'N/A'}\n';
        _result += '  Client Secret: ${response.clientSecret ?? 'N/A'}\n';
        _result += '  Status: ${response.status ?? 'N/A'}\n';
        _result += '  Amount: ${response.amount ?? 'N/A'} ${response.currency ?? 'N/A'}\n';
        _result += '  Error Message: ${response.errorMessage ?? 'N/A'}\n\n';

        if (response.success) {
          _result += '✅ Payment intent created successfully!\n';
          _result += '💡 Please check Stripe Dashboard to confirm if payment intent was received\n';
          _result += '🔗 Stripe Dashboard: https://dashboard.stripe.com/test/payments\n';
        } else {
          _result += '❌ Payment intent creation failed\n';
        }
      });
    } catch (e) {
      setState(() {
        _result += '❌ Error occurred: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testConfirmPayment() async {
    if (_lastResponse?.paymentIntentId == null) {
      setState(() {
        _result += '\n❌ No available payment intent ID, please create payment intent first\n';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _result += '\n🔄 Starting test confirm payment...\n';
    });

    try {
      // Use test payment method ID (this is Stripe provided test ID)
      const testPaymentMethodId = 'pm_card_visa'; // Stripe test Visa card

      _result += '📝 Confirm payment parameters:\n';
      _result += '  Payment Intent ID: ${_lastResponse!.paymentIntentId}\n';
      _result += '  Payment Method ID: $testPaymentMethodId\n\n';

      final response = await _paymentService.confirmPayment(
        paymentIntentId: _lastResponse!.paymentIntentId!,
        paymentMethodId: testPaymentMethodId,
      );

      setState(() {
        _result += '📊 Payment confirmation response:\n';
        _result += '  Success: ${response.success}\n';
        _result += '  Payment Intent ID: ${response.paymentIntentId ?? 'N/A'}\n';
        _result += '  Status: ${response.status ?? 'N/A'}\n';
        _result += '  Amount: ${response.amount ?? 'N/A'} ${response.currency ?? 'N/A'}\n';
        _result += '  Error Message: ${response.errorMessage ?? 'N/A'}\n\n';

        if (response.success) {
          _result += '✅ Payment confirmation successful!\n';
          _result += '💰 Please check Stripe Dashboard to confirm if money was actually received\n';
          _result += '🔗 Stripe Dashboard: https://dashboard.stripe.com/test/payments\n';
        } else {
          _result += '❌ Payment confirmation failed\n';
        }
      });
    } catch (e) {
      setState(() {
        _result += '❌ Error occurred: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testGetPaymentStatus() async {
    if (_lastResponse?.paymentIntentId == null) {
      setState(() {
        _result += '\n❌ No available payment intent ID, please create payment intent first\n';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _result += '\n🔄 Starting query payment status...\n';
    });

    try {
      final response = await _paymentService.getPaymentStatus(
        _lastResponse!.paymentIntentId!,
      );

      setState(() {
        _result += '📊 Payment status response:\n';
        _result += '  Success: ${response.success}\n';
        _result += '  Payment Intent ID: ${response.paymentIntentId ?? 'N/A'}\n';
        _result += '  Status: ${response.status ?? 'N/A'}\n';
        _result += '  Amount: ${response.amount ?? 'N/A'} ${response.currency ?? 'N/A'}\n';
        _result += '  Error Message: ${response.errorMessage ?? 'N/A'}\n\n';

        if (response.success) {
          _result += '✅ Payment status query successful!\n';
        } else {
          _result += '❌ Payment status query failed\n';
        }
      });
    } catch (e) {
      setState(() {
        _result += '❌ Error occurred: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearResult() {
    setState(() {
      _result = '';
      _lastResponse = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stripe Payment Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Test parameters display
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🧪 Test Parameters (Hardcoded)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Customer Name: $_testCustomerName'),
                    Text('Is Adult: ${_testIsAdult ? 'Yes' : 'No'}'),
                    Text('Time Slot: $_testTime'),
                    Text('Expected Amount: ${_testIsAdult ? '20.0' : '0.0'} EUR'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Test buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testCreatePaymentIntent,
                    icon: const Icon(Icons.payment),
                    label: const Text('Create Payment Intent'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testConfirmPayment,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Confirm Payment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testGetPaymentStatus,
                    icon: const Icon(Icons.info),
                    label: const Text('Query Status'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _clearResult,
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear Results'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Loading indicator
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),

            // Results display
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '📋 Test Results',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 200,
                      child: SingleChildScrollView(
                        child: Text(
                          _result.isEmpty ? 'Click button to start testing...' : _result,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Stripe Dashboard links
            const SizedBox(height: 16),
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🔗 Stripe Dashboard Links',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Test Environment: https://dashboard.stripe.com/test/payments'),
                    const Text('Production Environment: https://dashboard.stripe.com/payments'),
                    const SizedBox(height: 8),
                    const Text(
                      '💡 Tip: After creating payment intent, please check Stripe Dashboard to confirm if payment intent was actually received',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
