import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/ticket_storage_service.dart';
import '../models/online_confirmation_response.dart';
import '../models/online_ticket_response.dart';

/// My Train Tickets Page
/// Displays user's purchased train tickets
class MyTrainTicketsPage extends StatefulWidget {
  const MyTrainTicketsPage({super.key});

  @override
  State<MyTrainTicketsPage> createState() => _MyTrainTicketsPageState();
}

class _MyTrainTicketsPageState extends State<MyTrainTicketsPage> {
  List<String> _orderIds = [];
  Map<String, OnlineConfirmationResponse> _confirmations = {};
  Map<String, OnlineTicketResponse> _ticketFiles = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTicketData();
  }

  /// Load train ticket data
  Future<void> _loadTicketData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final orderIds = await TicketStorageService.getAllOrderIds();
      final confirmations = <String, OnlineConfirmationResponse>{};
      final ticketFiles = <String, OnlineTicketResponse>{};

      for (final orderId in orderIds) {
        final confirmation = await TicketStorageService.getTicketConfirmation(orderId);
        final files = await TicketStorageService.getTicketFiles(orderId);
        
        if (confirmation != null) {
          confirmations[orderId] = confirmation;
        }
        if (files != null) {
          ticketFiles[orderId] = files;
        }
      }

      setState(() {
        _orderIds = orderIds;
        _confirmations = confirmations;
        _ticketFiles = ticketFiles;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Failed to load train ticket data: $e');
      setState(() {
        _isLoading = false;
      });
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
            colors: Theme.of(context).brightness == Brightness.dark ? [
              const Color(0xFF1A1A2E),
              const Color(0xFF16213E),
              const Color(0xFF0F3460),
            ] : [
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
                    Icons.confirmation_number,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.myTrainTickets,
                  style: const TextStyle(
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
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  tooltip: AppLocalizations.of(context)!.reload,
                  onPressed: _loadTicketData,
                ),
              ),
            ],
          ),
          body: _isLoading
              ? Center(
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.black.withOpacity(0.3) 
                              : Colors.blue.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue.shade400, Colors.purple.shade400],
                            ),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          AppLocalizations.of(context)!.loadingYourTickets,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.blue.shade400 
                                : Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _orderIds.isEmpty
                  ? _buildEmptyState()
                  : _buildTicketList(),
        ),
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.black.withOpacity(0.3) 
                  : Colors.blue.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.blue.withOpacity(0.3) 
                : Colors.blue.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade100, Colors.purple.shade100],
                ),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.train,
                size: 60,
                color: Colors.blue.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.noTrainTicketsYet,
              style: TextStyle(
                fontSize: 24,
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.blue.shade400 
                    : Colors.blue.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.trainTicketInfoWillBeDisplayed,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white70 
                    : Colors.grey.shade600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.purple.shade400],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.search, color: Colors.white),
                label: Text(
                  AppLocalizations.of(context)!.searchTrainTickets,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build ticket list
  Widget _buildTicketList() {
    return RefreshIndicator(
      onRefresh: _loadTicketData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orderIds.length,
        itemBuilder: (context, index) {
          final orderId = _orderIds[index];
          final confirmation = _confirmations[orderId];
          final ticketFiles = _ticketFiles[orderId];

          if (confirmation == null) {
            return const SizedBox.shrink();
          }

          return _buildTicketCard(orderId, confirmation, ticketFiles);
        },
      ),
    );
  }

  /// Build ticket card
  Widget _buildTicketCard(
    String orderId,
    OnlineConfirmationResponse confirmation,
    OnlineTicketResponse? ticketFiles,
  ) {
    final order = confirmation.order;
    final departureDate = DateTime.parse(order.departure);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section with route and status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.purple.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.train,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${order.from.localName} → ${order.to.localName}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.white 
                                : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Train ${order.railway.code}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.white70 
                                : Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.confirmed,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Trip information section
            _buildSectionHeader(AppLocalizations.of(context)!.tripInformation, Icons.info_outline),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? const Color(0xFF2A2A2A) 
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.grey.shade600 
                      : Colors.grey.shade200,
                ),
              ),
              child: Column(
                children: [
                  _buildEnhancedInfoRow(Icons.confirmation_number, AppLocalizations.of(context)!.pnrLabel, order.pnr),
                  const SizedBox(height: 12),
                  _buildEnhancedInfoRow(Icons.calendar_today, AppLocalizations.of(context)!.departureDate, DateFormat('yyyy-MM-dd').format(departureDate)),
                  const SizedBox(height: 12),
                  _buildEnhancedInfoRow(Icons.access_time, AppLocalizations.of(context)!.departureTime, DateFormat('HH:mm').format(departureDate)),
                ],
              ),
            ),
            
            // Seat information
            if (order.reservations.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildSectionHeader(AppLocalizations.of(context)!.seatInformation, Icons.event_seat),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.blue.shade900.withOpacity(0.3) 
                    : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.blue.shade600 
                      : Colors.blue.shade200,
                ),
              ),
                child: Column(
                  children: order.reservations.asMap().entries.map((entry) {
                    final index = entry.key;
                    final reservation = entry.value;
                    return Column(
                      children: [
                        if (index > 0) const SizedBox(height: 12),
                        _buildEnhancedInfoRow(
                          Icons.train, 
                          reservation.trainName, 
                          '${AppLocalizations.of(context)!.car} ${reservation.car} ${AppLocalizations.of(context)!.seat} ${reservation.seat}'
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
            
            // Passenger information
            if (order.passengers.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildSectionHeader(AppLocalizations.of(context)!.passengerInformation, Icons.person),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.green.shade900.withOpacity(0.3) 
                    : Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.green.shade600 
                      : Colors.green.shade200,
                ),
              ),
                child: Column(
                  children: order.passengers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final passenger = entry.value;
                    return Column(
                      children: [
                        if (index > 0) const SizedBox(height: 12),
                        _buildEnhancedInfoRow(
                          Icons.person_outline, 
                          AppLocalizations.of(context)!.passenger, 
                          '${passenger.firstName} ${passenger.lastName}'
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
            
            // Ticket files
            if (ticketFiles != null && ticketFiles.tickets.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildSectionHeader(AppLocalizations.of(context)!.ticketFiles, Icons.file_download),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: ticketFiles.tickets.map((ticket) => 
                  _buildEnhancedTicketFileButton(ticket)
                ).toList(),
              ),
            ],
            
            // Check-in information
            if (confirmation.ticketCheckIns.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildSectionHeader(AppLocalizations.of(context)!.checkInInformation, Icons.qr_code),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.orange.shade900.withOpacity(0.3) 
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.orange.shade600 
                      : Colors.orange.shade200,
                ),
              ),
                child: Column(
                  children: confirmation.ticketCheckIns.asMap().entries.map((entry) {
                    final index = entry.key;
                    return Column(
                      children: [
                        if (index > 0) const SizedBox(height: 12),
                        _buildEnhancedInfoRow(Icons.link, AppLocalizations.of(context)!.checkInLink, AppLocalizations.of(context)!.clickToView),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showTicketDetails(orderId, confirmation, ticketFiles),
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: Text(AppLocalizations.of(context)!.details),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.blue.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _shareTicket(orderId, confirmation),
                    icon: const Icon(Icons.share, size: 18),
                    label: Text(AppLocalizations.of(context)!.share),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build section header
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.blue.shade600,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700,
          ),
        ),
      ],
    );
  }

  /// Build enhanced info row
  Widget _buildEnhancedInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 16,
            color: Colors.blue.shade600,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white70 
                      : Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white 
                      : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build info row (legacy method for compatibility)
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build enhanced ticket file button
  Widget _buildEnhancedTicketFileButton(TicketFile ticket) {
    return InkWell(
      onTap: () => _openTicketFile(ticket),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: ticket.isPdfTicket 
                ? [Colors.red.shade50, Colors.red.shade100]
                : [Colors.blue.shade50, Colors.blue.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ticket.isPdfTicket ? Colors.red.shade300 : Colors.blue.shade300,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: ticket.isPdfTicket ? Colors.red.shade100 : Colors.blue.shade100,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: ticket.isPdfTicket ? Colors.red.shade600 : Colors.blue.shade600,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                ticket.isPdfTicket ? Icons.picture_as_pdf : Icons.phone_android,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              ticket.isPdfTicket ? AppLocalizations.of(context)!.pdfTicket : AppLocalizations.of(context)!.mobileTicket,
              style: TextStyle(
                fontSize: 14,
                color: ticket.isPdfTicket ? Colors.red.shade700 : Colors.blue.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build ticket file button (legacy method for compatibility)
  Widget _buildTicketFileButton(TicketFile ticket) {
    return InkWell(
      onTap: () => _openTicketFile(ticket),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: ticket.isPdfTicket ? Colors.red.shade50 : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: ticket.isPdfTicket ? Colors.red.shade200 : Colors.blue.shade200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              ticket.isPdfTicket ? Icons.picture_as_pdf : Icons.phone_android,
              size: 16,
              color: ticket.isPdfTicket ? Colors.red.shade600 : Colors.blue.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              ticket.isPdfTicket ? AppLocalizations.of(context)!.pdfTicket : AppLocalizations.of(context)!.mobileTicket,
              style: TextStyle(
                fontSize: 12,
                color: ticket.isPdfTicket ? Colors.red.shade700 : Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show ticket details
  void _showTicketDetails(
    String orderId,
    OnlineConfirmationResponse confirmation,
    OnlineTicketResponse? ticketFiles,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.ticketDetails),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${AppLocalizations.of(context)!.orderId}: $orderId'),
              Text('${AppLocalizations.of(context)!.pnr}: ${confirmation.order.pnr}'),
              Text('${AppLocalizations.of(context)!.route}: ${confirmation.order.from.localName} → ${confirmation.order.to.localName}'),
              Text('${AppLocalizations.of(context)!.departureTime}: ${confirmation.order.departure}'),
              Text('${AppLocalizations.of(context)!.paymentPrice}: ${confirmation.paymentPrice.cents / 100} ${confirmation.paymentPrice.currency}'),
              Text('${AppLocalizations.of(context)!.chargingPrice}: ${confirmation.chargingPrice.cents / 100} ${confirmation.chargingPrice.currency}'),
              if (ticketFiles != null) ...[
                const SizedBox(height: 8),
                Text('${AppLocalizations.of(context)!.ticketFiles}:', style: const TextStyle(fontWeight: FontWeight.bold)),
                ...ticketFiles.tickets.map((ticket) => 
                  Text('• ${ticket.isPdfTicket ? AppLocalizations.of(context)!.pdfTicket : AppLocalizations.of(context)!.mobileTicket}: ${ticket.file}')
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.close),
          ),
        ],
      ),
    );
  }

  /// Share ticket
  void _shareTicket(String orderId, OnlineConfirmationResponse confirmation) {
    final order = confirmation.order;
    final shareText = '''
🚂 Train Ticket Information
Route: ${order.from.localName} → ${order.to.localName}
PNR: ${order.pnr}
Departure Time: ${order.departure}
Order ID: $orderId
''';

    Clipboard.setData(ClipboardData(text: shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.ticketInfoCopied),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Open ticket file
  void _openTicketFile(TicketFile ticket) {
    // Here you can implement actual file opening logic
    // For example: use url_launcher to open PDF or display mobile ticket
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ticket.isPdfTicket ? AppLocalizations.of(context)!.pdfTicket : AppLocalizations.of(context)!.mobileTicket),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${AppLocalizations.of(context)!.fileType}: ${ticket.kind}'),
            const SizedBox(height: 8),
            Text('${AppLocalizations.of(context)!.downloadLink}:'),
            SelectableText(
              ticket.file,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.close),
          ),
          ElevatedButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: ticket.file));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.downloadLinkCopied),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text(AppLocalizations.of(context)!.copyLink),
          ),
        ],
      ),
    );
  }
}
