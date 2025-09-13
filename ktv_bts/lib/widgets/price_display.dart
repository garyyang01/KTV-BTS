import 'package:flutter/material.dart';

/// 價格顯示組件
/// 根據年齡群組動態顯示票價
class PriceDisplay extends StatelessWidget {
  final bool isAdult;
  final int quantity;

  const PriceDisplay({
    super.key,
    required this.isAdult,
    this.quantity = 1,
  });

  /// 計算票價
  int get ticketPrice => isAdult ? 19 : 0;
  
  /// 計算總價
  int get totalPrice => ticketPrice * quantity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Price Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isAdult ? 'Adult Ticket' : 'Under 18 Ticket',
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                '€$ticketPrice',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          if (quantity > 1) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Quantity: $quantity'),
                Text(
                  'Total: €$totalPrice',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
