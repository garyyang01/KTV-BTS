import 'package:flutter/material.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/content_display_widget.dart';
import '../models/search_option.dart';
import 'my_train_tickets_page.dart';

/// Main Page - Unified ticket search and booking page
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  SearchOption? _selectedOption;

  void _clearSelection() {
    setState(() {
      _selectedOption = null;
    });
  }

  /// Navigate to my tickets page
  void _navigateToMyTickets() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MyTrainTicketsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          '🎫 Ticketrip',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _navigateToMyTickets,
            icon: const Icon(Icons.confirmation_number),
            tooltip: 'My Train Tickets',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search section
              _buildSearchSection(),
              
              const SizedBox(height: 24),
              
              // Content area
              ContentDisplayWidget(
                selectedOption: _selectedOption,
                onClearSelection: _clearSelection,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build search section
  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              Icon(
                Icons.search,
                color: Colors.blue.shade600,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Search for Destinations',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Search component
          SearchBarWidget(
            hintText: 'Type destination...',
            onSelectionChanged: (option) {
              setState(() {
                _selectedOption = option;
              });
            },
          ),
        ],
      ),
    );
  }

}
