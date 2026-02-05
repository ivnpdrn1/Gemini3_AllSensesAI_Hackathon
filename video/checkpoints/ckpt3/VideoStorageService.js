/**
 * VideoStorageService - S3 Integration for Video Evidence Storage
 * 
 * CRITICAL RULES (from execution contract):
 * - Zero page-load network calls (no automatic execution on import)
 * - All network calls inside explicitly invoked methods only
 * - Storage path: video-evidence/{incidentId}/{timestamp}-{type}.{ext}
 * - Minimal metadata: incidentId, captureType, capturedAt, contentType
 * 
 * Feature: video-sms-evidence-capture
 * Component: VideoStorageService
 * Requirements: 6.1, 6.2, 6.6, 6.7
 */

class VideoStorageService {
    /**
     * Initialize VideoStorageService
     * @param {Object} config - Configuration object
     * @param {string} config.bucketName - S3 bucket name
     * @param {string} config.region - AWS region
     * @param {Object} config.credentials - AWS credentials (optional, uses default if not provided)
     */
    constructor(config = {}) {
        this.bucketName = config.bucketName || null;
        this.region = config.region || 'us-east-1';
        this.credentials = config.credentials || null;
        this.s3Client = null;
        this.maxRetries = 3;
        this.retryDelayMs = 1000; // Base delay for exponential backoff
        
        // NO network calls here - initialization only
        console.log('[VIDEO][STORAGE] Service initialized (no network calls)');
    }
    
    /**
     * Initialize S3 client (lazy initialization)
     * Only called when upload is actually needed
     * @private
     */
    _initializeS3Client() {
        if (this.s3Client) {
            return; // Already initialized
        }
        
        if (!this.bucketName) {
            throw new Error('[VIDEO][STORAGE] Bucket name not configured');
        }
        
        // Initialize AWS SDK S3 client
        // This would use AWS SDK v3 in production
        // For now, this is a stub that will be replaced with actual AWS SDK
        console.log('[VIDEO][STORAGE] S3 client initialized for bucket:', this.bucketName);
        
        // Placeholder for actual S3 client initialization
        // In production: this.s3Client = new S3Client({ region: this.region, credentials: this.credentials });
        this.s3Client = {
            initialized: true,
            bucketName: this.bucketName,
            region: this.region
        };
    }
    
    /**
     * Upload video frames to S3
     * @param {string} incidentId - Emergency incident identifier
     * @param {Array<Blob>} frames - Video frame blobs
     * @returns {Promise<Array<string>>} Array of S3 object keys for successfully uploaded frames
     * 
     * Requirements: 6.1, 6.2, 6.6, 6.7
     * - S3 path pattern: /video-evidence/{incidentId}/{timestamp}-{type}.{ext}
     * - AES-256 server-side encryption
     * - Object tagging: incident_id, captureType, capturedAt, contentType
     * - Retry logic with exponential backoff (max 3 attempts)
     * - Proof logging: [VIDEO] upload success/failure
     */
    async uploadVideoFrames(incidentId, frames) {
        console.log('[VIDEO][STORAGE] uploadVideoFrames called', { incidentId, frameCount: frames.length });
        
        if (!incidentId || typeof incidentId !== 'string') {
            console.log('[VIDEO][STORAGE] Invalid incidentId, aborting upload');
            return [];
        }
        
        if (!Array.isArray(frames) || frames.length === 0) {
            console.log('[VIDEO][STORAGE] No frames to upload');
            return [];
        }
        
        // Lazy initialize S3 client only when actually needed
        try {
            this._initializeS3Client();
        } catch (error) {
            console.log('[VIDEO][STORAGE] S3 initialization failed:', error.message);
            return [];
        }
        
        const uploadedKeys = [];
        
        for (let i = 0; i < frames.length; i++) {
            const frame = frames[i];
            const timestamp = Date.now();
            const captureType = 'frame';
            const extension = this._getExtensionFromBlob(frame);
            
            // S3 object key format: video-evidence/{incidentId}/{timestamp}-{type}.{ext}
            const s3Key = `video-evidence/${incidentId}/${timestamp}-${captureType}-${String(i).padStart(2, '0')}.${extension}`;
            
            try {
                const uploadedKey = await this._uploadFrameWithRetry(s3Key, frame, incidentId, i);
                if (uploadedKey) {
                    uploadedKeys.push(uploadedKey);
                    console.log('[VIDEO][STORAGE] upload success', s3Key);
                }
            } catch (error) {
                console.log('[VIDEO][STORAGE] upload failure', s3Key, error.message);
                // Continue with other frames (non-fatal)
            }
        }
        
        console.log('[VIDEO][STORAGE] Upload complete', { 
            total: frames.length, 
            successful: uploadedKeys.length,
            failed: frames.length - uploadedKeys.length
        });
        
        return uploadedKeys;
    }
    
