import 'package:flutter/material.dart';
import '../models/train_ticket.dart';

/// 訂單摘要組件
/// 顯示城堡門票總價、火車票價格和總金額
class OrderSummaryWidget extends StatelessWidget {
  final double castleTicketsTotal;
  final TrainTicket? selectedTrainTicket;
  final bool showTrainTicketLine;

  const OrderSummaryWidget({
    super.key,
    required this.castleTicketsTotal,
    this.selectedTrainTicket,
    this.showTrainTicketLine = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題
          _buildSectionTitle(),
          const SizedBox(height: 12),
          
          // 城堡門票
          _buildCastleTicketsLine(),
          
          // 火車票（如果需要顯示）
          if (showTrainTicketLine) ...[
            const SizedBox(height: 8),
            _buildTrainTicketLine(),
          ],
          
          // 分隔線
          const SizedBox(height: 12),
          _buildDivider(),
          const SizedBox(height: 12),
          
          // 總金額
          _buildTotalLine(),
        ],
      ),
    );
  }

  /// 建立區段標題
  Widget _buildSectionTitle() {
    return const Text(
      'Order Summary',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// 建立城堡門票行
  Widget _buildCastleTicketsLine() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Castle Tickets',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        Text(
          _formatPrice(castleTicketsTotal),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  /// 建立火車票行
  Widget _buildTrainTicketLine() {
    final trainTicketPrice = selectedTrainTicket?.price ?? 0.0;
    final isSelected = selectedTrainTicket != null;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            isSelected 
                ? 'Train Ticket (${selectedTrainTicket!.trainName})'
                : 'Train Ticket',
            style: TextStyle(
              fontSize: 14,
              color: isSelected ? Colors.black87 : Colors.grey.shade600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          isSelected 
              ? _formatPrice(trainTicketPrice)
              : '${_formatPrice(0.0)} (optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.black87 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  /// 建立分隔線
  Widget _buildDivider() {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade300,
            Colors.grey.shade200,
            Colors.grey.shade300,
          ],
        ),
      ),
    );
  }

  /// 建立總金額行
  Widget _buildTotalLine() {
    final trainTicketPrice = selectedTrainTicket?.price ?? 0.0;
    final totalAmount = castleTicketsTotal + trainTicketPrice;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Total',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          _formatPrice(totalAmount),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  /// 格式化價格顯示
  String _formatPrice(double price) {
    return '€${price.toStringAsFixed(2)}';
  }

  /// 計算總金額
  double get totalAmount {
    final trainTicketPrice = selectedTrainTicket?.price ?? 0.0;
    return castleTicketsTotal + trainTicketPrice;
  }
}

/// 訂單摘要建構器
/// 提供便利方法建立不同配置的訂單摘要
class OrderSummaryBuilder {
  /// 建立基本的訂單摘要（只有城堡門票）
  static Widget castleOnly(double castleTicketsTotal) {
    return OrderSummaryWidget(
      castleTicketsTotal: castleTicketsTotal,
      showTrainTicketLine: false,
    );
  }

  /// 建立完整的訂單摘要（包含火車票選項）
  static Widget withTrainOption({
    required double castleTicketsTotal,
    TrainTicket? selectedTrainTicket,
  }) {
    return OrderSummaryWidget(
      castleTicketsTotal: castleTicketsTotal,
      selectedTrainTicket: selectedTrainTicket,
      showTrainTicketLine: true,
    );
  }

  /// 建立緊湊版本的訂單摘要（只顯示總金額）
  static Widget compact({
    required double castleTicketsTotal,
    TrainTicket? selectedTrainTicket,
  }) {
    final trainTicketPrice = selectedTrainTicket?.price ?? 0.0;
    final totalAmount = castleTicketsTotal + trainTicketPrice;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total Amount',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '€${totalAmount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}

/// 動畫版本的訂單摘要
/// 當價格變化時提供平滑的動畫效果
class AnimatedOrderSummary extends StatefulWidget {
  final double castleTicketsTotal;
  final TrainTicket? selectedTrainTicket;
  final bool showTrainTicketLine;
  final Duration animationDuration;

  const AnimatedOrderSummary({
    super.key,
    required this.castleTicketsTotal,
    this.selectedTrainTicket,
    this.showTrainTicketLine = true,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<AnimatedOrderSummary> createState() => _AnimatedOrderSummaryState();
}

class _AnimatedOrderSummaryState extends State<AnimatedOrderSummary>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  TrainTicket? _previousSelectedTicket;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _previousSelectedTicket = widget.selectedTrainTicket;
  }

  @override
  void didUpdateWidget(AnimatedOrderSummary oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 如果選中的火車票發生變化，觸發動畫
    if (widget.selectedTrainTicket?.ticketId != _previousSelectedTicket?.ticketId) {
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
      _previousSelectedTicket = widget.selectedTrainTicket;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: OrderSummaryWidget(
            castleTicketsTotal: widget.castleTicketsTotal,
            selectedTrainTicket: widget.selectedTrainTicket,
            showTrainTicketLine: widget.showTrainTicketLine,
          ),
        );
      },
    );
  }
}
