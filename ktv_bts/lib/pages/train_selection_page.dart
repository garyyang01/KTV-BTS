import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/train_solution.dart';
import '../models/payment_request.dart';
import 'payment_page.dart';

/// 火車班次選擇頁面
class TrainSelectionPage extends StatefulWidget {
  final List<TrainSolution> solutions;
  final PaymentRequest? originalTicketRequest; // 原始門票支付請求（用於組合支付）

  const TrainSelectionPage({
    super.key,
    required this.solutions,
    this.originalTicketRequest,
  });

  @override
  State<TrainSelectionPage> createState() => _TrainSelectionPageState();
}

class _TrainSelectionPageState extends State<TrainSelectionPage> {
  int? selectedSolutionIndex;
  int? selectedOfferIndex;
  int? selectedServiceIndex;
  int? selectedTrainIndex;
  
  // 乘客資訊表單控制器
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passportController = TextEditingController();
  final _birthdateController = TextEditingController();
  String _selectedGender = 'male';
  
  // 表單驗證鍵
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🚄 Select Train Schedule'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Passenger Information Form
                  _buildPassengerInfoForm(),
                  const SizedBox(height: 16),
                  
                  // Train Schedule Selection
                  ...widget.solutions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final solution = entry.value;
                    return _buildSolutionCard(solution, index);
                  }).toList(),
                ],
              ),
            ),
            
            // Confirm Button
            Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selectedSolutionIndex != null && selectedTrainIndex != null && selectedServiceIndex != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '已選擇: ${widget.solutions[selectedSolutionIndex!].trains[selectedTrainIndex!].number} - ${widget.solutions[selectedSolutionIndex!].offers[selectedOfferIndex!].services[selectedServiceIndex!].description}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _canProceed() ? _confirmSelection : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _canProceed() ? 'Confirm Selection' : 'Please select train and fare',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildSolutionCard(TrainSolution solution, int solutionIndex) {
    final isSelected = selectedSolutionIndex == solutionIndex;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isSelected ? 8 : 2,
      child: InkWell(
        onTap: () {
          setState(() {
            selectedSolutionIndex = solutionIndex;
            selectedOfferIndex = null;
            selectedServiceIndex = null;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                ? Theme.of(context).primaryColor 
                : Colors.transparent,
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 營運商信息
                Row(
                  children: [
                    if (solution.carrierIcon.isNotEmpty)
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade100,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            'https://sematicweb.detie.cn/railway_images/${solution.carrierIcon}',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.train,
                                color: Theme.of(context).primaryColor,
                              );
                            },
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            solution.carrierDescription,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${solution.offers.length} 種票價選項',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: Theme.of(context).primaryColor,
                      ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Train Schedule Information
                if (solution.trains.isNotEmpty) ...[
                  Text(
                    '🚂 Train Schedule (Please select a train)',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...solution.trains.asMap().entries.map((entry) {
                    final trainIndex = entry.key;
                    final train = entry.value;
                    return _buildSelectableTrainInfo(train, solutionIndex, trainIndex);
                  }),
                ],
                
                const SizedBox(height: 16),
                
                // Fare Options
                if (solution.offers.isNotEmpty) ...[
                  Text(
                    '💰 Fare Options',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...solution.offers.asMap().entries.map((entry) {
                    final offerIndex = entry.key;
                    final offer = entry.value;
                    return _buildOfferCard(offer, solutionIndex, offerIndex);
                  }),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectableTrainInfo(TrainInfo train, int solutionIndex, int trainIndex) {
    final isSelected = selectedSolutionIndex == solutionIndex && 
                      selectedTrainIndex == trainIndex;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            selectedSolutionIndex = solutionIndex;
            selectedTrainIndex = trainIndex;
            // 重置票價選擇
            selectedOfferIndex = null;
            selectedServiceIndex = null;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected 
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected 
                ? Theme.of(context).primaryColor 
                : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // 選擇指示器
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected 
                      ? Theme.of(context).primaryColor 
                      : Colors.grey.shade400,
                    width: 2,
                  ),
                  color: isSelected 
                    ? Theme.of(context).primaryColor 
                    : Colors.transparent,
                ),
                child: isSelected 
                  ? const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    )
                  : null,
              ),
              const SizedBox(width: 12),
              
              // 車次信息
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      train.number,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isSelected 
                          ? Theme.of(context).primaryColor 
                          : Colors.black,
                      ),
                    ),
                    Text(
                      train.typeName,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 出發信息
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('HH:mm').format(train.departure),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isSelected 
                          ? Theme.of(context).primaryColor 
                          : Colors.black,
                      ),
                    ),
                    Text(
                      train.from.localName,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 箭頭
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward, size: 16),
              ),
              
              // 到達信息
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('HH:mm').format(train.arrival),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isSelected 
                          ? Theme.of(context).primaryColor 
                          : Colors.black,
                      ),
                    ),
                    Text(
                      train.to.localName,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 時間和停靠站信息
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      train.formattedDuration,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    if (train.stops.isNotEmpty)
                      Text(
                        '${train.stops.length} 站',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrainInfo(TrainInfo train) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      train.number,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      train.typeName,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text(
                    DateFormat('HH:mm').format(train.departure),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    train.from.localName,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward, size: 16),
              ),
              Column(
                children: [
                  Text(
                    DateFormat('HH:mm').format(train.arrival),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    train.to.localName,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '行程時間: ${train.formattedDuration}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              if (train.stops.isNotEmpty)
                Text(
                  '${train.stops.length} 個停靠站',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard(TrainOffer offer, int solutionIndex, int offerIndex) {
    final isSelected = selectedSolutionIndex == solutionIndex && 
                      selectedOfferIndex == offerIndex;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            selectedSolutionIndex = solutionIndex;
            selectedOfferIndex = offerIndex;
            selectedServiceIndex = null;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected 
                ? Theme.of(context).primaryColor 
                : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            color: isSelected 
              ? Theme.of(context).primaryColor.withOpacity(0.05)
              : Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          offer.description,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected 
                              ? Theme.of(context).primaryColor 
                              : Colors.black,
                          ),
                        ),
                        Text(
                          offer.ticketType,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // 服務選項
              ...offer.services.asMap().entries.map((entry) {
                final serviceIndex = entry.key;
                final service = entry.value;
                return _buildServiceCard(
                  service, 
                  solutionIndex, 
                  offerIndex, 
                  serviceIndex
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard(
    TrainService service, 
    int solutionIndex, 
    int offerIndex, 
    int serviceIndex
  ) {
    final isSelected = selectedSolutionIndex == solutionIndex && 
                      selectedOfferIndex == offerIndex &&
                      selectedServiceIndex == serviceIndex;
    
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            selectedSolutionIndex = solutionIndex;
            selectedOfferIndex = offerIndex;
            selectedServiceIndex = serviceIndex;
          });
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected 
                ? Theme.of(context).primaryColor 
                : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
            color: isSelected 
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.grey.shade50,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.description,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected 
                          ? Theme.of(context).primaryColor 
                          : Colors.black,
                      ),
                    ),
                    if (service.available.seats > 0)
                      Text(
                        '剩餘座位: ${service.available.seats}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    service.price.formattedPrice,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isSelected 
                        ? Theme.of(context).primaryColor 
                        : Colors.black,
                    ),
                  ),
                  if (isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '已選擇',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _canProceed() {
    return selectedSolutionIndex != null && 
           selectedTrainIndex != null && 
           selectedOfferIndex != null && 
           selectedServiceIndex != null;
  }

  void _confirmSelection() {
    if (!_canProceed()) return;
    
    final solution = widget.solutions[selectedSolutionIndex!];
    final train = solution.trains[selectedTrainIndex!];
    final offer = solution.offers[selectedOfferIndex!];
    final service = offer.services[selectedServiceIndex!];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Selection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Train: ${train.number}'),
            Text('Type: ${train.typeName}'),
            Text('Departure: ${DateFormat('HH:mm').format(train.departure)} - ${train.from.localName}'),
            Text('Arrival: ${DateFormat('HH:mm').format(train.arrival)} - ${train.to.localName}'),
            Text('Duration: ${train.formattedDuration}'),
            const SizedBox(height: 8),
            Text('Fare Type: ${offer.description}'),
            Text('Seat Type: ${service.description}'),
            Text('Price: ${service.price.formattedPrice}'),
            if (service.available.seats > 0)
              Text('Available Seats: ${service.available.seats}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _proceedToPayment();
            },
            child: const Text('Confirm Booking'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passportController.dispose();
    _birthdateController.dispose();
    super.dispose();
  }

  /// Build Passenger Information Form
  Widget _buildPassengerInfoForm() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '👤 Passenger Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Name Fields
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'First Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter first name';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Last Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter last name';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Contact Information
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            
            // Passport and Birthdate
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _passportController,
                    decoration: const InputDecoration(
                      labelText: 'Passport Number *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter passport number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _birthdateController,
                    decoration: const InputDecoration(
                      labelText: 'Birthdate (YYYY-MM-DD) *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter birthdate';
                      }
                      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
                        return 'Please use YYYY-MM-DD format';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Gender Selection
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(
                labelText: 'Gender *',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'male', child: Text('Male')),
                DropdownMenuItem(value: 'female', child: Text('Female')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedGender = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Navigate to Payment Page
  void _proceedToPayment() {
    if (!_canProceed()) return;
    
    // Validate form
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in complete passenger information'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final solution = widget.solutions[selectedSolutionIndex!];
    final train = solution.trains[selectedTrainIndex!];
    final offer = solution.offers[selectedOfferIndex!];
    final service = offer.services[selectedServiceIndex!];
    
    // Get passenger information
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final customerName = '$firstName $lastName';
    
    PaymentRequest paymentRequest;
    
    if (widget.originalTicketRequest != null) {
      // Create combined payment (ticket + train ticket) PaymentRequest
      paymentRequest = PaymentRequest.forCombinedPayment(
        originalTicketRequest: widget.originalTicketRequest!,
        train: train,
        offer: offer,
        service: service,
        customerName: customerName,
        passengerFirstName: firstName,
        passengerLastName: lastName,
        passengerEmail: _emailController.text.trim(),
        passengerPhone: _phoneController.text.trim(),
        passengerPassport: _passportController.text.trim(),
        passengerBirthdate: _birthdateController.text.trim(),
        passengerGender: _selectedGender,
      );
    } else {
      // Create train ticket only PaymentRequest
      paymentRequest = PaymentRequest.forTrainTicket(
        customerName: customerName,
        train: train,
        offer: offer,
        service: service,
        passengerFirstName: firstName,
        passengerLastName: lastName,
        passengerEmail: _emailController.text.trim(),
        passengerPhone: _phoneController.text.trim(),
        passengerPassport: _passportController.text.trim(),
        passengerBirthdate: _birthdateController.text.trim(),
        passengerGender: _selectedGender,
      );
    }
    
    // Navigate to payment page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(paymentRequest: paymentRequest),
      ),
    );
  }
}
