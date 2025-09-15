import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
  TextEditingController? _fieldTextEditingController;

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
    });
    _textEditingController.clear();
    _fieldTextEditingController?.clear();
    _updateSearchResults('');
    widget.onSelectionChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 標題
        Text(
          AppLocalizations.of(context)!.whereWouldYouLikeToGo,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white70 
                : Colors.grey.shade800,
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
            // 保存 fieldTextEditingController 的引用
            _fieldTextEditingController = fieldTextEditingController;
            
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
                suffixIcon: (_selectedOption != null || _textEditingController.text.isNotEmpty)
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 選中狀態指示器
                          if (_selectedOption != null)
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
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                
                // 填充樣式
                filled: true,
                fillColor: _selectedOption != null 
                    ? Colors.green.shade50 
                    : Colors.white,
                
                // 內邊距
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                
                // 焦點邊框
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: _selectedOption != null 
                        ? Colors.green.shade400 
                        : Colors.blue.shade400,
                    width: 2,
                  ),
                ),
                
                // 錯誤邊框
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.red.shade400, width: 2),
                ),
                
                // 啟用邊框
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: _selectedOption != null 
                        ? Colors.green.shade300 
                        : Colors.grey.shade300,
                    width: 1,
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
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 12.0,
                borderRadius: BorderRadius.circular(20),
                shadowColor: Colors.blue.withOpacity(0.2),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  constraints: BoxConstraints(
                    maxHeight: 350,
                    maxWidth: MediaQuery.of(context).size.width - 32,
                  ),
                  child: options.isEmpty
                      ? _buildNoResultsView()
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shrinkWrap: true,
                          itemCount: options.length,
                          separatorBuilder: (context, index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            height: 1,
                            color: Colors.grey.shade200,
                          ),
                          itemBuilder: (context, index) {
                            final option = options.elementAt(index);
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


  /// 建立選項磁貼
  Widget _buildOptionTile(
    SearchOption option,
    SearchResult searchResult,
    AutocompleteOnSelected<SearchOption> onSelected,
  ) {
    return InkWell(
      onTap: () => onSelected(option),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 主要信息行
            Row(
              children: [
                // 圖標容器
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: option.type == SearchOptionType.station
                          ? [Colors.blue.shade400, Colors.blue.shade600]
                          : [Colors.orange.shade400, Colors.orange.shade600],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    option.icon,
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // 名稱和描述
                Expanded(
                  flex: 3,
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
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      
                      const SizedBox(height: 4),
                      
                      Text(
                        option.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // 類型標籤
                Container(
                  constraints: const BoxConstraints(minWidth: 80),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: option.type == SearchOptionType.station
                          ? [Colors.blue.shade100, Colors.blue.shade200]
                          : [Colors.orange.shade100, Colors.orange.shade200],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: option.type == SearchOptionType.station
                          ? Colors.blue.shade300
                          : Colors.orange.shade300,
                    ),
                  ),
                  child: Text(
                    option.type == SearchOptionType.station ? 'Station' : 'Attraction',
                    style: TextStyle(
                      fontSize: 12,
                      color: option.type == SearchOptionType.station
                          ? Colors.blue.shade800
                          : Colors.orange.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
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
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey.shade100, Colors.grey.shade200],
              ),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.search_off,
              size: 40,
              color: Colors.grey.shade500,
            ),
          ),
          
          const SizedBox(height: 20),
          
          Text(
            'No destinations found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Try searching with different keywords',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 20),
          
          // 建議關鍵字
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              children: [
                Text(
                  'Try these popular destinations:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: ['Munich', 'Florence', 'Castle', 'Gallery'].map((keyword) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        keyword,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}