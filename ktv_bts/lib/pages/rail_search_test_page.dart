import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/rail_booking_service.dart';
import '../models/rail_search_criteria.dart';
import '../models/rail_api_response.dart';
import '../models/train_solution.dart';
import '../models/ticket_info.dart';
import '../models/payment_request.dart';
import '../widgets/rail_solution_card.dart';
import 'train_selection_page.dart';

/// Railway Search Test Page
/// Provides UI interface to test G2Rail API search functionality
class RailSearchTestPage extends StatefulWidget {
  final List<TicketInfo>? ticketInfos; // Passenger data from ticket information
  final String? ticketDate; // Date from ticket information
  final String? ticketSession; // Session from ticket information
  final PaymentRequest? originalTicketRequest; // Original ticket payment request (for combined payment)

  const RailSearchTestPage({
    super.key,
    this.ticketInfos,
    this.ticketDate,
    this.ticketSession,
    this.originalTicketRequest,
  });

  @override
  State<RailSearchTestPage> createState() => _RailSearchTestPageState();
}

class _RailSearchTestPageState extends State<RailSearchTestPage> {
  final _formKey = GlobalKey<FormState>();
  final _fromController = TextEditingController(text: 'ST_EMYR64OX'); // Munich train station code
  final _toController = TextEditingController(text: 'ST_E7G93QNJ'); // Füssen train station code
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _adultController = TextEditingController(text: '1');
  final _childController = TextEditingController(text: '0');
  final _juniorController = TextEditingController(text: '0');
  final _seniorController = TextEditingController(text: '0');
  final _infantController = TextEditingController(text: '0');

  late RailBookingService _railService;
  bool _isLoading = false;
  String _statusMessage = '';
  AsyncResultResponse? _searchResults;
  List<TrainSolution> _trainSolutions = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _railService = RailBookingService.defaultInstance();
    
