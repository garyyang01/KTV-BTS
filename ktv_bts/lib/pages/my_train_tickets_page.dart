import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/ticket_storage_service.dart';
import '../models/online_confirmation_response.dart';
import '../models/online_ticket_response.dart';

/// 我的火車票頁面
/// 顯示用戶已購買的火車票
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

  /// 載入火車票數據
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
      print('❌ 載入火車票數據失敗: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的火車票'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '重新載入',
            onPressed: _loadTicketData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orderIds.isEmpty
              ? _buildEmptyState()
              : _buildTicketList(),
    );
  }

  /// 建立空狀態
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.train,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '還沒有火車票',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '購買火車票後，票券資訊會顯示在這裡',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.search),
            label: const Text('搜尋火車票'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// 建立票券列表
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

  /// 建立票券卡片
  Widget _buildTicketCard(
    String orderId,
    OnlineConfirmationResponse confirmation,
    OnlineTicketResponse? ticketFiles,
  ) {
    final order = confirmation.order;
    final departureDate = DateTime.parse(order.departure);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標題行
            Row(
              children: [
                Icon(
                  Icons.train,
                  color: Colors.blue.shade600,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${order.from.localName} → ${order.to.localName}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '已確認',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // 行程資訊
            _buildInfoRow('🎫 PNR', order.pnr),
            _buildInfoRow('🚂 列車', order.railway.code),
            _buildInfoRow('📅 出發日期', DateFormat('yyyy-MM-dd').format(departureDate)),
            _buildInfoRow('⏰ 出發時間', DateFormat('HH:mm').format(departureDate)),
            
            // 座位資訊
            if (order.reservations.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(),
              const Text(
                '座位資訊',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              ...order.reservations.map((reservation) => 
                _buildInfoRow('🚂 ${reservation.trainName}', '車廂 ${reservation.car} 座位 ${reservation.seat}')
              ),
            ],
            
            // 乘客資訊
            if (order.passengers.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(),
              const Text(
                '乘客資訊',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              ...order.passengers.map((passenger) => 
                _buildInfoRow('👤 乘客', '${passenger.firstName} ${passenger.lastName}')
              ),
            ],
            
            // 票券文件
            if (ticketFiles != null && ticketFiles.tickets.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(),
              const Text(
                '票券文件',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ticketFiles.tickets.map((ticket) => 
                  _buildTicketFileButton(ticket)
                ).toList(),
              ),
            ],
            
            // 登機資訊
            if (confirmation.ticketCheckIns.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(),
              const Text(
                '登機資訊',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              ...confirmation.ticketCheckIns.map((checkIn) => 
                _buildInfoRow('🔗 登機連結', '點擊查看'),
              ),
            ],
            
            const SizedBox(height: 12),
            
            // 操作按鈕
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showTicketDetails(orderId, confirmation, ticketFiles),
                    icon: const Icon(Icons.info_outline),
                    label: const Text('詳細資訊'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _shareTicket(orderId, confirmation),
                    icon: const Icon(Icons.share),
                    label: const Text('分享'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
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

  /// 建立資訊行
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

  /// 建立票券文件按鈕
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
              ticket.ticketTypeDisplayName,
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

  /// 顯示票券詳細資訊
  void _showTicketDetails(
    String orderId,
    OnlineConfirmationResponse confirmation,
    OnlineTicketResponse? ticketFiles,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('票券詳細資訊'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('訂單ID: $orderId'),
              Text('PNR: ${confirmation.order.pnr}'),
              Text('路線: ${confirmation.order.from.localName} → ${confirmation.order.to.localName}'),
              Text('出發時間: ${confirmation.order.departure}'),
              Text('支付價格: ${confirmation.paymentPrice.cents / 100} ${confirmation.paymentPrice.currency}'),
              Text('收費價格: ${confirmation.chargingPrice.cents / 100} ${confirmation.chargingPrice.currency}'),
              if (ticketFiles != null) ...[
                const SizedBox(height: 8),
                const Text('票券文件:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...ticketFiles.tickets.map((ticket) => 
                  Text('• ${ticket.ticketTypeDisplayName}: ${ticket.file}')
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('關閉'),
          ),
        ],
      ),
    );
  }

  /// 分享票券
  void _shareTicket(String orderId, OnlineConfirmationResponse confirmation) {
    final order = confirmation.order;
    final shareText = '''
🚂 火車票資訊
路線: ${order.from.localName} → ${order.to.localName}
PNR: ${order.pnr}
出發時間: ${order.departure}
訂單ID: $orderId
''';

    Clipboard.setData(ClipboardData(text: shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('票券資訊已複製到剪貼板'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// 開啟票券文件
  void _openTicketFile(TicketFile ticket) {
    // 這裡可以實現實際的文件開啟邏輯
    // 例如：使用 url_launcher 開啟 PDF 或顯示手機票券
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ticket.ticketTypeDisplayName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('文件類型: ${ticket.kind}'),
            const SizedBox(height: 8),
            Text('下載連結:'),
            SelectableText(
              ticket.file,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('關閉'),
          ),
          ElevatedButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: ticket.file));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('下載連結已複製到剪貼板'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('複製連結'),
          ),
        ],
      ),
    );
  }
}
