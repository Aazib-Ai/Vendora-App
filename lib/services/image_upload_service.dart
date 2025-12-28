import 'dart:io';
import 'dart:typed_data'; // Added for Uint8List
import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:minio/minio.dart';
import 'package:minio/models.dart'; // For MinioError if separate or standard exceptions
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  final Minio _minio;
  final String _bucketName;
  final String _publicUrl;
  final Uuid _uuid = const Uuid();
  
  // Validation constants from Requirements 3.6
  static const List<String> _allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];
  static const int _maxFileSizeBytes = 10 * 1024 * 1024; // 10MB

  R2ImageUploadService()
      : _minio = Minio(
          endPoint: '${dotenv.env['R2_ACCOUNT_ID'] ?? "missing-account-id"}.r2.cloudflarestorage.com',
          accessKey: dotenv.env['R2_ACCESS_KEY_ID'] ?? '',
          secretKey: dotenv.env['R2_SECRET_ACCESS_KEY'] ?? '',
          region: 'auto',
          useSSL: true,
        ),
        _bucketName = dotenv.env['R2_BUCKET_NAME'] ?? '',
        _publicUrl = dotenv.env['R2_PUBLIC_URL'] ?? '';

  @override
  Future<Either<Failure, String>> uploadImage({
    required File file,
    required String bucket, // Argument 'bucket' is kept to satisfy interface, but we might prefer env bucket
    required String path,
  }) async {
    try {
      // Step 0: Check configuration
      if (dotenv.env['R2_ACCESS_KEY_ID'] == null ||
          dotenv.env['R2_SECRET_ACCESS_KEY'] == null ||
          dotenv.env['R2_ACCOUNT_ID'] == null) {
        return Left(const ServerFailure('R2 credentials not found in .env'));
      }

      // Step 1: Validate file
      final validationResult = _validateFile(file);
      if (validationResult != null) {
        return Left(validationResult);
      }

      // Step 2: Generate unique filename
      final extension = p.extension(file.path).toLowerCase().replaceFirst('.', '');
      final filename = '${_uuid.v4()}.$extension';
      final fullPath = '$path/$filename';
      // Normalize path to remove leading slashes if any, Minio handles buckets separate from keys
      final objectKey = fullPath.startsWith('/') ? fullPath.substring(1) : fullPath;
      
      // Use the bucket from env if available as primary, otherwise use the passed one (or fallback)
      final actualBucket = _bucketName.isNotEmpty ? _bucketName : bucket;

      // Step 3: Upload file to R2
      final Stream<Uint8List> stream = file.openRead().map((chunk) => Uint8List.fromList(chunk));
      final length = await file.length();

      // Attempting upload
      await _minio.putObject(
        actualBucket,
        objectKey,
        stream,
        size: length,
        metadata: {
          'content-type': 'image/$extension',
        }
      );

      // Step 4: Construct Public URL
      // If R2_PUBLIC_URL is set (e.g. pub-xxxx.r2.dev or custom domain), use it.
      // properties: $publicUrl/$objectKey
      String finalUrl;
      if (_publicUrl.isNotEmpty) {
        // Remove trailing slash from public url if present
        final cleanPublicUrl = _publicUrl.endsWith('/') 
            ? _publicUrl.substring(0, _publicUrl.length - 1) 
            : _publicUrl;
        finalUrl = '$cleanPublicUrl/$objectKey';
      } else {
        // Fallback or error? For MVP we need the public URL.
        return Left(const ServerFailure('R2_PUBLIC_URL not set in .env'));
      }

      return Right(finalUrl);

    } on MinioError catch (e) {
      return Left(ServerFailure('R2 Error: ${e.message}'));
    } on SocketException catch (e) {
      return Left(NetworkFailure('Network error during upload: ${e.message}'));
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
       // Check configuration
      if (dotenv.env['R2_ACCESS_KEY_ID'] == null ||
          dotenv.env['R2_SECRET_ACCESS_KEY'] == null ||
          dotenv.env['R2_ACCOUNT_ID'] == null) {
        return Left(const ServerFailure('R2 credentials not found in .env'));
      }
      
      // Extract object key from public URL
      // URL: https://<domain>/<key>
      // We assume _publicUrl is the prefix.
      
      String objectKey = url;
      if (_publicUrl.isNotEmpty) {
         final cleanPublicUrl = _publicUrl.endsWith('/') 
            ? _publicUrl.substring(0, _publicUrl.length - 1) 
            : _publicUrl;
         if (url.startsWith(cleanPublicUrl)) {
           objectKey = url.replaceFirst('$cleanPublicUrl/', '');
         }
      } else {
        // Try to parse basic URL structure if public URL var is missing (fallback)
        final uri = Uri.parse(url);
        // Path usually includes the leading /
        objectKey = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
      }

      final actualBucket = _bucketName.isNotEmpty ? _bucketName : ''; 
      if (actualBucket.isEmpty) {
         return Left(const ServerFailure('R2_BUCKET_NAME not set for deletion context'));
      }

      await _minio.removeObject(actualBucket, objectKey);
      
      return const Right(null);
    } on MinioError catch (e) {
       return Left(ServerFailure('R2 Delete Error: ${e.toString()}'));
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
