import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// 價格顯示組件
/// 根據票券列表動態顯示總價
class PriceDisplay extends StatelessWidget {
  final List<Map<String, dynamic>> tickets;
  final int adultPrice;
  final int childPrice;

  const PriceDisplay({
    super.key,
    required this.tickets,
    this.adultPrice = 19,
    this.childPrice = 1,
  });

  /// 計算單張票價
  int getTicketPrice(bool isAdult) => isAdult ? adultPrice : childPrice;
  
  /// 計算總價
  int get totalPrice {
    return tickets.fold(0, (sum, ticket) {
      return sum + getTicketPrice(ticket['isAdult'] ?? true);
    });
  }

  /// 計算成人票數量
  int get adultCount {
    return tickets.where((ticket) => ticket['isAdult'] == true).length;
  }

  /// 計算兒童票數量
  int get childCount {
    return tickets.where((ticket) => ticket['isAdult'] == false).length;
  }

  @override
  Widget build(BuildContext context) {
    if (tickets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade600 : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E2E) : Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.priceSummary,
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          
          // Adult tickets
          if (adultCount > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Adult Ticket${adultCount > 1 ? 's' : ''} (${adultCount}x)',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  '€${adultCount * adultPrice}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          
          // Child tickets
          if (childCount > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Under 18 Ticket${childCount > 1 ? 's' : ''} (${childCount}x)',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  childPrice == 0 ? 'Free' : '€${childCount * childPrice}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          
          // Total
          if (tickets.length > 1) ...[
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total (${tickets.length} ticket${tickets.length > 1 ? 's' : ''})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '€$totalPrice',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '€$totalPrice',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
