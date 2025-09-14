import 'package:flutter/material.dart';
import '../models/search_option.dart';

/// 搜索欄組件 - 支援多語言關鍵字搜索的下拉選單
class SearchBarWidget extends StatefulWidget {
  final String hintText;
  final ValueChanged<SearchOption?> onSelectionChanged;
  final SearchOptionType? filterType;

  const SearchBarWidget({
    super.key,
    this.hintText = 'Search destinations...',
    required this.onSelectionChanged,
    this.filterType,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _textEditingController = TextEditingController();
  SearchOption? _selectedOption;
  late FocusNode _focusNode;
  List<SearchResult> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChanged);
    
    // 初始化搜索結果
    _updateSearchResults('');
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus && _selectedOption == null && _textEditingController.text.isNotEmpty) {
      _textEditingController.clear();
      _updateSearchResults('');
    }
  }

  void _updateSearchResults(String query) {
    setState(() {
      _searchResults = SearchService.performSearch(
        query,
        filterType: widget.filterType,
        limit: 10,
      );
    });
  }

  void _selectOption(SearchOption option) {
    setState(() {
      _selectedOption = option;
      _textEditingController.text = option.name;
    });
    widget.onSelectionChanged(option);
    _focusNode.unfocus();
  }

  void _clearSelection() {
    setState(() {
      _selectedOption = null;
      _textEditingController.clear();
      _updateSearchResults('');
    });
    widget.onSelectionChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 標題
        Text(
          'Where would you like to go?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        
        const SizedBox(height: 12),
        
        // 搜索輸入框
        Autocomplete<SearchOption>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            _updateSearchResults(textEditingValue.text);
            return _searchResults.map((result) => result.option);
          },
          
          displayStringForOption: (SearchOption option) => option.name,
          
          fieldViewBuilder: (
            BuildContext context,
            TextEditingController fieldTextEditingController,
            FocusNode fieldFocusNode,
            VoidCallback onFieldSubmitted,
          ) {
            // 同步控制器
            if (_textEditingController.text != fieldTextEditingController.text) {
              _textEditingController.text = fieldTextEditingController.text;
            }
            
            return TextFormField(
              controller: fieldTextEditingController,
              focusNode: fieldFocusNode,
              onChanged: (value) {
                _textEditingController.text = value;
                _updateSearchResults(value);
              },
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(color: Colors.grey.shade500),
                
                // 前綴圖標
                prefixIcon: Icon(
                  Icons.search,
                  color: _selectedOption != null ? Colors.green.shade600 : Colors.blue.shade600,
                ),
                
                // 後綴圖標
                suffixIcon: _selectedOption != null
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 選中狀態指示器
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: _selectedOption!.type == SearchOptionType.station
                                  ? Colors.blue.shade100
                                  : Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _selectedOption!.type == SearchOptionType.station ? 'Station' : 'Attraction',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: _selectedOption!.type == SearchOptionType.station
                                    ? Colors.blue.shade700
                                    : Colors.orange.shade700,
                              ),
                            ),
                          ),
                          // 清除按鈕
                          IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: _clearSelection,
                            tooltip: 'Clear selection',
                          ),
                        ],
                      )
                    : null,
                
                // 邊框樣式
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                
                // 填充樣式
                filled: true,
                fillColor: _selectedOption != null 
                    ? Colors.green.shade50 
                    : Colors.grey.shade100,
                
                // 內邊距
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                
                // 焦點邊框
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _selectedOption != null 
                        ? Colors.green.shade400 
                        : Colors.blue.shade400,
                    width: 2,
                  ),
                ),
              ),
              
              onTap: () {
                // 點擊時如果已選中，則清除選擇以允許新搜索
                if (_selectedOption != null) {
                  _clearSelection();
                }
              },
            );
          },
          
          optionsViewBuilder: (
            BuildContext context,
            AutocompleteOnSelected<SearchOption> onSelected,
            Iterable<SearchOption> options,
          ) {
            return _buildOptionsView(context, onSelected, options.toList());
          },
          
          onSelected: _selectOption,
        ),
        
        // 搜索統計信息
        if (_textEditingController.text.isNotEmpty && _selectedOption == null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${_searchResults.length} results found',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
      ],
    );
  }

  /// 建立選項視圖
  Widget _buildOptionsView(
    BuildContext context,
    AutocompleteOnSelected<SearchOption> onSelected,
    List<SearchOption> options,
  ) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 8.0,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: 300,
            maxWidth: MediaQuery.of(context).size.width - 32,
          ),
          child: options.isEmpty
              ? _buildNoResultsView()
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shrinkWrap: true,
                  itemCount: options.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: Colors.grey.shade200,
                  ),
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final searchResult = _searchResults.firstWhere(
                      (result) => result.option.id == option.id,
                      orElse: () => SearchResult(
                        option: option,
                        matchingKeywords: [],
                        relevanceScore: 0.0,
                      ),
                    );
                    
                    return _buildOptionTile(option, searchResult, onSelected);
                  },
                ),
        ),
      ),
    );
  }

  /// 建立選項磁貼
  Widget _buildOptionTile(
    SearchOption option,
    SearchResult searchResult,
    AutocompleteOnSelected<SearchOption> onSelected,
  ) {
    return InkWell(
      onTap: () => onSelected(option),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 主要信息行
            Row(
              children: [
                // 圖標
                Text(
                  option.icon,
                  style: const TextStyle(fontSize: 20),
                ),
                
                const SizedBox(width: 12),
                
                // 名稱和描述
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      
                      const SizedBox(height: 2),
                      
                      Text(
                        option.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 類型標籤
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: option.type == SearchOptionType.station
                        ? Colors.blue.shade100
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    option.type == SearchOptionType.station ? 'Station' : 'Attraction',
                    style: TextStyle(
                      fontSize: 11,
                      color: option.type == SearchOptionType.station
                          ? Colors.blue.shade800
                          : Colors.orange.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            // 匹配的關鍵字
            if (searchResult.matchingKeywords.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: searchResult.matchingKeywords.take(3).map((keyword) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      keyword,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            
            // 相關性分數（開發模式顯示）
            if (searchResult.relevanceScore > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Relevance: ${searchResult.relevanceScore.toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 建立無結果視圖
  Widget _buildNoResultsView() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: Colors.grey.shade400,
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'No destinations found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Try searching with different keywords',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 建議關鍵字
          Text(
            'Try: Munich, Florence, Castle, Gallery',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}