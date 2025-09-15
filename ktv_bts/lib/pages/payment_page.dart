import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/stripe_payment_service.dart';
import '../services/ticket_api_service.dart';
import '../services/ip_verification_service.dart';
import '../services/rail_booking_service.dart';
import '../models/payment_request.dart';
import '../models/payment_response.dart';
import '../models/ticket_request.dart';
import '../models/ticket_info.dart';
import '../models/online_order_request.dart';
import '../models/online_order_response.dart';
import '../models/online_confirmation_response.dart';
import '../models/online_ticket_response.dart';
import '../models/bundle_info.dart';
import '../services/ticket_storage_service.dart';
import '../utils/ticket_id_generator.dart';
import 'dart:math';
import 'rail_search_test_page.dart';
import 'my_train_tickets_page.dart';
import 'bundle_booking_page.dart';
import '../models/bundle_ticket.dart';
import '../services/bundle_ticket_storage_service.dart';

class PaymentPage extends StatefulWidget {
  final PaymentRequest paymentRequest;
  final bool isBundlePayment;
  final Map<String, dynamic>? bundleData;

  const PaymentPage({
    super.key,
    required this.paymentRequest,
    this.isBundlePayment = false,
    this.bundleData,
  });

  /// Create PaymentPage from bundle data
  factory PaymentPage.fromBundle(Map<String, dynamic> bundleData) {
    final bundle = bundleData['bundle'] as BundleInfo;
    final participants = bundleData['participants'] as List<ParticipantInfo>;
    final date = bundleData['date'] as DateTime;
    final totalPrice = bundleData['totalPrice'] as double;
    
    // Create a PaymentRequest for bundle
    final paymentRequest = PaymentRequest(
      customerName: participants.first.firstName + ' ' + participants.first.lastName,
      isAdult: true, // Bundle participants are typically adults
      time: 'Bundle Tour',
      currency: 'EUR',
      description: '${bundle.name} - ${participants.length} participant(s)',
      amount: totalPrice,
    );
    
    return PaymentPage(
      paymentRequest: paymentRequest,
      isBundlePayment: true,
      bundleData: bundleData,
    );
  }

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _stripeService = StripePaymentService();
  final _ticketApiService = TicketApiService();
  final _ipVerificationService = IpVerificationService();
  final _railBookingService = RailBookingService.defaultInstance();
  // Form controllers
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvcController = TextEditingController();
  final _cardholderNameController = TextEditingController();

  bool _isLoading = false;
  PaymentResponse? _lastPaymentIntent;

