import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 鐵路班次解決方案卡片組件
/// 用於顯示搜尋到的火車班次詳細信息
class RailSolutionCard extends StatelessWidget {
  final dynamic solution;
  final int index;
  final VoidCallback? onTap;

  const RailSolutionCard({
    super.key,
    required this.solution,
    required this.index,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 12),
              _buildRouteInfo(context),
              const SizedBox(height: 12),
              _buildPriceInfo(context),
              if (solution is Map && _hasDetailedInfo(solution)) ...[
                const SizedBox(height: 12),
                _buildDetailedInfo(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '班次 $index',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (solution is Map && solution.containsKey('carrier'))
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  solution['carrier'] ?? 'Unknown',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        if (solution is Map && solution.containsKey('duration'))
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              solution['duration'] ?? '',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRouteInfo(BuildContext context) {
    if (solution is Map && _hasRouteInfo(solution)) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            _buildLocationRow(
              context,
              solution['from'] ?? 'Unknown',
              solution['departure'] ?? '',
              true,
            ),
            const SizedBox(height: 8),
            Container(
              height: 1,
              color: Colors.grey.shade300,
              child: const Center(
                child: Icon(
                  Icons.arrow_downward,
                  size: 16,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildLocationRow(
              context,
              solution['to'] ?? 'Unknown',
              solution['arrival'] ?? '',
              false,
            ),
          ],
        ),
      );
    }

    // 顯示原始數據
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        '路線信息: ${solution.toString()}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  Widget _buildLocationRow(BuildContext context, String location, String time, bool isDeparture) {
    return Row(
      children: [
        Icon(
          isDeparture ? Icons.play_arrow : Icons.flag,
          color: isDeparture ? Colors.green : Colors.red,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            location,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          _formatTime(time),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceInfo(BuildContext context) {
    if (solution is Map && solution.containsKey('price')) {
      final price = solution['price'];
      final currency = solution['currency'] ?? 'EUR';
      
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.green.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '價格',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${_getCurrencySymbol(currency)}${price.toString()}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (solution.containsKey('train_number'))
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  solution['train_number'] ?? '',
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildDetailedInfo(BuildContext context) {
    return ExpansionTile(
      title: Text(
        '詳細信息',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '原始數據:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  solution.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _hasRouteInfo(Map<String, dynamic> solution) {
    return solution.containsKey('from') && 
           solution.containsKey('to') &&
           (solution.containsKey('departure') || solution.containsKey('arrival'));
  }

  bool _hasDetailedInfo(Map<String, dynamic> solution) {
    return solution.keys.length > 5; // 如果有超過 5 個字段，顯示詳細信息
  }

  String _formatTime(String time) {
    if (time.isEmpty) return '';
    
    try {
      // 嘗試解析 ISO 8601 格式
      final dateTime = DateTime.parse(time);
      return DateFormat('HH:mm').format(dateTime);
    } catch (e) {
      // 如果不是 ISO 格式，直接返回
      return time;
    }
  }

  String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'EUR':
        return '€';
      case 'USD':
        return '\$';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      default:
        return '$currency ';
    }
  }
}
