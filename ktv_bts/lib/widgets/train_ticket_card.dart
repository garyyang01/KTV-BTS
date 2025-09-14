import 'package:flutter/material.dart';
import '../models/train_ticket.dart';

/// 火車票卡片組件
/// 顯示火車票的詳細資訊，支援選擇狀態
class TrainTicketCard extends StatelessWidget {
  final TrainTicket ticket;
  final bool isSelected;
  final VoidCallback? onTap;

  const TrainTicketCard({
    super.key,
    required this.ticket,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 車種名稱和類型
            _buildTrainHeader(),
            const SizedBox(height: 12),
            
            // 路線顯示
            _buildRouteDisplay(),
            const SizedBox(height: 12),
            
            // 時間和價格資訊
            _buildTimeAndPriceInfo(),
            
            // 選擇按鈕
            if (!isSelected) ...[
              const SizedBox(height: 12),
              _buildSelectButton(),
            ],
          ],
        ),
      ),
    );
  }

  /// 建立車種標題
  Widget _buildTrainHeader() {
    return Row(
      children: [
        Icon(
          Icons.train,
          color: _getTrainTypeColor(),
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            ticket.trainName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getTrainTypeColor().withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            ticket.trainType,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _getTrainTypeColor(),
            ),
          ),
        ),
      ],
    );
  }

  /// 建立路線顯示
  Widget _buildRouteDisplay() {
    return Row(
      children: [
        // 起始站
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ticket.originStation,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                ticket.departureTime,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        
        // 箭頭和行程時間
        Expanded(
          flex: 1,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade400)),
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade400)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                ticket.duration,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        
        // 終點站
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                ticket.destinationStation,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
              Text(
                ticket.arrivalTime,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 建立時間和價格資訊
  Widget _buildTimeAndPriceInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Duration: ${ticket.duration}',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          '€${ticket.price.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  /// 建立選擇按鈕
  Widget _buildSelectButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 36),
          side: BorderSide(color: Colors.blue.shade400),
        ),
        child: const Text(
          'Select This Ticket',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// 根據車種類型獲取顏色
  Color _getTrainTypeColor() {
    switch (ticket.trainType.toUpperCase()) {
      case 'ICE':
        return Colors.red;
      case 'IC':
        return Colors.orange;
      case 'RE':
      case 'REGIONAL EXPRESS':
        return Colors.blue;
      case 'R':
      case 'REGIONAL':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
