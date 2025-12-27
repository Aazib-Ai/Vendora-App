import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { S3Client, PutObjectCommand } from 'https://deno.land/x/s3_lite_client@0.5.0/mod.ts'

/**
 * Supabase Edge Function: generate-upload-url
 * 
 * Purpose: Generate presigned upload URLs for Cloudflare R2
 * 
 * Requirements:
 * - 3.1: Generate presigned URLs for R2 uploads
 * - 3.2: Return public URL for accessing uploaded images
 * 
 * Environment Variables (set in Supabase dashboard):
 * - R2_ACCOUNT_ID: Cloudflare account ID
 * - R2_ACCESS_KEY_ID: R2 API access key
 * - R2_SECRET_ACCESS_KEY: R2 API secret key
 * - R2_BUCKET_NAME: R2 bucket name
 * - R2_PUBLIC_DOMAIN: Public URL domain for R2 bucket
 */

interface RequestBody {
    bucket: string
    path: string
    contentType: string
}

interface ResponseBody {
    uploadUrl: string
    publicUrl: string
}

serve(async (req) => {
    try {
        // Only allow POST requests
        if (req.method !== 'POST') {
            return new Response(
                JSON.stringify({ error: 'Method not allowed' }),
                { status: 405, headers: { 'Content-Type': 'application/json' } }
            )
        }

        // Verify authentication
        const authHeader = req.headers.get('Authorization')
        if (!authHeader) {
            return new Response(
                JSON.stringify({ error: 'Missing authorization header' }),
                { status: 401, headers: { 'Content-Type': 'application/json' } }
            )
        }

        // Parse request body
        const { bucket, path, contentType } = await req.json() as RequestBody

        if (!bucket || !path || !contentType) {
            return new Response(
                JSON.stringify({ error: 'Missing required fields: bucket, path, contentType' }),
                { status: 400, headers: { 'Content-Type': 'application/json' } }
            )
        }

        // Validate content type
        const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
        if (!allowedTypes.includes(contentType)) {
            return new Response(
                JSON.stringify({ error: `Invalid content type. Allowed: ${allowedTypes.join(', ')}` }),
                { status: 400, headers: { 'Content-Type': 'application/json' } }
            )
        }

        // Get R2 credentials from environment
        const accountId = Deno.env.get('R2_ACCOUNT_ID')
        const accessKeyId = Deno.env.get('R2_ACCESS_KEY_ID')
        const secretAccessKey = Deno.env.get('R2_SECRET_ACCESS_KEY')
        const bucketName = Deno.env.get('R2_BUCKET_NAME')
        const publicDomain = Deno.env.get('R2_PUBLIC_DOMAIN')

        if (!accountId || !accessKeyId || !secretAccessKey || !bucketName || !publicDomain) {
            console.error('Missing R2 environment variables')
            return new Response(
                JSON.stringify({ error: 'Server configuration error' }),
                { status: 500, headers: { 'Content-Type': 'application/json' } }
            )
        }

        // Create S3 client for R2
        const s3Client = new S3Client({
            endPoint: `${accountId}.r2.cloudflarestorage.com`,
            port: 443,
            useSSL: true,
            region: 'auto',
            accessKey: accessKeyId,
            secretKey: secretAccessKey,
            bucket: bucketName,
            pathStyle: false,
        })

        // Generate presigned URL (15 minutes expiry)
        const objectKey = `${bucket}/${path}`
        const expiresIn = 15 * 60 // 15 minutes in seconds

        const presignedUrl = await s3Client.presignedPutObject(
            bucketName,
            objectKey,
            expiresIn,
            {
                'Content-Type': contentType,
            }
        )

        // Construct public URL
        const publicUrl = `https://${publicDomain}/${objectKey}`

        const response: ResponseBody = {
            uploadUrl: presignedUrl,
            publicUrl: publicUrl,
        }

        return new Response(
            JSON.stringify(response),
            {
                status: 200,
                headers: { 'Content-Type': 'application/json' },
            }
        )
    } catch (error) {
        console.error('Error generating upload URL:', error)
        return new Response(
            JSON.stringify({ error: 'Failed to generate upload URL', details: error.message }),
            { status: 500, headers: { 'Content-Type': 'application/json' } }
        )
    }
})
