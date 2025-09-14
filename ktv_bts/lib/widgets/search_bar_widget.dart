import 'package:flutter/material.dart';

/// 搜索選項類型
enum SearchOptionType { station, attraction }

/// 搜索選項模型（臨時版本）
class SearchOption {
  final String id;
  final String name;
  final SearchOptionType type;
  final String description;
  final String icon;
  final List<String> keywords;
  final String? stationCode;

  const SearchOption({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.icon,
    required this.keywords,
    this.stationCode,
  });
}

/// 搜索組件 - 可輸入的下拉選單，支援多語言關鍵字搜索
class SearchBarWidget extends StatefulWidget {
  final Function(SearchOption?)? onSelectionChanged;
  final String? hintText;

  const SearchBarWidget({
    super.key,
    this.onSelectionChanged,
    this.hintText,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  SearchOption? _selectedOption;
  List<SearchOption> _filteredOptions = [];
  bool _isDropdownVisible = false;

  // 硬編碼的搜索選項（包含多語言關鍵字）
  static const List<SearchOption> _searchOptions = [
    SearchOption(
      id: 'munich_central',
      name: 'Munich Central',
      type: SearchOptionType.station,
      description: 'Munich Central Railway Station',
      icon: '🚉',
      stationCode: 'ST_L6NN3P6K',
      keywords: [
        'Munich', 'München', 'Munich Hbf', 'München Hauptbahnhof',
        'Munich Central', 'Munich Main Station', '慕尼黑', '慕尼黑中央車站'
      ],
    ),
    SearchOption(
      id: 'neuschwanstein_castle',
      name: 'Neuschwanstein Castle',
      type: SearchOptionType.attraction,
      description: 'Fairy-tale Castle in Bavaria',
      icon: '🏰',
      keywords: [
        '新天鵝堡', '新天鹅堡', 'Neuschwanstein', 'Neuschwanstein Castle',
        'Schloss Neuschwanstein', '노이슈반슈타인성', 'Château de Neuschwanstein'
      ],
    ),
    SearchOption(
      id: 'fuessen_station',
      name: 'Füssen Station',
      type: SearchOptionType.station,
      description: 'Füssen Railway Station',
      icon: '🚉',
      stationCode: 'ST_FUESSEN',
      keywords: ['Füssen', 'Fussen', '福森', 'Bahnhof Füssen'],
    ),
    SearchOption(
      id: 'uffizi_gallery',
      name: 'Uffizi Gallery',
      type: SearchOptionType.attraction,
      description: 'World-famous Renaissance art museum in Florence',
      icon: '🎨',
      keywords: [
        '烏菲齊美術館', '烏菲茲美術館', 'Uffizi', 'Uffizi Gallery',
        'Galleria degli Uffizi', 'Galerie des Offices', 'Галерея Уффици'
      ],
    ),
    SearchOption(
      id: 'florence_station',
      name: 'Florence SMN',
      type: SearchOptionType.station,
      description: 'Firenze Santa Maria Novella Railway Station',
      icon: '🚉',
      stationCode: 'ST_DKRRM9Q4',
      keywords: [
        'Florence', 'Firenze', 'Florenz', '佛羅倫斯',
        'Firenze S. M. Novella', 'Firenze SMN', 'Florence SMN',
        'Firenze Centrale', '佛羅倫斯中央車站'
      ],
    ),
    SearchOption(
      id: 'milan_station',
      name: 'Milano Centrale',
      type: SearchOptionType.station,
      description: 'Milan Central Railway Station',
      icon: '🚉',
      stationCode: 'ST_L6NN3P6K',
      keywords: ['Milan', 'Milano', 'Milano Centrale', '米蘭', '米蘭中央車站'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _filteredOptions = _searchOptions;
    
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          _isDropdownVisible = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 多語言關鍵字搜索
  void _filterOptions(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredOptions = _searchOptions;
      } else {
        _filteredOptions = _searchOptions.where((option) {
          // 搜索名稱
          if (option.name.toLowerCase().contains(query.toLowerCase())) {
            return true;
          }
          // 搜索描述
          if (option.description.toLowerCase().contains(query.toLowerCase())) {
            return true;
          }
          // 搜索關鍵字
          return option.keywords.any((keyword) =>
              keyword.toLowerCase().contains(query.toLowerCase()));
        }).toList();
      }
    });
  }

  /// 選擇選項
  void _selectOption(SearchOption option) {
    setState(() {
      _selectedOption = option;
      _controller.text = option.name;
      _isDropdownVisible = false;
    });
    
    _focusNode.unfocus();
    widget.onSelectionChanged?.call(option);
  }

  /// 清除選擇
  void _clearSelection() {
    setState(() {
      _selectedOption = null;
      _controller.clear();
      _filteredOptions = _searchOptions;
      _isDropdownVisible = false;
    });
    
    widget.onSelectionChanged?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 搜索輸入框
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _focusNode.hasFocus ? Colors.blue.shade600 : Colors.grey.shade300,
              width: _focusNode.hasFocus ? 2 : 1,
            ),
          ),
          child: TextFormField(
            controller: _controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: widget.hintText ?? 'Type destination...',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.grey.shade500,
              ),
              suffixIcon: _selectedOption != null
                  ? IconButton(
                      onPressed: _clearSelection,
                      icon: Icon(
                        Icons.clear,
                        color: Colors.grey.shade500,
                      ),
                    )
                  : Icon(
                      Icons.arrow_drop_down,
                      color: Colors.grey.shade500,
                    ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) {
              _filterOptions(value);
              if (!_isDropdownVisible) {
                setState(() {
                  _isDropdownVisible = true;
                });
              }
            },
            onTap: () {
              setState(() {
                _isDropdownVisible = true;
              });
            },
          ),
        ),

        // 下拉選項列表
        if (_isDropdownVisible && _filteredOptions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredOptions.length,
              itemBuilder: (context, index) {
                final option = _filteredOptions[index];
                return _buildOptionItem(option);
              },
            ),
          ),

        // 搜索建議提示
        if (_controller.text.isEmpty && !_focusNode.hasFocus)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildSuggestionChip('🚉 Munich Central'),
                _buildSuggestionChip('🏰 Neuschwanstein Castle'),
                _buildSuggestionChip('🎨 Uffizi Gallery'),
              ],
            ),
          ),
      ],
    );
  }

  /// 建立選項項目
  Widget _buildOptionItem(SearchOption option) {
    return InkWell(
      onTap: () => _selectOption(option),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(
              option.icon,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: option.type == SearchOptionType.station
                    ? Colors.blue.shade100
                    : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                option.type == SearchOptionType.station ? 'Station' : 'Attraction',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: option.type == SearchOptionType.station
                      ? Colors.blue.shade700
                      : Colors.orange.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 建立搜索建議標籤
  Widget _buildSuggestionChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}
