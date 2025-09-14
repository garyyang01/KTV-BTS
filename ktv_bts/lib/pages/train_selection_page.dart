import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/train_solution.dart';
import '../models/payment_request.dart';
import 'payment_page.dart';

/// Train schedule selection page
class TrainSelectionPage extends StatefulWidget {
  final List<TrainSolution> solutions;
  final PaymentRequest? originalTicketRequest; // Original ticket payment request (for combined payment)
  final String? passengerEmail; // Email from homepage
  final String? passengerFirstName; // First name from homepage
  final String? passengerLastName; // Last name from homepage

  const TrainSelectionPage({
    super.key,
    required this.solutions,
    this.originalTicketRequest,
    this.passengerEmail,
    this.passengerFirstName,
    this.passengerLastName,
  });

  @override
  State<TrainSelectionPage> createState() => _TrainSelectionPageState();
}

class _TrainSelectionPageState extends State<TrainSelectionPage> {
  int? selectedSolutionIndex;
  int? selectedOfferIndex;
  int? selectedServiceIndex;
  int? selectedTrainIndex;
  
  // Passenger information form controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passportController = TextEditingController();
  final _birthdateController = TextEditingController();
  String _selectedGender = 'male';
  
  // Form validation key
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Auto-fill form with data from homepage
    if (widget.passengerEmail != null) {
      _emailController.text = widget.passengerEmail!;
    }
    if (widget.passengerFirstName != null) {
      _firstNameController.text = widget.passengerFirstName!;
    }
    if (widget.passengerLastName != null) {
      _lastNameController.text = widget.passengerLastName!;
    }
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
              Colors.blue.shade50,
              Colors.purple.shade50,
              Colors.orange.shade50,
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
                      colors: [Colors.blue.shade400, Colors.purple.shade400],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.train,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Select Train Schedule',
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
                    Colors.blue.shade600,
                    Colors.purple.shade600,
                    Colors.orange.shade600,
                  ],
                ),
              ),
            ),
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
                      const SizedBox(height: 20),
                      
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
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.95),
                        Colors.blue.shade50.withOpacity(0.9),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                    border: Border(
                      top: BorderSide(
                        color: Colors.blue.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (selectedSolutionIndex != null && selectedTrainIndex != null && selectedServiceIndex != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.green.shade50, Colors.blue.shade50],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade600,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Selected Train',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${widget.solutions[selectedSolutionIndex!].trains[selectedTrainIndex!].number} - ${widget.solutions[selectedSolutionIndex!].offers[selectedOfferIndex!].services[selectedServiceIndex!].description}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green.shade700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
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
                              backgroundColor: _canProceed() 
                                  ? Colors.blue.shade600 
                                  : Colors.grey.shade400,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: _canProceed() ? 4 : 0,
                              shadowColor: Colors.blue.withOpacity(0.3),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_canProceed()) ...[
                                  const Icon(Icons.confirmation_number, size: 20),
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                  _canProceed() ? 'Confirm Selection' : 'Please select train and fare',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
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
              ],
            ),
          ),
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
                // Carrier information
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
                            '${solution.offers.length} fare options',
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
            // Reset fare selection
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
              // Selection indicator
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
              
              // Train number information
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
              
              // Departure information
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
              
              // Arrow
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward, size: 16),
              ),
              
              // Arrival information
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
              
              // Time and stop information
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
                        '${train.stops.length} stops',
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
                'Duration: ${train.formattedDuration}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              if (train.stops.isNotEmpty)
                Text(
                  '${train.stops.length} stops',
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
              
              // Service options
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
                        'Available Seats: ${service.available.seats}',
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
                        'Selected',
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.blue.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.purple.shade50],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.purple.shade400],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Passenger Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Name Fields
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      labelText: 'First Name *',
                      labelStyle: TextStyle(color: Colors.grey.shade600),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      prefixIcon: Icon(Icons.person_outline, color: Colors.blue.shade400),
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
                    decoration: InputDecoration(
                      labelText: 'Last Name *',
                      labelStyle: TextStyle(color: Colors.grey.shade600),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      prefixIcon: Icon(Icons.person_outline, color: Colors.blue.shade400),
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
              decoration: InputDecoration(
                labelText: 'Email *',
                labelStyle: TextStyle(color: Colors.grey.shade600),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                prefixIcon: Icon(Icons.email_outlined, color: Colors.blue.shade400),
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
              decoration: InputDecoration(
                labelText: 'Phone Number *',
                labelStyle: TextStyle(color: Colors.grey.shade600),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                prefixIcon: Icon(Icons.phone_outlined, color: Colors.blue.shade400),
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
                    decoration: InputDecoration(
                      labelText: 'Passport Number *',
                      labelStyle: TextStyle(color: Colors.grey.shade600),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      prefixIcon: Icon(Icons.badge_outlined, color: Colors.blue.shade400),
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
                    decoration: InputDecoration(
                      labelText: 'Birthdate (YYYY-MM-DD) *',
                      labelStyle: TextStyle(color: Colors.grey.shade600),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      prefixIcon: Icon(Icons.calendar_today_outlined, color: Colors.blue.shade400),
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
              decoration: InputDecoration(
                labelText: 'Gender *',
                labelStyle: TextStyle(color: Colors.grey.shade600),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                prefixIcon: Icon(Icons.person_outline, color: Colors.blue.shade400),
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
