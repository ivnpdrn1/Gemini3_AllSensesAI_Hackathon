/**
 * SignedURLGenerator - Generate time-limited access URLs for video evidence
 * 
 * CRITICAL RULES (from execution contract):
 * - Zero page-load network calls (no automatic execution on import)
 * - All network calls inside explicitly invoked methods only
 * - Presigned URL expiry: 20 minutes (configurable 15-30 min)
 * - Read-only permissions (GetObject only)
 * 
 * Feature: video-sms-evidence-capture
 * Component: SignedURLGenerator
 * Requirements: 7.1
 */

class SignedURLGenerator {
    /**
     * Initialize SignedURLGenerator
     * @param {Object} config - Configuration object
     * @param {string} config.bucketName - S3 bucket name
     * @param {string} config.region - AWS region
     * @param {number} config.expirationMinutes - URL expiration in minutes (default: 20)
     * @param {Object} config.credentials - AWS credentials (optional)
     */
    constructor(config = {}) {
        this.bucketName = config.bucketName || null;
        this.region = config.region || 'us-east-1';
        this.expirationMinutes = config.expirationMinutes || 20; // Default 20 minutes
        this.credentials = config.credentials || null;
        this.s3Client = null;
        
        // Validate expiration range (15-30 minutes)
        if (this.expirationMinutes < 15 || this.expirationMinutes > 30) {
            console.warn('[VIDEO][URL] Expiration outside recommended range (15-30 min), using:', this.expirationMinutes);
        }
        
        // NO network calls here - initialization only
        console.log('[VIDEO][URL] Generator initialized (no network calls)');
    }
    
    /**
     * Initialize S3 client (lazy initialization)
     * Only called when URL generation is actually needed
     * @private
     */
    _initializeS3Client() {
        if (this.s3Client) {
            return; // Already initialized
        }
        
        if (!this.bucketName) {
            throw new Error('[VIDEO][URL] Bucket name not configured');
        }
        
        console.log('[VIDEO][URL] S3 client initialized for bucket:', this.bucketName);
        
        // Placeholder for actual S3 client initialization
        // In production: this.s3Client = new S3Client({ region: this.region, credentials: this.credentials });
        this.s3Client = {
            initialized: true,
            bucketName: this.bucketName,
            region: this.region
        };
    }
    
    /**
     * Generate signed URL(s) for video evidence
     * @param {Array<string>} s3Keys - S3 object keys for video frames
     * @returns {Promise<string|null>} Signed URL or evidence viewer URL, null if no keys
     * 
     * Requirements: 7.1
     * - Single frame: Direct presigned URL
     * - Multiple frames: Evidence viewer URL with embedded signed URLs
     * - Expiration: 20 minutes (configurable)
     * - Read-only permissions: GetObject only
     */
    async generateVideoEvidenceURL(s3Keys) {
        console.log('[VIDEO][URL] generateVideoEvidenceURL called', { keyCount: s3Keys?.length || 0 });
        
        if (!Array.isArray(s3Keys) || s3Keys.length === 0) {
            console.log('[VIDEO][URL] No S3 keys provided, returning null');
            return null;
        }
        
        // Lazy initialize S3 client only when actually needed
        try {
            this._initializeS3Client();
        } catch (error) {
            console.log('[VIDEO][URL] S3 initialization failed:', error.message);
            return null;
        }
        
        try {
            // Single frame: Direct signed URL
            if (s3Keys.length === 1) {
                console.log('[VIDEO][URL] Generating direct presigned URL for single frame');
                return await this._generatePresignedURL(s3Keys[0]);
            }
            
            // Multiple frames: Evidence viewer URL
            console.log('[VIDEO][URL] Generating evidence viewer URL for multiple frames');
            return await this._generateEvidenceViewerURL(s3Keys);
            
        } catch (error) {
            console.log('[VIDEO][URL] URL generation failed:', error.message);
            return null;
        }
    }
    
    /**
     * Generate presigned URL for single S3 object
     * @param {string} s3Key - S3 object key
     * @returns {Promise<string>} Presigned URL
     * @private
     */
    async _generatePresignedURL(s3Key) {
        const expirationSeconds = this.expirationMinutes * 60;
        
        // In production, this would use AWS SDK S3 getSignedUrl
        // Example with AWS SDK v3:
        /*
        const command = new GetObjectCommand({
            Bucket: this.bucketName,
            Key: s3Key
        });
        
        const url = await getSignedUrl(this.s3Client, command, {
            expiresIn: expirationSeconds
        });
        
        return url;
        */
        
        // Placeholder implementation for testing
        const mockUrl = `https://s3.${this.region}.amazonaws.com/${this.bucketName}/${s3Key}?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Expires=${expirationSeconds}&X-Amz-Signature=MOCK_SIGNATURE`;
        
        console.log('[VIDEO][URL] Presigned URL generated', {
            key: s3Key,
            expiresIn: `${this.expirationMinutes} minutes`,
            url: mockUrl.substring(0, 100) + '...'
        });
        
        return mockUrl;
    }
    
