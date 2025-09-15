import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/search_option.dart';
import 'station_ticket_widget.dart';
import 'attraction_ticket_widget.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.blue.withOpacity(0.3) : Colors.transparent,
          width: 1,
        ),
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
        Text(
          AppLocalizations.of(context)!.ticketApplication,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
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
            tooltip: AppLocalizations.of(context)!.clearSelection,
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
            AppLocalizations.of(context)!.selectDestinationToStartBooking,
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          Text(
            AppLocalizations.of(context)!.useSearchBoxAbove,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// 建立車站內容
  Widget _buildStationContent() {
    return Container(
      key: const ValueKey('station'),
      child: StationTicketWidget(
        selectedStation: widget.selectedOption,
      ),
    );
  }

  /// 建立景點內容
  Widget _buildAttractionContent() {
    return Container(
      key: const ValueKey('attraction'),
      child: AttractionTicketWidget(
        selectedAttraction: widget.selectedOption,
      ),
    );
  }


}