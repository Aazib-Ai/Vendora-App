import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/errors/failures.dart';

/// Service for uploading images to Cloudflare R2 via Supabase Edge Functions
/// 
/// Requirements:
/// - 3.1: Upload images to Cloudflare R2 using presigned URLs
/// - 3.2: Store R2 object URLs in database
/// - 3.3: Handle upload failures with retry
/// - 3.6: Validate file type and size
abstract class IImageUploadService {
  /// Upload a single image to R2
  /// 
  /// [file] - The image file to upload
  /// [bucket] - The R2 bucket name (e.g., 'products', 'profiles')
  /// [path] - The path within the bucket (e.g., 'seller-123/product-456')
  /// 
  /// Returns Either<Failure, String> where String is the public URL
  Future<Either<Failure, String>> uploadImage({
    required File file,
    required String bucket,
    required String path,
  });

  /// Upload multiple images to R2
  /// 
  /// [files] - List of image files to upload
  /// [bucket] - The R2 bucket name
  /// [basePath] - The base path within the bucket
  /// 
  /// Returns Either<Failure, List<String>> where List<String> are the public URLs
  Future<Either<Failure, List<String>>> uploadMultipleImages({
    required List<File> files,
    required String bucket,
    required String basePath,
  });

  /// Delete an image from R2
  /// 
  /// [url] - The public URL of the image to delete
  /// 
  /// Returns Either<Failure, void>
  Future<Either<Failure, void>> deleteImage(String url);
}

/// Implementation of IImageUploadService using Cloudflare R2 and Supabase Edge Functions
class R2ImageUploadService implements IImageUploadService {
  final SupabaseClient _supabase;
  final Uuid _uuid = const Uuid();
  
  // Validation constants from Requirements 3.6
  static const List<String> _allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];
  static const int _maxFileSizeBytes = 10 * 1024 * 1024; // 10MB

  R2ImageUploadService({required SupabaseClient supabase})
      : _supabase = supabase;

  @override
  Future<Either<Failure, String>> uploadImage({
    required File file,
    required String bucket,
    required String path,
  }) async {
    try {
      // Step 1: Validate file
      final validationResult = _validateFile(file);
      if (validationResult != null) {
        return Left(validationResult);
      }

      // Step 2: Generate unique filename
      final extension = p.extension(file.path).toLowerCase().replaceFirst('.', '');
      final filename = '${_uuid.v4()}.$extension';
      final fullPath = '$path/$filename';

      // Step 3: Get presigned URL from Edge Function
      final response = await _supabase.functions.invoke(
        'generate-upload-url',
        body: {
          'bucket': bucket,
          'path': fullPath,
          'contentType': 'image/$extension',
        },
      );

      if (response.status != 200) {
        return Left(ServerFailure(
          'Failed to generate upload URL: ${response.data}',
        ));
      }

      final presignedUrl = response.data['uploadUrl'] as String?;
      final publicUrl = response.data['publicUrl'] as String?;

      if (presignedUrl == null || publicUrl == null) {
        return Left(ServerFailure(
          'Invalid response from upload URL generator',
        ));
      }

      // Step 4: Upload file to R2 using presigned URL
      final bytes = await file.readAsBytes();
      final uploadResponse = await http.put(
        Uri.parse(presignedUrl),
        body: bytes,
        headers: {
          'Content-Type': 'image/$extension',
          'Content-Length': bytes.length.toString(),
        },
      );

      if (uploadResponse.statusCode != 200 && uploadResponse.statusCode != 201) {
        return Left(ServerFailure(
          'Failed to upload image: ${uploadResponse.statusCode} ${uploadResponse.reasonPhrase}',
        ));
      }

      // Step 5: Return public URL
      return Right(publicUrl);
    } on SocketException catch (e) {
      return Left(NetworkFailure('Network error during upload: ${e.message}'));
    } on FileSystemException catch (e) {
      return Left(FileFailure('File system error: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Unexpected error during upload: $e'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> uploadMultipleImages({
    required List<File> files,
    required String bucket,
    required String basePath,
  }) async {
    final List<String> uploadedUrls = [];

    for (final file in files) {
      final result = await uploadImage(
        file: file,
        bucket: bucket,
        path: basePath,
      );

      // If any upload fails, return the failure
      if (result.isLeft()) {
        return result.fold(
          (failure) => Left(failure),
          (_) => throw StateError('Unexpected state'),
        );
      }

      // Add the uploaded URL to the list
      result.fold(
        (_) {},
        (url) => uploadedUrls.add(url),
      );
    }

    return Right(uploadedUrls);
  }

  @override
  Future<Either<Failure, void>> deleteImage(String url) async {
    try {
      // Extract object key from public URL
      // Example URL: https://pub-xxxxx.r2.dev/products/seller-123/uuid.jpg
      final uri = Uri.parse(url);
      final objectKey = uri.path.replaceFirst('/', '');

      // Call delete Edge Function (to be implemented)
      final response = await _supabase.functions.invoke(
        'delete-image',
        body: {'objectKey': objectKey},
      );

      if (response.status != 200) {
        return Left(ServerFailure(
          'Failed to delete image: ${response.data}',
        ));
      }

      return const Right(null);
    } on SocketException catch (e) {
      return Left(NetworkFailure('Network error during delete: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure('Unexpected error during delete: $e'));
    }
  }

  /// Validates file type and size according to Requirements 3.6
  /// 
  /// Returns null if valid, or a Failure if invalid
  Failure? _validateFile(File file) {
    // Check if file exists
    if (!file.existsSync()) {
      return const FileFailure('File does not exist');
    }

    // Validate file extension
    final extension = p.extension(file.path).toLowerCase().replaceFirst('.', '');
    if (!_allowedExtensions.contains(extension)) {
      return ValidationFailure(
        'Invalid file type. Allowed types: ${_allowedExtensions.join(', ')}',
      );
    }

    // Validate file size
    final fileSize = file.lengthSync();
    if (fileSize > _maxFileSizeBytes) {
      final maxSizeMB = (_maxFileSizeBytes / (1024 * 1024)).toStringAsFixed(1);
      final actualSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);
      return ValidationFailure(
        'File too large. Max: ${maxSizeMB}MB, Actual: ${actualSizeMB}MB',
      );
    }

    return null; // File is valid
  }
}

/// Mock implementation for testing without actual R2 connection
class MockImageUploadService implements IImageUploadService {
  @override
  Future<Either<Failure, String>> uploadImage({
    required File file,
    required String bucket,
    required String path,
  }) async {
    // Simulate upload delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Return mock URL
    return Right('https://mock-r2.dev/$bucket/$path/${p.basename(file.path)}');
  }

  @override
  Future<Either<Failure, List<String>>> uploadMultipleImages({
    required List<File> files,
    required String bucket,
    required String basePath,
  }) async {
    final urls = <String>[];
    for (final file in files) {
      final result = await uploadImage(
        file: file,
        bucket: bucket,
        path: basePath,
      );
      result.fold(
        (failure) => throw Exception(failure.message),
        (url) => urls.add(url),
      );
    }
    return Right(urls);
  }

  @override
  Future<Either<Failure, void>> deleteImage(String url) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return const Right(null);
  }
}