    // Pre-fill form based on ticket information
    _initializeFormFromTicketInfo();
  }

  /// Initialize form based on ticket information
  void _initializeFormFromTicketInfo() {
    // Set date
    if (widget.ticketDate != null) {
      _dateController.text = widget.ticketDate!;
    } else {
      // Default date is tomorrow
      final defaultDate = DateTime.now().add(const Duration(days: 1));
      _dateController.text = DateFormat('yyyy-MM-dd').format(defaultDate);
    }

    // Set departure time based on ticket session
    // Whether Morning or Afternoon, train ticket time is set to 12:00
    _timeController.text = '12:00';

    // Set passenger count based on ticket information
    if (widget.ticketInfos != null && widget.ticketInfos!.isNotEmpty) {
      int adultCount = 0;
      int childCount = 0;
      
      for (var ticketInfo in widget.ticketInfos!) {
        if (ticketInfo.isAdult) {
          adultCount++;
        } else {
          childCount++;
        }
      }
      
      _adultController.text = adultCount.toString();
      _childController.text = childCount.toString();
    }
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _adultController.dispose();
    _childController.dispose();
    _juniorController.dispose();
    _seniorController.dispose();
    _infantController.dispose();
    _railService.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Searching for train schedules...';
      _searchResults = null;
      _trainSolutions = [];
      _errorMessage = '';
    });

    try {
      // Create search criteria
      final criteria = RailSearchCriteria(
        from: _fromController.text.trim(),
        to: _toController.text.trim(),
        date: _dateController.text.trim(),
        time: _timeController.text.trim(),
        adult: int.tryParse(_adultController.text) ?? 1,
        child: int.tryParse(_childController.text) ?? 0,
        junior: int.tryParse(_juniorController.text) ?? 0,
        senior: int.tryParse(_seniorController.text) ?? 0,
        infant: int.tryParse(_infantController.text) ?? 0,
      );

      setState(() {
        _statusMessage = 'Search criteria: ${criteria.from} → ${criteria.to}';
      });

      // Execute search
      final result = await _railService.searchAndGetResults(criteria);

      setState(() {
        _isLoading = false;
        
        if (result.success) {
          _searchResults = result.data;
          _trainSolutions = _parseTrainSolutions(result.data?.solutions ?? []);
          _statusMessage = 'Search completed! Found ${_trainSolutions.length} schedule options';
          _errorMessage = '';
        } else {
          _errorMessage = result.errorMessage ?? 'Search failed';
          _statusMessage = 'Search failed';
          _searchResults = null;
          _trainSolutions = [];
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Search exception: ${e.toString()}';
        _statusMessage = 'Search exception';
        _searchResults = null;
        _trainSolutions = [];
      });
    }
  }

  /// Parse train schedule solutions
  List<TrainSolution> _parseTrainSolutions(List<dynamic> solutions) {
    final List<TrainSolution> trainSolutions = [];
    
    print('🔍 Starting to parse ${solutions.length} schedule solutions');
    
    for (int i = 0; i < solutions.length; i++) {
      var solution = solutions[i];
      print('🔍 Parsing solution ${i + 1}: ${solution.runtimeType}');
      
      if (solution is Map<String, dynamic>) {
        print('🔍 Solution content: ${solution.keys.toList()}');
        
        try {
          // Check if there is actual solutions data
          List<dynamic> solutionsData = solution['solutions'] as List<dynamic>? ?? [];
          print('🔍 Check solutions data: ${solutionsData.length} items');
          
          // Only process schedules with actual data
          if (solutionsData.isNotEmpty) {
            // Check if it is a valid schedule solution
            bool hasRequiredFields = false;
            
            // Check multiple possible structures
            if (solution.containsKey('offers') && solution.containsKey('trains')) {
              hasRequiredFields = true;
              print('✅ Found standard structure (offers + trains)');
            } else if (solution.containsKey('railway')) {
              hasRequiredFields = true;
              print('✅ Found railway structure');
            } else if (solution.containsKey('carrier')) {
              hasRequiredFields = true;
              print('✅ Found carrier structure');
            } else {
              print('❌ No standard structure found, try direct parsing');
              hasRequiredFields = true; // Try direct parsing
            }
            
            if (hasRequiredFields) {
              final trainSolution = TrainSolution.fromJson(solution);
              // Only add when TrainSolution has actual offers or trains
              if (trainSolution.offers.isNotEmpty || trainSolution.trains.isNotEmpty) {
                trainSolutions.add(trainSolution);
                print('✅ Successfully parsed schedule solution: ${trainSolution.carrierDescription} (${trainSolution.offers.length} offers, ${trainSolution.trains.length} trains)');
              } else {
                print('⚠️ Skipping empty data schedule solution: ${trainSolution.carrierDescription}');
              }
            }
          } else {
            print('⚠️ Skipping schedule without solutions data');
          }
        } catch (e) {
          print('❌ Error occurred while parsing schedule solution: $e');
          print('❌ Solution content: $solution');
        }
      } else {
        print('❌ Solution is not Map type: ${solution.runtimeType}');
      }
    }
    
    print('🎯 Final parsing result: ${trainSolutions.length} valid schedule solutions');
    return trainSolutions;
  }

  /// Navigate to schedule selection page
  void _navigateToTrainSelection() {
    if (_trainSolutions.isEmpty) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TrainSelectionPage(
          solutions: _trainSolutions,
          originalTicketRequest: widget.originalTicketRequest,
        ),
      ),
    );
  }

  Widget _buildSearchForm() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🚄 Neuschwanstein Castle Train Ticket Booking',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Route: Munich → Füssen',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Departure and destination
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _fromController,
                      decoration: const InputDecoration(
                        labelText: 'From Munich Central Station (ST_EMYR64OX)',
                        hintText: 'ST_EMYR64OX',
                        border: OutlineInputBorder(),
                        helperText: 'Munich to Füssen',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter departure location';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.arrow_forward),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _toController,
                      decoration: const InputDecoration(
                        labelText: 'To Füssen Station (ST_E7G93QNJ)',
                        hintText: 'ST_E7G93QNJ',
                        border: OutlineInputBorder(),
                        helperText: 'Füssen',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter destination';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Date and time
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dateController,
                      decoration: const InputDecoration(
                        labelText: 'Departure Date',
                        hintText: 'yyyy-MM-dd',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          _dateController.text = DateFormat('yyyy-MM-dd').format(date);
                        }
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please select departure date';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _timeController,
                      decoration: const InputDecoration(
                        labelText: 'Departure Time',
                        hintText: 'HH:mm',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter departure time';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Passenger count
              Text(
                '👥 Passenger Count',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _adultController,
                      decoration: const InputDecoration(
                        labelText: 'Adults',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final count = int.tryParse(value ?? '');
                        if (count == null || count < 0) {
                          return 'Please enter valid adult count';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _childController,
                      decoration: const InputDecoration(
                        labelText: 'Children',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final count = int.tryParse(value ?? '');
                        if (count == null || count < 0) {
                          return 'Please enter valid children count';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Show default junior, senior, infant counts
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          'Junior',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '0',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          'Senior',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '0',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          'Infant',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '0',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Search button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _performSearch,
                  icon: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                  label: Text(_isLoading ? 'Searching...' : 'Start Search'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    if (_statusMessage.isEmpty && _errorMessage.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📊 Search Status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (_statusMessage.isNotEmpty)
              Text(
                _statusMessage,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    if (_trainSolutions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '🚄 Search Results (${_trainSolutions.length} schedule options)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _navigateToTrainSelection,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Select Schedule'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Show schedule summary
            ..._trainSolutions.asMap().entries.map((entry) {
              final index = entry.key;
              final solution = entry.value;
              return _buildSolutionSummary(solution, index);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSolutionSummary(TrainSolution solution, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carrier title
          Row(
            children: [
              Text(
                '${index + 1}. ${solution.carrierDescription}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${solution.offers.length} fare types',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Train schedule list
          if (solution.trains.isNotEmpty) ...[
            Text(
              '🚂 Train Schedule',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            ...solution.trains.asMap().entries.map((entry) {
              final trainIndex = entry.key;
              final train = entry.value;
              return _buildTrainSummary(train, trainIndex);
            }),
            const SizedBox(height: 16),
          ],
          
          // Price information
          Row(
            children: [
              Text(
                '💰 Price Range: ',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _getLowestPrice(solution),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrainSummary(TrainInfo train, int trainIndex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          // Train number information
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  train.number,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  train.typeName,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  train.from.localName,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          
          // Arrow
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
          ),
          
          // Arrival information
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('HH:mm').format(train.arrival),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  train.to.localName,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
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
    );
  }

  String _getLowestPrice(TrainSolution solution) {
    int lowestCents = 999999;
    String currency = 'EUR';
    
    for (var offer in solution.offers) {
      for (var service in offer.services) {
        if (service.price.cents < lowestCents) {
          lowestCents = service.price.cents;
          currency = service.price.currency;
        }
      }
    }
    
    return '$currency ${(lowestCents / 100).toStringAsFixed(2)}';
  }

  void _showSolutionDetails(dynamic solution, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Schedule $index Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (solution is Map) ...[
                if (solution.containsKey('from') && solution.containsKey('to'))
                  _buildDetailRow('Route', '${solution['from']} → ${solution['to']}'),
                if (solution.containsKey('departure'))
                  _buildDetailRow('Departure Time', solution['departure']),
                if (solution.containsKey('arrival'))
                  _buildDetailRow('Arrival Time', solution['arrival']),
                if (solution.containsKey('duration'))
                  _buildDetailRow('Duration', solution['duration']),
                if (solution.containsKey('train_number'))
                  _buildDetailRow('Train Number', solution['train_number']),
                if (solution.containsKey('carrier'))
                  _buildDetailRow('Carrier', solution['carrier']),
                if (solution.containsKey('price'))
                  _buildDetailRow('Price', '€${solution['price']}'),
              ],
              const SizedBox(height: 16),
              Text(
                'Raw Data:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  solution.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🚄 Railway Search Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSearchForm(),
            const SizedBox(height: 16),
            _buildStatusSection(),
            const SizedBox(height: 16),
            _buildResultsSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
