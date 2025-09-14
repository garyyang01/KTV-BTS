import 'package:flutter/material.dart';
import '../models/search_option.dart';

/// 內容顯示組件 - 根據搜索選擇動態顯示不同的票券申請區塊
class ContentDisplayWidget extends StatefulWidget {
  final SearchOption? selectedOption;
  final VoidCallback? onClearSelection;

  const ContentDisplayWidget({
    super.key,
    this.selectedOption,
    this.onClearSelection,
  });

  @override
  State<ContentDisplayWidget> createState() => _ContentDisplayWidgetState();
}

class _ContentDisplayWidgetState extends State<ContentDisplayWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void didUpdateWidget(ContentDisplayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedOption != oldWidget.selectedOption) {
      if (widget.selectedOption != null) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          // 標題區域
          _buildHeader(),
          
          const SizedBox(height: 16),
          
          // 動態內容區域
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: child,
                ),
              );
            },
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  /// 建立標題區域
  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.confirmation_number,
          color: Colors.orange.shade600,
          size: 24,
        ),
        const SizedBox(width: 8),
        const Text(
          'Ticket Application',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const Spacer(),
        if (widget.selectedOption != null)
          IconButton(
            onPressed: widget.onClearSelection,
            icon: Icon(
              Icons.refresh,
              color: Colors.grey.shade600,
            ),
            tooltip: 'Clear selection',
          ),
      ],
    );
  }

  /// 建立動態內容
  Widget _buildContent() {
    if (widget.selectedOption == null) {
      return _buildEmptyState();
    }

    switch (widget.selectedOption!.type) {
      case SearchOptionType.station:
        return _buildStationContent();
      case SearchOptionType.attraction:
        return _buildAttractionContent();
    }
  }

  /// 建立空狀態顯示
  Widget _buildEmptyState() {
    return Container(
      key: const ValueKey('empty'),
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Colors.grey.shade300,
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Select a destination to start booking',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Use the search box above to find trains or attractions',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          // 快速選擇建議
          _buildQuickSelections(),
        ],
      ),
    );
  }

  /// 建立車站內容
  Widget _buildStationContent() {
    return Container(
      key: const ValueKey('station'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 選中的車站資訊
          _buildSelectedOptionInfo(),
          
          const SizedBox(height: 20),
          
          // 車站票券預覽
          _buildStationTicketPreview(),
          
          const SizedBox(height: 20),
          
          // 開始預訂按鈕
          _buildBookingButton('Book Train Tickets'),
        ],
      ),
    );
  }

  /// 建立景點內容
  Widget _buildAttractionContent() {
    return Container(
      key: const ValueKey('attraction'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 選中的景點資訊
          _buildSelectedOptionInfo(),
          
          const SizedBox(height: 20),
          
          // 景點門票預覽
          _buildAttractionTicketPreview(),
          
          const SizedBox(height: 20),
          
          // 開始預訂按鈕
          _buildBookingButton('Book Attraction Tickets'),
        ],
      ),
    );
  }

  /// 建立選中選項資訊
  Widget _buildSelectedOptionInfo() {
    final option = widget.selectedOption!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: option.type == SearchOptionType.station 
            ? Colors.blue.shade50 
            : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: option.type == SearchOptionType.station 
              ? Colors.blue.shade200 
              : Colors.orange.shade200,
        ),
      ),
      child: Row(
        children: [
          Text(
            option.icon,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  option.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: option.type == SearchOptionType.station
                        ? Colors.blue.shade100
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    option.type == SearchOptionType.station ? 'Train Station' : 'Tourist Attraction',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: option.type == SearchOptionType.station
                          ? Colors.blue.shade700
                          : Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 建立車站票券預覽
  Widget _buildStationTicketPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.train, color: Colors.blue.shade600, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Train Ticket Features',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(Icons.route, 'Multiple destination options'),
          _buildFeatureItem(Icons.schedule, 'Flexible departure times'),
          _buildFeatureItem(Icons.people, 'Adult and child tickets'),
          _buildFeatureItem(Icons.confirmation_number, 'Instant booking confirmation'),
        ],
      ),
    );
  }

  /// 建立景點門票預覽
  Widget _buildAttractionTicketPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_activity, color: Colors.orange.shade600, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Attraction Ticket Features',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(Icons.access_time, 'Morning and afternoon sessions'),
          _buildFeatureItem(Icons.family_restroom, 'Family-friendly pricing'),
          _buildFeatureItem(Icons.calendar_today, 'Flexible date selection'),
          _buildFeatureItem(Icons.email, 'Email confirmation'),
        ],
      ),
    );
  }

  /// 建立功能項目
  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  /// 建立預訂按鈕
  Widget _buildBookingButton(String text) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // TODO: 導航到對應的預訂頁面
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening $text for ${widget.selectedOption!.name}'),
              backgroundColor: Colors.green.shade600,
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.selectedOption!.type == SearchOptionType.station
              ? Colors.blue.shade600
              : Colors.orange.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// 建立快速選擇建議
  Widget _buildQuickSelections() {
    final quickOptions = [
      {'icon': '🚉', 'name': 'Munich Central', 'type': 'Station'},
      {'icon': '🏰', 'name': 'Neuschwanstein Castle', 'type': 'Attraction'},
      {'icon': '🎨', 'name': 'Uffizi Gallery', 'type': 'Attraction'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Popular destinations:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: quickOptions.map((option) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    option['icon']!,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    option['name']!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}