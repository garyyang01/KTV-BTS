import 'package:flutter/material.dart';

/// 火車票選擇頁面
/// 使用 Modal Bottom Sheet 或 Dialog 方式彈出
/// 讓使用者選擇火車票或跳過
class TrainTicketSelectionPage extends StatefulWidget {
  final double castleTicketsTotal; // 城堡門票總價

  const TrainTicketSelectionPage({
    super.key,
    required this.castleTicketsTotal,
  });

  @override
  State<TrainTicketSelectionPage> createState() => _TrainTicketSelectionPageState();
}

class _TrainTicketSelectionPageState extends State<TrainTicketSelectionPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 標題區域
          _buildHeader(),
          
          // 內容區域
          Expanded(
            child: _buildContent(),
          ),
          
          // 按鈕區域
          _buildButtonArea(),
        ],
      ),
    );
  }

  /// 建立標題區域
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Train Tickets',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: () => _closeModal(),
            icon: const Icon(Icons.close),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  /// 建立內容區域
  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available trains for your trip:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          
          // 火車票列表區域（暫時顯示佔位符）
          Expanded(
            child: _buildTrainTicketsList(),
          ),
        ],
      ),
    );
  }

  /// 建立火車票列表（暫時的佔位符）
  Widget _buildTrainTicketsList() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.train,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Train tickets will be displayed here',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 建立按鈕區域
  Widget _buildButtonArea() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          // 跳過按鈕
          Expanded(
            child: OutlinedButton(
              onPressed: () => _skipTrainTicket(),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Skip'),
            ),
          ),
          const SizedBox(width: 12),
          
          // 繼續按鈕（暫時禁用）
          Expanded(
            child: ElevatedButton(
              onPressed: null, // 暫時禁用，等待選擇火車票
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Continue with Selected'),
            ),
          ),
        ],
      ),
    );
  }

  /// 關閉彈出頁面
  void _closeModal() {
    Navigator.of(context).pop();
  }

  /// 跳過火車票選擇
  void _skipTrainTicket() {
    // TODO: 實作跳過邏輯，直接前往支付頁面
    Navigator.of(context).pop({'skipped': true});
  }

  /// 靜態方法：顯示火車票選擇頁面
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required double castleTicketsTotal,
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => TrainTicketSelectionPage(
          castleTicketsTotal: castleTicketsTotal,
        ),
      ),
    );
  }
}
