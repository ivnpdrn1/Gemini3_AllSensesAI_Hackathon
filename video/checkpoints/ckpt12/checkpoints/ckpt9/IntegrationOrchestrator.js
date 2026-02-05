/**
 * Integration Orchestrator for Video SMS Evidence Capture
 * 
 * This orchestrator is the ONLY bridge between:
 * - Video Panel UI
 * - VideoCaptureModule
 * - VideoStorageService / SignedURLGenerator
 * - SMSComposer additive field (later task)
 * 
 * CRITICAL WIRING RULE:
 * - Only wired to Step 4 panel button click
 * - NO listeners on Steps 1-3 buttons
 * - NO auto-capture when Step 4 is shown
 * - NO background prefetch of presigned URLs
 * - NO network calls at page load
 * 
 * @version 1.0.0
 * @date 2026-02-01
 */

class IntegrationOrchestrator {
    constructor() {
        this.videoCaptureModule = null;
        this.videoStorageService = null;
        this.signedURLGenerator = null;
        
        console.log('[VIDEO_ORCH] orchestrator initialized (no network calls)');
    }
    
    /**
     * Initialize orchestrator with required modules
     * @param {VideoCaptureModule} captureModule
     * @param {VideoStorageService} storageService
     * @param {SignedURLGenerator} urlGenerator
     */
    init(captureModule, storageService, urlGenerator) {
        this.videoCaptureModule = captureModule;
        this.videoStorageService = storageService;
        this.signedURLGenerator = urlGenerator;
        
        console.log('[VIDEO_ORCH] modules wired');
    }
    
    /**
     * Run complete video capture flow
     * 
     * This is the ONLY entry point for video capture.
     * Called ONLY from Step 4 panel button click.
     * 
     * Flow:
     * 1. Set UI state -> capturing
     * 2. Request camera permission
     * 3. Capture frames OR clip (per spec)
     * 4. Request presigned upload URL(s) from backend
     * 5. Upload blobs to S3
     * 6. Return structured result
     * 7. Set UI state -> complete or error
     * 
     * @param {string} incidentId - Unique incident identifier
     * @returns {Promise<Object>} Result object: { ok, videoEvidenceUrl?, uploadedKeys?, error? }
     */
    async runCaptureFlow(incidentId) {
        console.log('[VIDEO_ORCH] start');
        
        // Validate incident ID
        if (!incidentId || typeof incidentId !== 'string') {
            console.log('[VIDEO_ORCH] invalid incidentId');
            return {
                ok: false,
                error: 'Invalid incident ID'
            };
        }
        
        try {
            // Step 1: Set UI state to capturing
            if (typeof updateVideoPanelStatus === 'function') {
                updateVideoPanelStatus('capturing', 'Requesting camera permission...');
            }
            
            // Step 2: Capture frames
            console.log('[VIDEO_ORCH] requesting camera permission');
            
            if (!this.videoCaptureModule) {
                throw new Error('VideoCaptureModule not initialized');
            }
            
            const captureResult = await this.videoCaptureModule.captureEmergencyFrames(incidentId);
            
            if (!captureResult.success || !captureResult.frames || captureResult.frames.length === 0) {
                console.log('[VIDEO_ORCH] capture failed:', captureResult.error || 'no frames');
                
                if (typeof updateVideoPanelStatus === 'function') {
                    updateVideoPanelStatus('error', captureResult.error || 'Camera access denied or no frames captured');
                }
                
                return {
                    ok: false,
                    error: captureResult.error || 'Capture failed'
                };
            }
            
            const frameCount = captureResult.frames.length;
            const duration = captureResult.duration || 'unknown';
            console.log(`[VIDEO_ORCH] captured frames: ${frameCount}, duration: ${duration}ms`);
            
            // Step 3: Upload frames to S3
            console.log('[VIDEO_ORCH] uploading frames to S3');
            
            if (typeof updateVideoPanelStatus === 'function') {
                updateVideoPanelStatus('capturing', `Uploading ${frameCount} frames...`);
            }
            
            if (!this.videoStorageService) {
                throw new Error('VideoStorageService not initialized');
            }
            
            const uploadResult = await this.videoStorageService.uploadVideoFrames(
                incidentId,
                captureResult.frames
            );
            
            if (!uploadResult.success || !uploadResult.uploadedKeys || uploadResult.uploadedKeys.length === 0) {
                console.log('[VIDEO_ORCH] upload failed:', uploadResult.error || 'no keys returned');
                
                if (typeof updateVideoPanelStatus === 'function') {
                    updateVideoPanelStatus('error', uploadResult.error || 'Upload failed');
                }
                
                return {
                    ok: false,
                    error: uploadResult.error || 'Upload failed'
                };
            }
            
            console.log(`[VIDEO_ORCH] upload ok: ${uploadResult.uploadedKeys.length} frames`);
            
            // Step 4: Generate signed URL for evidence viewer
            console.log('[VIDEO_ORCH] generating signed URL');
            
            if (!this.signedURLGenerator) {
                throw new Error('SignedURLGenerator not initialized');
            }
            
            const urlResult = await this.signedURLGenerator.generateVideoEvidenceURL(
                uploadResult.uploadedKeys
            );
            
            if (!urlResult.success || !urlResult.url) {
                console.log('[VIDEO_ORCH] URL generation failed:', urlResult.error || 'no URL returned');
                
                if (typeof updateVideoPanelStatus === 'function') {
                    updateVideoPanelStatus('error', urlResult.error || 'URL generation failed');
                }
                
                return {
                    ok: false,
                    error: urlResult.error || 'URL generation failed',
                    uploadedKeys: uploadResult.uploadedKeys
                };
            }
            
            console.log('[VIDEO_ORCH] done - success');
            
            // Step 5: Set UI state to complete
            if (typeof updateVideoPanelStatus === 'function') {
                updateVideoPanelStatus('complete', `${frameCount} frames captured and uploaded`);
            }
            
            return {
                ok: true,
                videoEvidenceUrl: urlResult.url,
                uploadedKeys: uploadResult.uploadedKeys,
                frameCount: frameCount,
                duration: duration
            };
            
        } catch (error) {
            console.log('[VIDEO_ORCH] exception:', error.message);
            
            if (typeof updateVideoPanelStatus === 'function') {
                updateVideoPanelStatus('error', error.message);
            }
            
            return {
                ok: false,
                error: error.message
            };
        }
    }
    
    /**
     * Check if orchestrator is ready
     * @returns {boolean}
     */
    isReady() {
        return !!(this.videoCaptureModule && this.videoStorageService && this.signedURLGenerator);
    }
}

// Export for module systems
if (typeof module !== 'undefined' && module.exports) {
    module.exports = IntegrationOrchestrator;
}

// Make available globally for browser
if (typeof window !== 'undefined') {
    window.IntegrationOrchestrator = IntegrationOrchestrator;
}
