/// 鐵路 API 響應模型
class RailApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? errorMessage;
  final int? statusCode;
  final String? asyncKey;

  const RailApiResponse({
    required this.success,
    this.data,
    this.message,
    this.errorMessage,
    this.statusCode,
    this.asyncKey,
  });

  /// 創建成功響應
  factory RailApiResponse.success({
    required T data,
    String? message,
    String? asyncKey,
  }) {
    return RailApiResponse<T>(
      success: true,
      data: data,
      message: message,
      asyncKey: asyncKey,
    );
  }

  /// 創建失敗響應
  factory RailApiResponse.failure({
    required String errorMessage,
    int? statusCode,
  }) {
    return RailApiResponse<T>(
      success: false,
      errorMessage: errorMessage,
      statusCode: statusCode,
    );
  }

  @override
  String toString() {
    return 'RailApiResponse(success: $success, message: $message, '
        'errorMessage: $errorMessage, statusCode: $statusCode, asyncKey: $asyncKey)';
  }
}

/// 搜尋響應模型
class SearchResponse {
  final String asyncKey;
  final bool isLoading;

  const SearchResponse({
    required this.asyncKey,
    this.isLoading = false,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(
      asyncKey: json['async'] as String,
      isLoading: json['isLoading'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'SearchResponse(asyncKey: $asyncKey, isLoading: $isLoading)';
  }
}

/// 非同步結果響應模型
class AsyncResultResponse {
  final List<dynamic> solutions;
  final Map<String, dynamic> rawData;

  const AsyncResultResponse({
    required this.solutions,
    required this.rawData,
  });

  factory AsyncResultResponse.fromJson(Map<String, dynamic> json) {
    return AsyncResultResponse(
      solutions: json['solutions'] as List<dynamic>? ?? [],
      rawData: json,
    );
  }

  /// 從 List 直接創建 AsyncResultResponse
  factory AsyncResultResponse.fromList(List<dynamic> solutions) {
    return AsyncResultResponse(
      solutions: solutions,
      rawData: {'solutions': solutions},
    );
  }

  @override
  String toString() {
    return 'AsyncResultResponse(solutions: ${solutions.length} items)';
  }
}

/// 非同步結果處理中異常
class AsyncResultPendingException implements Exception {
  final String message;
  
  const AsyncResultPendingException(this.message);

  @override
  String toString() {
    return 'AsyncResultPendingException: $message';
  }
}

/// 鐵路 API 異常
class RailApiException implements Exception {
  final String message;
  final int? statusCode;
  
  const RailApiException(this.message, [this.statusCode]);

  @override
  String toString() {
    return 'RailApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
  }
}