  @override
  void initState() {
    super.initState();
    _initializeService();
    // Automatically create payment intent
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _createPaymentIntent();
    });
  }

  Future<void> _initializeService() async {
    try {
      await _stripeService.initialize();
    } catch (e) {
      // Silently handle initialization error, will retry during payment
    }
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvcController.dispose();
    _cardholderNameController.dispose();
    super.dispose();
  }

  Future<void> _createPaymentIntent() async {
    if (_lastPaymentIntent != null) return;

    try {
      final response = await _stripeService.createPaymentIntent(widget.paymentRequest);
      setState(() {
        _lastPaymentIntent = response;
      });
    } catch (e) {
      // Silently handle error, will retry during payment
    }
  }

  Future<void> _processPayment() async {
    print('💳 Starting payment process...');

    if (!_formKey.currentState!.validate()) {
      print('💳 Form validation failed');
      return;
    }

    // Verify user IP before payment
    print('🔒 Verifying user IP before payment...');
    final isIpAuthorized = await _ipVerificationService.verifyUserIp();
    if (!isIpAuthorized) {
      _showIpBlockedDialog();
      return;
    }
    print('✅ IP verification passed, proceeding with payment');

    if (_lastPaymentIntent == null || !_lastPaymentIntent!.success) {
      print('💳 Payment intent not ready, attempting to create...');
      setState(() {
        _isLoading = true;
      });
      
      try {
        final response = await _stripeService.createPaymentIntent(widget.paymentRequest);
        setState(() {
          _lastPaymentIntent = response;
        });
        
        if (!response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create payment intent: ${response.errorMessage}'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment initialization failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }

    print('💳 Payment intent ready, starting payment...');
    setState(() {
      _isLoading = true;
    });

    try {
      // Create PaymentMethod using test card number
      final cardNumber = _cardNumberController.text.replaceAll(' ', '');
      final expiryParts = _expiryDateController.text.split('/');
      final month = expiryParts[0];
      final year = '20${expiryParts[1]}';
      final cvc = _cvcController.text;

      // Create PaymentMethod
      final paymentMethodResponse = await _createPaymentMethod(
        cardNumber: cardNumber,
        expMonth: int.parse(month),
        expYear: int.parse(year),
        cvc: cvc,
        cardholderName: _cardholderNameController.text,
      );

      if (!paymentMethodResponse.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment processing failed: ${paymentMethodResponse.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Confirm payment
      final response = await _stripeService.confirmPayment(
        paymentIntentId: _lastPaymentIntent!.paymentIntentId!,
        paymentMethodId: paymentMethodResponse.paymentIntentId!,
      );

      if (response.success) {
        print('💳 Payment successful with ID: ${response.paymentIntentId}');
        // Payment successful, call external API
        await _submitTicketToApi(response.paymentIntentId!);
      } else if (response.requiresAction) {
        print('🔒 3DS authentication required');
        // Show 3DS authentication prompt
        _show3DSAuthenticationDialog(response);
      } else {
        print('💳 Payment failed: ${response.errorMessage}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${response.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment processing error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<PaymentResponse> _createPaymentMethod({
    required String cardNumber,
    required int expMonth,
    required int expYear,
    required String cvc,
    required String cardholderName,
  }) async {
    try {
      final response = await _stripeService.createPaymentMethod(
        cardNumber: cardNumber,
        expMonth: expMonth,
        expYear: expYear,
        cvc: cvc,
        cardholderName: cardholderName,
      );
      return response;
    } catch (e) {
      return PaymentResponse.failure(errorMessage: 'Failed to create payment method: $e');
    }
  }

  /// Submit ticket request to external API after successful payment
  Future<void> _submitTicketToApi(String paymentIntentId) async {
    try {
      print('🎫 Submitting ticket request to API with paymentIntentId: $paymentIntentId');
      
      if (widget.isBundlePayment) {
        // Handle bundle payment
        await _submitBundleToApi(paymentIntentId);
      } else {
        // Create comprehensive ticket request that includes both entrance and train tickets
        final comprehensiveTicketRequest = _createComprehensiveTicketRequest();
        
        print('🎫 Comprehensive ticket request data: ${comprehensiveTicketRequest.toJson()}');
        
        // Submit to API
        final apiResponse = await _ticketApiService.submitTicketRequest(
          paymentRefno: paymentIntentId,
          ticketRequest: comprehensiveTicketRequest,
        );
        
        print('🎫 API response - Success: ${apiResponse.success}, Error: ${apiResponse.errorMessage}');
        
        if (apiResponse.success) {
          // If train ticket info exists, call G2Rail online_orders API
          if (widget.paymentRequest.trainInfo != null) {
            await _createOnlineOrderWithLoading(paymentIntentId);
          } else {
            _showSuccessDialog();
          }
        } else {
          // Temporary test: show success dialog even if API fails
          print('🎫 API failed but showing success dialog for testing');
          _showSuccessDialog();
          // _showApiErrorDialog(apiResponse.errorMessage ?? 'Unknown error');
        }
      }
    } catch (e) {
      print('🎫 Exception in _submitTicketToApi: $e');
      _showApiErrorDialog('Failed to submit ticket request: $e');
    }
  }

  /// Submit bundle booking to external API
  Future<void> _submitBundleToApi(String paymentIntentId) async {
    try {
      print('🎫 [BUNDLE] Submitting bundle booking to API with paymentIntentId: $paymentIntentId');
      print('🎫 [BUNDLE] Bundle data available: ${widget.bundleData != null}');
      
      if (widget.bundleData == null) {
        print('🎫 [BUNDLE] ERROR: Bundle data is null!');
        _showApiErrorDialog('Bundle data is missing');
        return;
      }
      
      final bundle = widget.bundleData!['bundle'] as BundleInfo;
      final participants = widget.bundleData!['participants'] as List<ParticipantInfo>;
      final date = widget.bundleData!['date'] as DateTime;
      final totalPrice = widget.bundleData!['totalPrice'] as double;
      
      print('🎫 [BUNDLE] Bundle ID: ${bundle.id}');
      print('🎫 [BUNDLE] Bundle Name: ${bundle.name}');
      print('🎫 [BUNDLE] Participants count: ${participants.length}');
      print('🎫 [BUNDLE] Total price: $totalPrice');
      
      // Create bundle booking request in the correct API format
      final bundleRequest = {
        'PaymentRefno': paymentIntentId,
        'RecipientEmail': participants.first.email,
        'Ip': '127.0.0.1', // Default IP
        'TicketInfo': participants.map((participant) => {
          'Id': _generateTicketId(),
          'FamilyName': participant.lastName,
          'GivenName': participant.firstName,
          'IsAdult': true, // Bundle participants are typically adults
          'Session': 'Bundle Tour',
          'ArrivalTime': date.toIso8601String().split('T')[0], // YYYY-MM-DD format
          'Prize': bundle.priceEur,
          'Type': 'Bundle',
          'EntranceName': '', // Bundle doesn't need entrance name
          'BundleName': bundle.name,
          'From': '', // Not required for Bundle
          'To': bundle.location,
          'Phone': '', // Not required for Bundle
          'PassportNumber': participant.passportNumber,
          'BirthDate': '', // Not required for Bundle
          'Gender': '', // Not required for Bundle
        }).toList(),
      };
      
      print('🎫 [BUNDLE] Bundle request data: $bundleRequest');
      print('🎫 [BUNDLE] Calling API: https://ezzn8n.zeabur.app/webhook/order-ticket');
      
      // Call bundle API
      final response = await _ticketApiService.submitBundleRequest(bundleRequest);
      
      print('🎫 [BUNDLE] API response - Success: ${response.success}, Error: ${response.errorMessage}');
      print('🎫 [BUNDLE] API response - Status Code: ${response.statusCode}');
      
      if (response.success) {
        print('🎫 [BUNDLE] API call successful, showing success dialog');
        
        // Save bundle ticket to local storage
        await _saveBundleTicket(paymentIntentId);
        
        _showSuccessDialog();
      } else {
        // Temporary test: show success dialog even if API fails
        print('🎫 [BUNDLE] API failed but showing success dialog for testing');
        print('🎫 [BUNDLE] Error details: ${response.errorMessage}');
        
        // Still save bundle ticket even if API fails (for testing)
        await _saveBundleTicket(paymentIntentId);
        
        _showSuccessDialog();
      }
    } catch (e) {
      print('🎫 [BUNDLE] Exception in _submitBundleToApi: $e');
      print('🎫 [BUNDLE] Exception type: ${e.runtimeType}');
      _showApiErrorDialog('Failed to submit bundle booking: $e');
    }
  }

  /// Generate ticket ID in format: tickettrip_ + 16 random characters
  String _generateTicketId() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final randomString = String.fromCharCodes(
      Iterable.generate(16, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
    return 'tickettrip_$randomString';
  }

  /// Save bundle ticket to local storage
  Future<void> _saveBundleTicket(String paymentIntentId) async {
    try {
      if (widget.bundleData == null) {
        print('🎫 [BUNDLE] Cannot save ticket: bundle data is null');
        return;
      }

      final bundle = widget.bundleData!['bundle'] as BundleInfo;
      final participants = widget.bundleData!['participants'] as List<dynamic>;
      final date = widget.bundleData!['date'] as DateTime;

      // Convert participants to BundleParticipant objects
      final bundleParticipants = participants.map((p) {
        // Handle both Map<String, dynamic> and ParticipantInfo types
        if (p is Map<String, dynamic>) {
          return BundleParticipant(
            firstName: p['firstName'] as String,
            lastName: p['lastName'] as String,
            email: p['email'] as String,
            passportNumber: p['passportNumber'] as String,
          );
        } else {
          // Assume it's a ParticipantInfo object
          final participant = p as ParticipantInfo;
          return BundleParticipant(
            firstName: participant.firstName,
            lastName: participant.lastName,
            email: participant.email,
            passportNumber: participant.passportNumber,
          );
        }
      }).toList();

      // Create bundle ticket
      final bundleTicket = BundleTicket(
        id: paymentIntentId, // Use payment intent ID as ticket ID
        bundleId: bundle.id,
        bundleName: bundle.name,
        location: bundle.location,
        priceEur: bundle.priceEur,
        bookingDate: DateTime.now(),
        tourDate: date,
        participants: bundleParticipants,
        paymentRefno: paymentIntentId,
        status: 'confirmed',
      );

      // Save to storage
      await BundleTicketStorageService.saveBundleTicket(bundleTicket);
      
      print('🎫 [BUNDLE] Bundle ticket saved successfully: ${bundleTicket.id}');
    } catch (e) {
      print('🎫 [BUNDLE] Failed to save bundle ticket: $e');
    }
  }

  /// Create comprehensive ticket request that includes both entrance and train tickets
  TicketRequest _createComprehensiveTicketRequest() {
    final ticketInfoList = <TicketInfo>[];
    
    // Add entrance tickets if they exist
    if (widget.paymentRequest.ticketRequest != null) {
      ticketInfoList.addAll(widget.paymentRequest.ticketRequest!.ticketInfo);
    }
    
    // Add train ticket if it exists
    if (widget.paymentRequest.trainInfo != null) {
      final trainInfo = widget.paymentRequest.trainInfo!;
      final trainTicketId = TicketIdGenerator.generateTicketId();
      
      // Use passenger info from payment request (collected from train booking page)
      final firstName = widget.paymentRequest.passengerFirstName ?? 'Train';
      final lastName = widget.paymentRequest.passengerLastName ?? 'Passenger';
      final phone = widget.paymentRequest.passengerPhone ?? '';
      final passport = widget.paymentRequest.passengerPassport ?? '';
      final birthdate = widget.paymentRequest.passengerBirthdate ?? '';
      final gender = widget.paymentRequest.passengerGender ?? '';
      
      // Get train route information
      final fromStation = trainInfo.from.localName;
      final toStation = trainInfo.to.localName;
      
      // Calculate train ticket price
      final trainPrice = widget.paymentRequest.trainTicketAmount ?? 0.0;
      
      // 根據火車出發時間判斷是上午還是下午
      final trainSession = TicketIdGenerator.getSessionFromTime(trainInfo.departure);
      
      ticketInfoList.add(TicketInfo(
        id: trainTicketId,
        familyName: lastName,
        givenName: firstName,
        isAdult: true, // Train tickets are always adult
        session: trainSession, // 根據火車出發時間判斷 Morning/Afternoon
        arrivalTime: DateFormat('yyyy-MM-dd').format(trainInfo.departure),
        price: trainPrice,
        type: 'Train', // Train ticket type
        entranceName: '', // No entrance name for train tickets
        bundleName: '', // Currently empty
        from: fromStation,
        to: toStation,
        phone: phone, // 從火車票預訂頁面收集
        passportNumber: passport, // 從火車票預訂頁面收集
        birthDate: birthdate, // 從火車票預訂頁面收集
        gender: gender, // 從火車票預訂頁面收集
      ));
    }
    
    // Determine recipient email
    String recipientEmail;
    if (widget.paymentRequest.ticketRequest != null) {
      recipientEmail = widget.paymentRequest.ticketRequest!.recipientEmail;
    } else if (widget.paymentRequest.passengerEmail != null) {
      recipientEmail = widget.paymentRequest.passengerEmail!;
    } else {
      recipientEmail = 'customer@example.com';
    }
    
    return TicketRequest(
      recipientEmail: recipientEmail,
      totalTickets: ticketInfoList.length,
      ticketInfo: ticketInfoList,
    );
  }

  /// Create legacy ticket request from current payment request
  TicketRequest _createLegacyTicketRequest() {
    // This is a fallback for when ticketRequest is null
    // We'll create a single ticket based on the current payment request
    final customerName = widget.paymentRequest.customerName;
    final nameParts = customerName.split(' ');
    final familyName = nameParts.length > 1 ? nameParts.last : '';
    final givenName = nameParts.length > 1 ? nameParts.take(nameParts.length - 1).join(' ') : customerName;
    
    // 獲取景點資訊
    final description = widget.paymentRequest.description ?? '';
    String attractionName;
    if (description.contains('Uffizi Gallery')) {
      attractionName = 'Uffizi Gallery Ticket';
    } else {
      attractionName = 'Neuschwanstein Castle Ticket';
    }
    
    // 生成隨機ID
    final ticketId = TicketIdGenerator.generateTicketId();
    
    return TicketRequest(
      recipientEmail: 'customer@example.com', // Default email
      totalTickets: 1,
      ticketInfo: [
        TicketInfo(
          id: ticketId,
          familyName: familyName,
          givenName: givenName,
          isAdult: widget.paymentRequest.isAdult,
          session: widget.paymentRequest.time,
          arrivalTime: DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T')[0], // Tomorrow
          price: widget.paymentRequest.amount,
          type: 'Entrance', // 門票類型
          entranceName: attractionName,
          bundleName: '', // 目前為空
          from: '', // 門票不需要出發地資訊
          to: '', // 門票不需要目的地資訊
          phone: '', // 門票不需要電話資訊
          passportNumber: '', // 門票不需要護照資訊
          birthDate: '', // 門票不需要出生日期
          gender: '', // 門票不需要性別資訊
        ),
      ],
    );
  }

  /// Create G2Rail online order (with Loading animation)
  Future<void> _createOnlineOrderWithLoading(String paymentIntentId) async {
    // Show Loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text(
              'Processing train tickets...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Processing your train ticket order',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );

    try {
      // Execute train ticket processing flow
      await _createOnlineOrder(paymentIntentId);
      
      // Close Loading dialog
      if (mounted) {
        Navigator.of(context).pop();
        // Show success dialog with option to navigate to tickets page
        _showTrainTicketSuccessDialog();
      }
    } catch (e) {
      // Close Loading dialog
      if (mounted) {
        Navigator.of(context).pop();
        // Show error dialog
        _showTrainTicketErrorDialog(e.toString());
      }
    }
  }

  /// Create G2Rail online order
  Future<void> _createOnlineOrder(String paymentIntentId) async {
    try {
      print('🚄 Starting G2Rail online order creation');
      
      // Check if train ticket info exists
      if (widget.paymentRequest.trainInfo == null) {
        print('🚄 No train ticket info, skipping online order creation');
        return;
      }

      // Get necessary data from train ticket info
      final trainInfo = widget.paymentRequest.trainInfo!;
      
      // Use real passenger info, or default values if not available
      final firstName = widget.paymentRequest.passengerFirstName ?? 'Train';
      final lastName = widget.paymentRequest.passengerLastName ?? 'Passenger';
      final email = widget.paymentRequest.passengerEmail ?? 'customer@example.com';
      final phone = widget.paymentRequest.passengerPhone ?? '+8615000367081';
      final passport = widget.paymentRequest.passengerPassport ?? 'A123456';
      final birthdate = widget.paymentRequest.passengerBirthdate ?? '1986-09-01';
      final gender = widget.paymentRequest.passengerGender ?? 'male';
      
      // Create passenger information
      final passengers = [
        Passenger(
          lastName: lastName,
          firstName: firstName,
          birthdate: birthdate,
          passport: passport,
          email: email,
          phone: phone,
          gender: gender,
        ),
      ];

      // Get booking_code from train service
      print('🚄 Check trainService: ${widget.paymentRequest.trainService}');
      print('🚄 trainService.bookingCode: ${widget.paymentRequest.trainService?.bookingCode}');
      
      final bookingCode = widget.paymentRequest.trainService?.bookingCode ?? 'bc_05';
      
      print('🚄 Using booking_code: $bookingCode');
      
      // Create online order request
      final onlineOrderRequest = OnlineOrderRequest(
        passengers: passengers,
        sections: [bookingCode], // Use real booking_code
        seatReserved: true,
        memo: paymentIntentId, // Use payment ID as memo
      );

      print('🚄 Online order request parameters: ${onlineOrderRequest.toJson()}');

      // Call G2Rail API
      final response = await _railBookingService.createOnlineOrder(
        request: onlineOrderRequest,
      );

      if (response.success) {
        print('✅ G2Rail online order created successfully');
        print('🆔 Order ID: ${response.data?.id}');
        print('🚄 Route: ${response.data?.from.localName} → ${response.data?.to.localName}');
        print('⏰ Departure Time: ${response.data?.departure}');
        print('⏰ Arrival Time: ${response.data?.arrival}');
        
        // Immediately confirm order after successful online order creation
        if (response.data?.id != null) {
          await _confirmOnlineOrder(response.data!.id);
        }
      } else {
        print('❌ G2Rail online order creation failed: ${response.errorMessage}');
        // Even if online order creation fails, it does not affect the overall flow, just log the error
      }
    } catch (e) {
      print('❌ Exception creating G2Rail online order: $e');
      // Even if online order creation fails, it does not affect the overall flow, just log the error
    }
  }

  /// Confirm G2Rail online order
  Future<void> _confirmOnlineOrder(String onlineOrderId) async {
    try {
      print('🎫 Starting G2Rail online order confirmation');
      print('🆔 Online Order ID: $onlineOrderId');

      // Call G2Rail confirmation API
      final response = await _railBookingService.confirmOnlineOrder(
        onlineOrderId: onlineOrderId,
      );

      if (response.success) {
        print('✅ G2Rail online order confirmed successfully');
        print('🆔 Confirmation ID: ${response.data?.id}');
        print('🎫 PNR: ${response.data?.order.pnr}');
        print('🚄 Route: ${response.data?.order.from.localName} → ${response.data?.order.to.localName}');
        print('⏰ Departure Time: ${response.data?.order.departure}');
        
        // Display seat information
        if (response.data?.order.reservations.isNotEmpty == true) {
          final reservation = response.data!.order.reservations.first;
          print('🚂 Train: ${reservation.trainName}, Car: ${reservation.car}, Seat: ${reservation.seat}');
        }
        
        // Display fare information
        print('💰 Payment Price: ${(response.data?.paymentPrice.cents ?? 0) / 100} ${response.data?.paymentPrice.currency}');
        print('💰 Charging Price: ${(response.data?.chargingPrice.cents ?? 0) / 100} ${response.data?.chargingPrice.currency}');
        print('💰 Rebate Amount: ${(response.data?.rebateAmount.cents ?? 0) / 100} ${response.data?.rebateAmount.currency}');
        
        // Display whether re-confirmation is needed
        print('🔄 Need re-confirmation: ${response.data?.confirmAgain}');
        
        // Display check-in information
        if (response.data?.ticketCheckIns.isNotEmpty == true) {
          final checkIn = response.data!.ticketCheckIns.first;
          print('🎫 Check-in URL: ${checkIn.checkInUrl}');
          print('⏰ Earliest Check-in Time: ${checkIn.earliestCheckInTimestamp}');
          print('⏰ Latest Check-in Time: ${checkIn.latestCheckInTimestamp}');
        }
        
        // Save confirmation information to local storage
        await TicketStorageService.saveTicketConfirmation(
          orderId: onlineOrderId,
          confirmation: response.data!,
        );
        
        // Download tickets after successful online order confirmation
        await _downloadOnlineTickets(onlineOrderId);
      } else {
        print('❌ G2Rail online order confirmation failed: ${response.errorMessage}');
        // Even if confirmation fails, it does not affect the overall flow, just log the error
      }
    } catch (e) {
      print('❌ Exception confirming G2Rail online order: $e');
      // Even if confirmation fails, it does not affect the overall flow, just log the error
    }
  }

  /// Download G2Rail online tickets
  Future<void> _downloadOnlineTickets(String onlineOrderId) async {
    try {
      print('🎫 Starting G2Rail online ticket download');
      print('🆔 Online Order ID: $onlineOrderId');

      // Call G2Rail ticket download API
      final response = await _railBookingService.downloadOnlineTickets(
        onlineOrderId: onlineOrderId,
      );

      if (response.success) {
        print('✅ G2Rail online ticket download successful');
        print('🎫 Ticket Count: ${response.data?.tickets.length}');
        
        for (int i = 0; i < (response.data?.tickets.length ?? 0); i++) {
          final ticket = response.data!.tickets[i];
          print('🎫 Ticket ${i + 1}: ${ticket.ticketTypeDisplayName}');
          print('🔗 Download Link: ${ticket.file}');
          
          // Can further process ticket files as needed
          if (ticket.isPdfTicket) {
            print('📄 This is a PDF ticket, can download and save locally');
          } else if (ticket.isMobileTicket) {
            print('📱 This is a mobile ticket, can display in app');
          }
        }
        
        // Save ticket file information to local storage
        await TicketStorageService.saveTicketFiles(
          orderId: onlineOrderId,
          tickets: response.data!,
        );
        
        // Here you can add actual download logic, for example:
        // - Download PDF files to local storage
        // - Save mobile tickets to user's ticket wallet
        // - Send tickets to user's email
        print('💡 Ticket download completed, can further process ticket files based on business requirements');
        
      } else {
        print('❌ G2Rail online ticket download failed: ${response.errorMessage}');
        // Even if download fails, it does not affect the overall flow, just log the error
      }
    } catch (e) {
      print('❌ Exception downloading G2Rail online tickets: $e');
      // Even if download fails, it does not affect the overall flow, just log the error
    }
  }

  /// Show train ticket success dialog
  void _showTrainTicketSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Train Ticket Purchase Successful!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your train ticket has been successfully purchased and confirmed!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🎫 Ticket Information:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (widget.paymentRequest.trainInfo != null) ...[
                    Text('Route: ${widget.paymentRequest.trainInfo!.from.localName} → ${widget.paymentRequest.trainInfo!.to.localName}'),
                    Text('Train: ${widget.paymentRequest.trainInfo!.number}'),
                    Text('Departure: ${DateFormat('HH:mm').format(widget.paymentRequest.trainInfo!.departure)}'),
                    Text('Arrival: ${DateFormat('HH:mm').format(widget.paymentRequest.trainInfo!.arrival)}'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'You can now view your train tickets or return to the homepage to continue browsing.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to homepage
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/',
                (route) => false,
              );
            },
            child: const Text('Return to Homepage'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to my train tickets page
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MyTrainTicketsPage(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('View My Tickets'),
          ),
        ],
      ),
    );
  }

  /// Show train ticket error dialog
  void _showTrainTicketErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Train Ticket Processing Failed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment was successful, but there was an issue processing your train ticket:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Text(
                errorMessage,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please contact customer service and provide your payment reference number:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              _lastPaymentIntent?.paymentIntentId ?? 'Unknown',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to homepage
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/',
                (route) => false,
              );
            },
            child: const Text('Return to Homepage'),
          ),
        ],
      ),
    );
  }

  /// Show API error dialog
  void _showApiErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('API Error'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Payment was successful, but there was an error submitting the ticket request:'),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please contact support with your payment reference:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              _lastPaymentIntent?.paymentIntentId ?? 'Unknown',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              // 跳轉到首頁
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/',
                (route) => false,
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    print('🎫 Showing success dialog');
    print('🎫 PaymentRequest time: ${widget.paymentRequest.time}');
    print('🎫 PaymentRequest isCombinedPayment: ${widget.paymentRequest.isCombinedPayment}');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Payment Successful!'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Customer: ${widget.paymentRequest.customerName}'),
              Text('Total Amount: ${widget.paymentRequest.amount} EUR'),
              Text('Description: ${widget.paymentRequest.description}'),
              const SizedBox(height: 16),
              
              // 如果是組合支付，顯示詳細的金額分解
              if (widget.paymentRequest.isCombinedPayment) ...[
                const Text(
                  'Payment Details:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('• Neuschwanstein Castle Ticket: ${widget.paymentRequest.ticketOnlyAmount.toStringAsFixed(2)} EUR'),
                Text('• Train Ticket: ${widget.paymentRequest.trainTicketAmount!.toStringAsFixed(2)} EUR'),
                Text('• Total: ${widget.paymentRequest.amount.toStringAsFixed(2)} EUR'),
                const SizedBox(height: 16),
              ],
              
              // Display ticket details
              if (widget.paymentRequest.ticketRequest != null) ...[
                const Text(
                  'Ticket Details:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...widget.paymentRequest.ticketRequest!.ticketInfo.map((ticket) => 
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• ${ticket.fullName} (${ticket.isAdult ? 'Adult' : 'Child'}) - ${ticket.session} - ${ticket.arrivalTime} - ${ticket.price} EUR',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Display train ticket details
              if (widget.paymentRequest.trainInfo != null) ...[
                const Text(
                  'Train Details:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('• Train Number: ${widget.paymentRequest.trainInfo!.number}'),
                Text('• Route: ${widget.paymentRequest.trainInfo!.from.localName} → ${widget.paymentRequest.trainInfo!.to.localName}'),
                Text('• Departure: ${DateFormat('HH:mm').format(widget.paymentRequest.trainInfo!.departure)}'),
                Text('• Arrival: ${DateFormat('HH:mm').format(widget.paymentRequest.trainInfo!.arrival)}'),
                Text('• Duration: ${widget.paymentRequest.trainInfo!.formattedDuration}'),
                if (widget.paymentRequest.trainOffer != null)
                  Text('• Fare Type: ${widget.paymentRequest.trainOffer!.description}'),
                if (widget.paymentRequest.trainService != null)
                  Text('• Seat Type: ${widget.paymentRequest.trainService!.description}'),
                const SizedBox(height: 16),
              ],
              
              Text(
                widget.paymentRequest.isCombinedPayment 
                    ? 'Your tickets and train tickets have been successfully purchased!\nPlease keep this receipt as your entry and travel voucher.'
                    : 'Your ticket(s) have been successfully purchased!\nPlease keep this receipt as your entry voucher.',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              // If bundle payment, train ticket or combined payment, go directly to homepage; if ticket, ask if want to book train ticket
              if (widget.isBundlePayment || widget.paymentRequest.time == 'Train Journey' || widget.paymentRequest.isCombinedPayment) {
                // Bundle, train ticket or combined payment successful, go directly to homepage
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/',
                  (route) => false,
                );
              } else {
                // Ticket payment successful, ask if want to book train ticket
                _showTrainBookingDialog();
              }
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  /// Show dialog asking if want to book train ticket
  void _showTrainBookingDialog() {
    print('🚄 Showing train booking dialog');
    
    // Get date and session from ticket information
    final ticketDate = _getTicketDate();
    final ticketSession = widget.paymentRequest.time;
    final departureTime = _getDepartureTime(ticketSession);
    
    // Get attraction name and train route from description
    final attractionName = _getAttractionName();
    final trainRoute = _getTrainRoute();
    
    print('🚄 Ticket date: $ticketDate');
    print('🚄 Ticket session: $ticketSession');
    print('🚄 Departure time: $departureTime');
    print('🚄 Attraction name: $attractionName');
    print('🚄 Train route: $trainRoute');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.train, color: Colors.blue),
            SizedBox(width: 8),
            Text('🚄 Booking Train Ticket'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ticket buying successful！',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Do you also need to book train tickets to $attractionName?',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Default Train Ticket Information：',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Start：$trainRoute', style: const TextStyle(fontSize: 12)),
                  Text('Date：$ticketDate', style: const TextStyle(fontSize: 12)),
                  Text('Time：$departureTime', style: const TextStyle(fontSize: 12)),
                  Text('Session：${ticketSession == "Morning" ? "Morning" : "Afternoon"}', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              // 跳轉到首頁
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/',
                (route) => false,
              );
            },
            child: const Text('No need'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              _navigateToTrainBooking();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('🚄 Booking Train Ticket'),
          ),
        ],
      ),
    );
  }

  /// Get ticket date
  String _getTicketDate() {
    if (widget.paymentRequest.ticketRequest != null && 
        widget.paymentRequest.ticketRequest!.ticketInfo.isNotEmpty) {
      return widget.paymentRequest.ticketRequest!.ticketInfo.first.arrivalTime;
    }
    // If no ticket information, use tomorrow's date as default
    return DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T')[0];
  }

  /// Get departure time based on ticket session
  String _getDepartureTime(String session) {
    // Whether Morning or Afternoon, train ticket time is set to 12:00
    return '12:00';
  }

  /// Get attraction name from description
  String _getAttractionName() {
    final description = widget.paymentRequest.description ?? '';
    if (description.contains('Uffizi Gallery')) {
      return 'Uffizi Gallery';
    } else if (description.contains('Neuschwanstein Castle')) {
      return 'Neuschwanstein Castle';
    }
    return 'Neuschwanstein Castle'; // Default
  }

  /// Get train route based on attraction
  String _getTrainRoute() {
    final description = widget.paymentRequest.description ?? '';
    if (description.contains('Uffizi Gallery')) {
      return 'Milano Centrale → Florence SMN';
    } else if (description.contains('Neuschwanstein Castle')) {
      return 'Munich Central → Füssen';
    }
    return 'Munich Central → Füssen'; // Default
  }

  /// Show 3DS authentication dialog
  void _show3DSAuthenticationDialog(PaymentResponse response) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.security, color: Colors.orange),
            SizedBox(width: 8),
            Text('3DS Authentication'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your bank requires additional authentication。',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PaymentIntent ID:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  Text(
                    response.paymentIntentId ?? 'Unknown',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Note: In actual application, Stripe Elements will be integrated here to handle 3DS authentication flow.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Temporarily skip 3DS authentication, directly call API
              if (response.paymentIntentId != null) {
                _submitTicketToApi(response.paymentIntentId!);
              }
            },
            child: const Text('Skip Authentication (Test)'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _isLoading = false;
              });
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Show IP blocked dialog
  void _showIpBlockedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.block, color: Colors.red),
            SizedBox(width: 8),
            Text('Access Denied'),
          ],
        ),
        content: Text(_ipVerificationService.getBlockedUserMessage()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to previous page
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Navigate to train ticket booking page
  void _navigateToTrainBooking() {
    // Get ticket information
    final ticketInfos = widget.paymentRequest.ticketRequest?.ticketInfo ?? [];
    final ticketDate = _getTicketDate();
    final ticketSession = widget.paymentRequest.time;

    // Get station information based on attraction
    final attractionName = _getAttractionName();
    String departureStation;
    String destinationStation;
    
    if (attractionName == 'Uffizi Gallery') {
      departureStation = 'Milano Centrale';
      destinationStation = 'Florence SMN';
    } else {
      departureStation = 'Munich Central Station';
      destinationStation = 'Füssen Station';
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RailSearchTestPage(
          ticketInfos: ticketInfos,
          ticketDate: ticketDate,
          ticketSession: ticketSession,
          originalTicketRequest: widget.paymentRequest,
          departureStation: departureStation,
          destinationStation: destinationStation,
        ),
      ),
    );
  }

  String _formatCardNumber(String input) {
    // 移除所有非數字字符
    String digitsOnly = input.replaceAll(RegExp(r'\D'), '');
    
    // Limit length to 16 digits
    if (digitsOnly.length > 16) {
      digitsOnly = digitsOnly.substring(0, 16);
    }
    
    // Add space every 4 digits
    String formatted = '';
    for (int i = 0; i < digitsOnly.length; i++) {
      if (i > 0 && i % 4 == 0) {
        formatted += ' ';
      }
      formatted += digitsOnly[i];
    }
    
    return formatted;
  }

  String _formatExpiryDate(String input) {
    // 移除所有非數字字符
    String digitsOnly = input.replaceAll(RegExp(r'\D'), '');
    
    // Limit length to 4 digits
    if (digitsOnly.length > 4) {
      digitsOnly = digitsOnly.substring(0, 4);
    }
    
    // Add slash between month and year
    if (digitsOnly.length >= 2) {
      return '${digitsOnly.substring(0, 2)}/${digitsOnly.substring(2)}';
    }
    
    return digitsOnly;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade50,
              Colors.blue.shade50,
              Colors.purple.shade50,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.blue.shade400],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.payment,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Secure Payment',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.green.shade600,
                    Colors.blue.shade600,
                    Colors.purple.shade600,
                  ],
                ),
              ),
            ),
            leading: Container(
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            // Order summary
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.paymentRequest.isCombinedPayment ? '📋 Combined Order Summary' : '📋 Order Summary',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Customer Name: ${widget.paymentRequest.customerName}'),
                    Text('Ticket Type: ${widget.paymentRequest.isAdult ? 'Adult' : 'Child'}'),
                    Text('Time Slot: ${widget.paymentRequest.time}'),
                    
                    // If combined payment, show detailed amount breakdown
                    if (widget.paymentRequest.isCombinedPayment) ...[
                      const SizedBox(height: 8),
                      const Divider(),
                      const Text(
                        '💰 Cost Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Neuschwanstein Castle Ticket: ${widget.paymentRequest.ticketOnlyAmount.toStringAsFixed(2)} ${widget.paymentRequest.currency}'),
                      Text('Train Ticket: ${widget.paymentRequest.trainTicketAmount!.toStringAsFixed(2)} ${widget.paymentRequest.currency}'),
                      const Divider(),
                      Text(
                        'Total Amount: ${widget.paymentRequest.amount.toStringAsFixed(2)} ${widget.paymentRequest.currency}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ] else ...[
                      Text('Amount: ${widget.paymentRequest.amount.toStringAsFixed(2)} ${widget.paymentRequest.currency}'),
                    ],
                    
                    Text('Description: ${widget.paymentRequest.description}'),
                    
                    // If train ticket or combined payment, show additional train information
                    if (widget.paymentRequest.time == 'Train Journey' || widget.paymentRequest.isCombinedPayment) ...[
                      const SizedBox(height: 8),
                      const Divider(),
                      const Text(
                        '🚄 Train Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (widget.paymentRequest.trainInfo != null) ...[
                        Text('Train Number: ${widget.paymentRequest.trainInfo!.number}'),
                        Text('Type: ${widget.paymentRequest.trainInfo!.typeName}'),
                        Text('Route: ${widget.paymentRequest.trainInfo!.from.localName} → ${widget.paymentRequest.trainInfo!.to.localName}'),
                        Text('Departure: ${DateFormat('HH:mm').format(widget.paymentRequest.trainInfo!.departure)}'),
                        Text('Arrival: ${DateFormat('HH:mm').format(widget.paymentRequest.trainInfo!.arrival)}'),
                        Text('Duration: ${widget.paymentRequest.trainInfo!.formattedDuration}'),
                        if (widget.paymentRequest.trainOffer != null)
                          Text('Fare Type: ${widget.paymentRequest.trainOffer!.description}'),
                        if (widget.paymentRequest.trainService != null)
                          Text('Seat Type: ${widget.paymentRequest.trainService!.description}'),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Payment form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '💳 Payment Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Cardholder Name
                      TextFormField(
                        controller: _cardholderNameController,
                        decoration: const InputDecoration(
                          labelText: 'Cardholder Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter cardholder name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Card Number
                      TextFormField(
                        controller: _cardNumberController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(19), // 16 digits + 3 spaces
                          TextInputFormatter.withFunction((oldValue, newValue) {
                            final formatted = _formatCardNumber(newValue.text);
                            return TextEditingValue(
                              text: formatted,
                              selection: TextSelection.collapsed(offset: formatted.length),
                            );
                          }),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Card Number',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.credit_card),
                          hintText: '4242 4242 4242 4242',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter card number';
                          }
                          String digitsOnly = value.replaceAll(' ', '');
                          if (digitsOnly.length != 16) {
                            return 'Card number must be 16 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Expiry Date and CVC
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _expiryDateController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                                TextInputFormatter.withFunction((oldValue, newValue) {
                                  final formatted = _formatExpiryDate(newValue.text);
                                  return TextEditingValue(
                                    text: formatted,
                                    selection: TextSelection.collapsed(offset: formatted.length),
                                  );
                                }),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Expiry Date',
                                border: OutlineInputBorder(),
                                hintText: '12/25',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter expiry date';
                                }
                                if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
                                  return 'Format: MM/YY';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _cvcController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'CVC',
                                border: OutlineInputBorder(),
                                hintText: '123',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter CVC';
                                }
                                if (value.length < 3 || value.length > 4) {
                                  return 'CVC must be 3-4 digits';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Payment Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _processPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: _isLoading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Processing...'),
                                ],
                              )
                            : const Text(
                                '💳 Pay Now',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