    /**
     * Generate evidence viewer URL with multiple signed URLs
     * @param {Array<string>} s3Keys - Array of S3 object keys
     * @returns {Promise<string>} Evidence viewer URL
     * @private
     */
    async _generateEvidenceViewerURL(s3Keys) {
        // Generate presigned URLs for all frames
        const signedUrls = [];
        
        for (const s3Key of s3Keys) {
            try {
                const signedUrl = await this._generatePresignedURL(s3Key);
                signedUrls.push(signedUrl);
            } catch (error) {
                console.log('[VIDEO][URL] Failed to generate URL for key:', s3Key, error.message);
                // Continue with other frames
            }
        }
        
        if (signedUrls.length === 0) {
            throw new Error('No signed URLs generated');
        }
        
        // Extract incident ID from first S3 key
        // Format: video-evidence/{incidentId}/frame_...
        const incidentId = this._extractIncidentId(s3Keys[0]);
        
        // Encode signed URLs as query parameter
        const encodedUrls = encodeURIComponent(JSON.stringify(signedUrls));
        
        // Evidence viewer URL format
        // In production, this would point to actual evidence viewer page
        const viewerBaseUrl = this._getEvidenceViewerBaseUrl();
        const viewerUrl = `${viewerBaseUrl}?incident=${incidentId}&urls=${encodedUrls}&expires=${this.expirationMinutes}`;
        
        console.log('[VIDEO][URL] Evidence viewer URL generated', {
            incidentId: incidentId,
            frameCount: signedUrls.length,
            expiresIn: `${this.expirationMinutes} minutes`,
            url: viewerUrl.substring(0, 100) + '...'
        });
        
        return viewerUrl;
    }
    
    /**
     * Extract incident ID from S3 key
     * @param {string} s3Key - S3 object key (format: video-evidence/{incidentId}/...)
     * @returns {string} Incident ID
     * @private
     */
    _extractIncidentId(s3Key) {
        const parts = s3Key.split('/');
        if (parts.length >= 2 && parts[0] === 'video-evidence') {
            return parts[1];
        }
        return 'unknown';
    }
    
    /**
     * Get evidence viewer base URL
     * @returns {string} Base URL for evidence viewer
     * @private
     */
    _getEvidenceViewerBaseUrl() {
        // In production, this would be configured via environment variable
        // For now, return placeholder
        return 'https://allsenses-guardian.example.com/evidence-viewer';
    }
    
    /**
     * Request presigned URLs from backend Lambda
     * Alternative implementation mode when backend generates URLs
     * @param {Object} payload - Request payload
     * @param {string} payload.incidentId - Incident identifier
     * @param {Array<string>} payload.s3Keys - S3 object keys
     * @returns {Promise<Array<string>>} Array of presigned URLs
     */
    async requestPresignedUrls(payload) {
        console.log('[VIDEO][URL] Requesting presigned URLs from backend', payload);
        
        // In production, this would call backend Lambda endpoint
        // Example:
        /*
        const response = await fetch('/api/video-evidence/presigned-urls', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });
        
        if (!response.ok) {
            throw new Error(`Backend request failed: ${response.status}`);
        }
        
        const data = await response.json();
        return data.presignedUrls;
        */
        
        // Placeholder implementation
        const mockUrls = payload.s3Keys.map(key => 
            `https://s3.${this.region}.amazonaws.com/${this.bucketName}/${key}?X-Amz-Signature=MOCK`
        );
        
        console.log('[VIDEO][URL] Presigned URLs received from backend', { count: mockUrls.length });
        
        return mockUrls;
    }
    
    /**
     * Upload via Lambda endpoint (fallback mode)
     * @param {string} incidentId - Incident identifier
     * @param {Blob} blob - Video frame blob
     * @param {string} contentType - Content type
     * @returns {Promise<string>} S3 key of uploaded object
     */
    async uploadViaLambda(incidentId, blob, contentType) {
        console.log('[VIDEO][URL] Uploading via Lambda endpoint', { 
            incidentId, 
            size: blob.size, 
            contentType 
        });
        
        // In production, this would POST to Lambda endpoint
        // Example:
        /*
        const formData = new FormData();
        formData.append('incidentId', incidentId);
        formData.append('file', blob);
        formData.append('contentType', contentType);
        
        const response = await fetch('/api/video-evidence/upload', {
            method: 'POST',
            body: formData
        });
        
        if (!response.ok) {
            throw new Error(`Upload failed: ${response.status}`);
        }
        
        const data = await response.json();
        return data.s3Key;
        */
        
        // Placeholder implementation
        const mockS3Key = `video-evidence/${incidentId}/${Date.now()}-frame.webm`;
        console.log('[VIDEO][URL] Upload via Lambda complete', { s3Key: mockS3Key });
        
        return mockS3Key;
    }
    
    /**
     * Get generator statistics (for monitoring)
     * @returns {Object} Generator statistics
     */
    getStats() {
        return {
            bucketName: this.bucketName,
            region: this.region,
            expirationMinutes: this.expirationMinutes,
            s3ClientInitialized: this.s3Client !== null
        };
    }
}

// Export for use in other modules
// NO automatic execution - class must be explicitly instantiated
if (typeof module !== 'undefined' && module.exports) {
    module.exports = SignedURLGenerator;
}
