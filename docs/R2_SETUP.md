# Cloudflare R2 Setup Guide

## Prerequisites

- Cloudflare account with R2 access
- Supabase project created
- Supabase CLI installed

## Step 1: Create Cloudflare R2 Bucket

1. Log in to [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Navigate to **R2** in the left sidebar
3. Click **Create bucket**
4. **Bucket name**: `vendora-images`
5. **Location**: Choose closest to your users (or Auto)
6. Click **Create bucket**

## Step 2: Configure CORS for R2 Bucket

1. Select your `vendora-images` bucket
2. Go to **Settings** tab
3. Scroll to **CORS policy**
4. Click **Add CORS policy** and paste:

```json
[
  {
    "AllowedOrigins": ["*"],
    "AllowedMethods": ["GET", "PUT", "POST", "DELETE", "HEAD"],
    "AllowedHeaders": ["*"],
    "ExposeHeaders": ["ETag"],
    "MaxAgeSeconds": 3000
  }
]
```

5. Click **Save**

> **Note**: For production, replace `"*"` in `AllowedOrigins` with your specific domains for better security.

## Step 3: Create R2 API Credentials

1. In Cloudflare Dashboard, go to **R2**
2. Click **Manage R2 API Tokens**
3. Click **Create API Token**
4. **Token name**: `vendora-upload-token`
5. **Permissions**: Select **Object Read & Write**
6. **Bucket**: Select `vendora-images`
7. Click **Create API Token**
8. **Save these credentials** (they won't be shown again):
   - Access Key ID
   - Secret Access Key
   - Account ID (found in R2 Overview)

## Step 4: Set Up Public Domain for R2

1. In R2 bucket settings, find **Public R2.dev subdomain**
2. Click **Allow Access** to enable public access
3. Note the public domain: `https://pub-xxxxx.r2.dev`

**Alternative**: You can set up a custom domain:
1. Go to **Custom Domains**
2. Click **Connect Domain**
3. Enter your domain (e.g., `images.vendora.com`)
4. Follow DNS setup instructions

## Step 5: Configure Supabase Edge Function Secrets

Deploy the Edge Function secrets using Supabase CLI:

```bash
# Navigate to project root
cd "e:\Vendora App\Vendora App"

# Set R2 credentials as Edge Function secrets
supabase secrets set R2_ACCOUNT_ID=your_account_id_here
supabase secrets set R2_ACCESS_KEY_ID=your_access_key_id_here
supabase secrets set R2_SECRET_ACCESS_KEY=your_secret_access_key_here
supabase secrets set R2_BUCKET_NAME=vendora-images
supabase secrets set R2_PUBLIC_DOMAIN=pub-xxxxx.r2.dev
```

Replace the placeholder values with your actual R2 credentials from Step 3.

## Step 6: Deploy Supabase Edge Function

```bash
# Login to Supabase (if not already logged in)
supabase login

# Link to your Supabase project
supabase link --project-ref your-project-ref

# Deploy the generate-upload-url function
supabase functions deploy generate-upload-url
```

## Step 7: Verify Edge Function

Test the Edge Function using curl:

```bash
curl -X POST 'https://your-project-ref.supabase.co/functions/v1/generate-upload-url' \
  -H 'Authorization: Bearer YOUR_SUPABASE_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "bucket": "products",
    "path": "test/image.jpg",
    "contentType": "image/jpeg"
  }'
```

Expected response:
```json
{
  "uploadUrl": "https://account-id.r2.cloudflarestorage.com/...",
  "publicUrl": "https://pub-xxxxx.r2.dev/products/test/image.jpg"
}
```

## Step 8: Update Flutter App Configuration

The app already has the `R2ImageUploadService` implemented. To use it:

1. Initialize Supabase in your app (Task 1.1)
2. Create an instance of the service:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vendora/services/image_upload_service.dart';

final imageUploadService = R2ImageUploadService(
  supabase: Supabase.instance.client,
);
```

3. Use it to upload images:

```dart
import 'dart:io';

final result = await imageUploadService.uploadImage(
  file: File('/path/to/image.jpg'),
  bucket: 'products',
  path: 'seller-123/product-456',
);

result.fold(
  (failure) => print('Upload failed: ${failure.message}'),
  (publicUrl) => print('Image uploaded: $publicUrl'),
);
```

## Troubleshooting

### Error: "Failed to generate upload URL"
- Verify all Edge Function secrets are set correctly
- Check R2 credentials are valid
- Ensure R2 bucket exists

### Error: "Invalid file type"
- Only JPEG, PNG, and WebP are allowed
- Check file extension is correct

### Error: "File too large"
- Maximum file size is 10MB
- Compress image before uploading

### CORS errors when uploading
- Verify CORS policy is correctly set on R2 bucket
- Check AllowedOrigins includes your domain

## Security Notes

- **Never** commit R2 credentials to version control
- Store credentials only in Supabase Edge Function secrets
- Use presigned URLs with expiration (default: 15 minutes)
- Implement rate limiting on Edge Function for production
- Consider adding file name sanitization

## Next Steps

After completing this setup:
1. Test image upload from Flutter app
2. Implement image upload in seller product creation screen
3. Add upload progress indicator
4. Implement image deletion functionality
