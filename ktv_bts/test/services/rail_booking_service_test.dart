import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ktv_bts/services/rail_booking_service.dart';
import 'package:ktv_bts/models/rail_search_criteria.dart';
import 'package:ktv_bts/models/rail_api_response.dart';

import 'rail_booking_service_test.mocks.dart';

@GenerateMocks([http.Client, http.Response])
void main() {
  group('RailBookingService', () {
    late MockClient mockClient;
    late RailBookingService service;

    setUp(() {
      mockClient = MockClient();
      service = RailBookingService(
        httpClient: mockClient,
        baseUrl: 'http://test-api.g2rail.com',
        apiKey: 'test-api-key',
        secret: 'test-secret',
      );
    });

    tearDown(() {
      service.dispose();
    });

    group('searchTrains', () {
      test('should return async key on successful search', () async {
        // Arrange
        final criteria = RailSearchCriteria(
          from: 'Frankfurt',
          to: 'Berlin',
          date: '2024-01-15',
          time: '08:00',
          adult: 1,
        );

        final mockResponse = MockResponse();
        when(mockResponse.statusCode).thenReturn(200);
        when(mockResponse.bodyBytes).thenReturn(
          '{"async": "test-async-key-123"}'.codeUnits,
        );

        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await service.searchTrains(criteria);

        // Assert
        expect(result.success, isTrue);
        expect(result.asyncKey, equals('test-async-key-123'));
        expect(result.data?.asyncKey, equals('test-async-key-123'));
      });

      test('should return error on API failure', () async {
        // Arrange
        final criteria = RailSearchCriteria(
          from: 'Frankfurt',
          to: 'Berlin',
          date: '2024-01-15',
          time: '08:00',
          adult: 1,
        );

        final mockResponse = MockResponse();
        when(mockResponse.statusCode).thenReturn(401);
        when(mockResponse.body).thenReturn('Unauthorized');

        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await service.searchTrains(criteria);

        // Assert
        expect(result.success, isFalse);
        expect(result.errorMessage, contains('401'));
        expect(result.statusCode, equals(401));
      });
    });

    group('getAsyncResult', () {
      test('should return results on successful fetch', () async {
        // Arrange
        const asyncKey = 'test-async-key-123';
        final mockResponse = MockResponse();
        when(mockResponse.statusCode).thenReturn(200);
        when(mockResponse.bodyBytes).thenReturn(
          '{"solutions": [{"id": "sol1", "price": 89.50}]}'.codeUnits,
        );

        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await service.getAsyncResult(asyncKey);

        // Assert
        expect(result.success, isTrue);
        expect(result.data?.solutions, isNotEmpty);
      });

      test('should retry when status is 202', () async {
        // Arrange
        const asyncKey = 'test-async-key-123';
        
        // First response: 202 (processing)
        final mockResponse202 = MockResponse();
        when(mockResponse202.statusCode).thenReturn(202);
        when(mockResponse202.body).thenReturn('Processing');

        // Second response: 200 (success)
        final mockResponse200 = MockResponse();
        when(mockResponse200.statusCode).thenReturn(200);
        when(mockResponse200.bodyBytes).thenReturn(
          '{"solutions": [{"id": "sol1", "price": 89.50}]}'.codeUnits,
        );

        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => mockResponse202)
            .thenAnswer((_) async => mockResponse200);

        // Act
        final result = await service.getAsyncResult(
          asyncKey,
          maxRetries: 2,
          retryDelay: const Duration(milliseconds: 100),
        );

        // Assert
        expect(result.success, isTrue);
        verify(mockClient.get(any, headers: anyNamed('headers'))).called(2);
      });

      test('should throw AsyncResultPendingException when max retries exceeded', () async {
        // Arrange
        const asyncKey = 'test-async-key-123';
        final mockResponse = MockResponse();
        when(mockResponse.statusCode).thenReturn(202);
        when(mockResponse.body).thenReturn('Processing');

        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await service.getAsyncResult(
          asyncKey,
          maxRetries: 1,
          retryDelay: const Duration(milliseconds: 50),
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.errorMessage, contains('處理超時'));
      });
    });

    group('searchAndGetResults', () {
      test('should complete full search flow successfully', () async {
        // Arrange
        final criteria = RailSearchCriteria(
          from: 'Frankfurt',
          to: 'Berlin',
          date: '2024-01-15',
          time: '08:00',
          adult: 1,
        );

        // Mock search response
        final mockSearchResponse = MockResponse();
        when(mockSearchResponse.statusCode).thenReturn(200);
        when(mockSearchResponse.bodyBytes).thenReturn(
          '{"async": "test-async-key-123"}'.codeUnits,
        );

        // Mock async result response
        final mockResultResponse = MockResponse();
        when(mockResultResponse.statusCode).thenReturn(200);
        when(mockResultResponse.bodyBytes).thenReturn(
          '{"solutions": [{"id": "sol1", "price": 89.50}]}'.codeUnits,
        );

        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => mockSearchResponse)
            .thenAnswer((_) async => mockResultResponse);

        // Act
        final result = await service.searchAndGetResults(criteria);

        // Assert
        expect(result.success, isTrue);
        expect(result.data?.solutions, isNotEmpty);
        verify(mockClient.get(any, headers: anyNamed('headers'))).called(2);
      });
    });
  });
}