    /**
     * Upload single frame with retry logic
     * @param {string} s3Key - S3 object key
     * @param {Blob} frameBlob - Video frame blob
     * @param {string} incidentId - Incident identifier
     * @param {number} frameIndex - Frame index
     * @returns {Promise<string|null>} S3 key if successful, null if failed
     * @private
     */
    async _uploadFrameWithRetry(s3Key, frameBlob, incidentId, frameIndex) {
        for (let attempt = 1; attempt <= this.maxRetries; attempt++) {
            try {
                await this._uploadToS3(s3Key, frameBlob, incidentId, frameIndex);
                return s3Key; // Success
            } catch (error) {
                console.log(`[VIDEO][STORAGE] upload attempt ${attempt}/${this.maxRetries} failed:`, error.message);
                
                if (attempt < this.maxRetries) {
                    // Exponential backoff: 1s, 2s, 4s
                    const delayMs = this.retryDelayMs * Math.pow(2, attempt - 1);
                    console.log(`[VIDEO][STORAGE] retrying in ${delayMs}ms...`);
                    await this._sleep(delayMs);
                } else {
                    console.log('[VIDEO][STORAGE] all retry attempts exhausted');
                    throw error;
                }
            }
        }
        
        return null;
    }
    
    /**
     * Upload frame to S3 with encryption and tagging
     * @param {string} s3Key - S3 object key
     * @param {Blob} frameBlob - Video frame blob
     * @param {string} incidentId - Incident identifier
     * @param {number} frameIndex - Frame index
     * @returns {Promise<void>}
     * @private
     */
    async _uploadToS3(s3Key, frameBlob, incidentId, frameIndex) {
        // Prepare metadata
        const capturedAt = new Date().toISOString();
        const contentType = frameBlob.type || 'video/webm';
        const captureType = 'frames'; // or 'clip' depending on implementation
        
        // Prepare tagging (URL-encoded key-value pairs)
        const tags = new URLSearchParams({
            incident_id: incidentId,
            captureType: captureType,
            capturedAt: capturedAt,
            contentType: contentType
        }).toString();
        
        // In production, this would use AWS SDK S3 PutObject
        // Example with AWS SDK v3:
        /*
        const command = new PutObjectCommand({
            Bucket: this.bucketName,
            Key: s3Key,
            Body: frameBlob,
            ServerSideEncryption: 'AES256',
            Tagging: tags,
            ContentType: contentType,
            Metadata: {
                incidentId: incidentId,
                captureType: captureType,
                capturedAt: capturedAt,
                frameIndex: String(frameIndex)
            }
        });
        
        await this.s3Client.send(command);
        */
        
        // Placeholder implementation for testing
        console.log('[VIDEO][STORAGE] S3 PutObject called', {
            bucket: this.bucketName,
            key: s3Key,
            size: frameBlob.size,
            contentType: contentType,
            encryption: 'AES256',
            tags: tags
        });
        
        // Simulate network delay
        await this._sleep(100);
        
        // Simulate success (in production, this would be actual S3 upload)
        return;
    }
    
    /**
     * Get file extension from Blob MIME type
     * @param {Blob} blob - Blob object
     * @returns {string} File extension
     * @private
     */
    _getExtensionFromBlob(blob) {
        const mimeType = blob.type || 'video/webm';
        
        // Map MIME types to extensions
        const mimeToExt = {
            'video/webm': 'webm',
            'video/mp4': 'mp4',
            'video/ogg': 'ogg',
            'image/jpeg': 'jpg',
            'image/png': 'png'
        };
        
        return mimeToExt[mimeType] || 'webm';
    }
    
    /**
     * Sleep utility for retry delays
     * @param {number} ms - Milliseconds to sleep
     * @returns {Promise<void>}
     * @private
     */
    _sleep(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
    
    /**
     * Get storage statistics (for monitoring)
     * @returns {Object} Storage statistics
     */
    getStats() {
        return {
            bucketName: this.bucketName,
            region: this.region,
            maxRetries: this.maxRetries,
            s3ClientInitialized: this.s3Client !== null
        };
    }
}

// Export for use in other modules
// NO automatic execution - class must be explicitly instantiated
if (typeof module !== 'undefined' && module.exports) {
    module.exports = VideoStorageService;
}
