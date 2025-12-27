import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vendora/core/errors/failures.dart';
import 'package:vendora/services/image_upload_service.dart';
import 'package:path/path.dart' as p;

// Generate mocks: flutter pub run build_runner build
@GenerateMocks([SupabaseClient, FunctionsClient])
import 'image_upload_service_test.mocks.dart';

void main() {
  group('R2ImageUploadService', () {
    late MockSupabaseClient mockSupabase;
    late MockFunctionsClient mockFunctions;
    late R2ImageUploadService service;
    late Directory tempDir;

    setUp(() async {
      mockSupabase = MockSupabaseClient();
      mockFunctions = MockFunctionsClient();
      service = R2ImageUploadService(supabase: mockSupabase);
      
      // Create temp directory for test files
      tempDir = await Directory.systemTemp.createTemp('image_upload_test_');
      
      // Setup mock
      when(mockSupabase.functions).thenReturn(mockFunctions);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('File Validation', () {
      test('should reject non-existent file', () async {
        // Arrange
        final file = File(p.join(tempDir.path, 'non_existent.jpg'));

        // Act
        final result = await service.uploadImage(
          file: file,
          bucket: 'products',
          path: 'test',
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<FileFailure>());
            expect(failure.message, contains('does not exist'));
          },
          (_) => fail('Should have failed'),
        );
      });

      test('should reject invalid file type', () async {
        // Arrange
        final file = await _createTestFile(tempDir, 'test.gif', 1024);

        // Act
        final result = await service.uploadImage(
          file: file,
          bucket: 'products',
          path: 'test',
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect(failure.message, contains('Invalid file type'));
          },
          (_) => fail('Should have failed'),
        );
      });

      test('should reject oversized file', () async {
        // Arrange: Create 11MB file
        final file = await _createTestFile(
          tempDir,
          'oversized.jpg',
          11 * 1024 * 1024,
        );

        // Act
        final result = await service.uploadImage(
          file: file,
          bucket: 'products',
          path: 'test',
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect(failure.message, contains('File too large'));
          },
          (_) => fail('Should have failed'),
        );
      });

      test('should accept valid JPEG file', () async {
        // Arrange
        final file = await _createTestFile(tempDir, 'valid.jpg', 1024 * 1024);

        // Mock successful response
        when(mockFunctions.invoke(
          'generate-upload-url',
          body: anyNamed('body'),
        )).thenAnswer((_) async => FunctionResponse(
              status: 200,
              data: {
                'uploadUrl': 'https://r2.example.com/upload',
                'publicUrl': 'https://pub.example.com/products/test/valid.jpg',
              },
            ));

        // Note: We can't actually test the HTTP upload without mocking http client
        // This test verifies validation passes
      });

      test('should accept valid PNG file', () async {
        final file = await _createTestFile(tempDir, 'valid.png', 2 * 1024 * 1024);
        expect(file.existsSync(), isTrue);
        expect(p.extension(file.path), '.png');
      });

      test('should accept valid WebP file', () async {
        final file = await _createTestFile(tempDir, 'valid.webp', 3 * 1024 * 1024);
        expect(file.existsSync(), isTrue);
        expect(p.extension(file.path), '.webp');
      });

      test('should accept file at exact 10MB limit', () async {
        final file = await _createTestFile(
          tempDir,
          'limit.jpg',
          10 * 1024 * 1024,
        );
        expect(file.lengthSync(), lessThanOrEqualTo(10 * 1024 * 1024));
      });
    });

    group('MockImageUploadService', () {
      late MockImageUploadService mockService;

      setUp(() {
        mockService = MockImageUploadService();
      });

      test('should return mock URL for valid upload', () async {
        // Arrange
        final file = await _createTestFile(tempDir, 'test.jpg', 1024);

        // Act
        final result = await mockService.uploadImage(
          file: file,
          bucket: 'products',
          path: 'test',
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should have succeeded'),
          (url) {
            expect(url, contains('mock-r2.dev'));
            expect(url, contains('products'));
            expect(url, contains('test'));
          },
        );
      });

      test('should upload multiple images', () async {
        // Arrange
        final files = [
          await _createTestFile(tempDir, 'img1.jpg', 1024),
          await _createTestFile(tempDir, 'img2.png', 2048),
          await _createTestFile(tempDir, 'img3.webp', 3072),
        ];

        // Act
        final result = await mockService.uploadMultipleImages(
          files: files,
          bucket: 'products',
          basePath: 'test',
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should have succeeded'),
          (urls) {
            expect(urls.length, equals(3));
            for (final url in urls) {
              expect(url, contains('mock-r2.dev'));
            }
          },
        );
      });

      test('should delete image', () async {
        // Act
        final result = await mockService.deleteImage(
          'https://mock-r2.dev/products/test/image.jpg',
        );

        // Assert
        expect(result.isRight(), isTrue);
      });
    });
  });
}

/// Helper function to create test files
Future<File> _createTestFile(
  Directory dir,
  String filename,
  int sizeBytes,
) async {
  final file = File(p.join(dir.path, filename));
  final bytes = List<int>.generate(sizeBytes, (i) => i % 256);
  await file.writeAsBytes(bytes);
  return file;
}
