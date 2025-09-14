import 'package:flutter/material.dart';
import '../models/train_ticket.dart';
import 'train_ticket_card.dart';

/// 火車票列表組件
/// 顯示多張火車票，支援單選功能、載入狀態和空狀態
class TrainTicketList extends StatelessWidget {
  final List<TrainTicket> tickets;
  final TrainTicket? selectedTicket;
  final Function(TrainTicket)? onTicketSelected;
  final bool isLoading;
  final String? errorMessage;

  const TrainTicketList({
    super.key,
    required this.tickets,
    this.selectedTicket,
    this.onTicketSelected,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    // 載入狀態
    if (isLoading) {
      return _buildLoadingState();
    }

    // 錯誤狀態
    if (errorMessage != null) {
      return _buildErrorState();
    }

    // 空狀態
    if (tickets.isEmpty) {
      return _buildEmptyState();
    }

    // 正常列表顯示
    return _buildTicketsList();
  }

  /// 建立載入狀態
  Widget _buildLoadingState() {
    return const SizedBox(
      height: 300,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Searching for available trains...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'This may take a few moments',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// 建立錯誤狀態
  Widget _buildErrorState() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'Unable to load train tickets',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage ?? 'An unexpected error occurred',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              // TODO: 實作重試邏輯
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  /// 建立空狀態
  Widget _buildEmptyState() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.train_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'No trains available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'There are no train tickets available for your selected date and time.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              // TODO: 實作搜尋其他日期邏輯
            },
            icon: const Icon(Icons.search),
            label: const Text('Search Other Dates'),
          ),
        ],
      ),
    );
  }

  /// 建立火車票列表
  Widget _buildTicketsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 列表標題和數量
        _buildListHeader(),
        const SizedBox(height: 16),
        
        // 火車票列表
        Expanded(
          child: ListView.builder(
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              final isSelected = selectedTicket?.ticketId == ticket.ticketId;
              
              return TrainTicketCard(
                ticket: ticket,
                isSelected: isSelected,
                onTap: () => _handleTicketSelection(ticket),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 建立列表標題
  Widget _buildListHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Available trains for your trip:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${tickets.length} option${tickets.length != 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.blue.shade700,
            ),
          ),
        ),
      ],
    );
  }

  /// 處理火車票選擇
  void _handleTicketSelection(TrainTicket ticket) {
    if (onTicketSelected != null) {
      // 如果點擊的是已選中的票券，則取消選擇
      if (selectedTicket?.ticketId == ticket.ticketId) {
        onTicketSelected!(ticket); // 讓父組件處理取消選擇邏輯
      } else {
        // 選擇新的票券
        onTicketSelected!(ticket);
      }
    }
  }
}

/// 火車票列表的建構器類別
/// 提供便利的方法來建立不同狀態的列表
class TrainTicketListBuilder {
  /// 建立載入中的列表
  static Widget loading() {
    return const TrainTicketList(
      tickets: <TrainTicket>[],
      isLoading: true,
    );
  }

  /// 建立錯誤狀態的列表
  static Widget error(String message) {
    return TrainTicketList(
      tickets: const <TrainTicket>[],
      errorMessage: message,
    );
  }

  /// 建立空狀態的列表
  static Widget empty() {
    return const TrainTicketList(
      tickets: <TrainTicket>[],
    );
  }

  /// 建立正常的火車票列表
  static Widget withTickets({
    required List<TrainTicket> tickets,
    TrainTicket? selectedTicket,
    Function(TrainTicket)? onTicketSelected,
  }) {
    return TrainTicketList(
      tickets: tickets,
      selectedTicket: selectedTicket,
      onTicketSelected: onTicketSelected,
    );
  }
}
