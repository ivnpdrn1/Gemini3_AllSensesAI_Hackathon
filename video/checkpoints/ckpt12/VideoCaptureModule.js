/**
 * VideoCaptureModule - Client-side video evidence capture for Step 4 emergencies
 * 
 * CRITICAL RULES:
 * - Must NOT run on page load
 * - Must NOT request camera permission until Step 4 user action
 * - All failures are non-fatal (return empty arrays, never throw to caller)
 * - Proof logging is mandatory for all operations
 * 
 * @module VideoCaptureModule
 * @version 1.0.0
 * @date 2026-02-01
 */

class VideoCaptureModule {
    constructor() {
        this.isCapturing = false;
        this.capturedFrames = [];
        this.incidentId = null;
        this.mediaStream = null;
        this.mediaRecorder = null;
        
        // Configuration
        this.maxFrames = 5;
        this.maxDurationMs = 3000; // 3 seconds max
        this.frameIntervalMs = 400; // ~2.5 frames per second
    }
    
    /**
     * Initialize the module (no permission request)
     * Safe to call on page load or anytime
     */
    init() {
        console.log('[VIDEO] init');
        this.isCapturing = false;
        this.capturedFrames = [];
        this.incidentId = null;
    }
    
    /**
     * Request camera permission from user
     * @returns {Promise<boolean>} true if granted, false if denied
     */
    async requestPermission() {
        try {
            const stream = await navigator.mediaDevices.getUserMedia({ 
                video: true, 
                audio: false 
            });
            
            console.log('[VIDEO] permission granted');
            
            // Stop the stream immediately - we just wanted to check permission
            stream.getTracks().forEach(track => track.stop());
            
            return true;
        } catch (error) {
            console.log('[VIDEO] permission denied', error.message);
            return false;
        }
    }
    
    /**
     * Capture video frames during emergency
     * @param {string} incidentId - Unique emergency incident identifier
     * @returns {Promise<Array<Blob>>} Array of video frame blobs (empty if failed)
     */
    async captureEmergencyFrames(incidentId) {
        this.incidentId = incidentId;
        
        try {
            // Request camera access
            this.mediaStream = await navigator.mediaDevices.getUserMedia({ 
                video: true, 
                audio: false 
            });
            
            console.log('[VIDEO] permission granted');
            console.log('[VIDEO] capture started');
            
            // Capture frames
            const frames = await this._recordFrames(this.mediaStream, this.maxDurationMs);
            
            console.log('[VIDEO] capture completed');
            
            // Clean up
            this._stopStream();
            
            return frames;
            
        } catch (error) {
            console.log('[VIDEO] capture failure:', error.message);
            this._stopStream();
            return []; // Non-fatal: return empty array
        }
    }
    
    /**
     * Capture a video clip (alternative to frame capture)
     * @param {number} maxMs - Maximum duration in milliseconds
     * @returns {Promise<Blob|null>} Video clip blob or null if failed
     */
    async captureClip(maxMs = 3000) {
        try {
            this.mediaStream = await navigator.mediaDevices.getUserMedia({ 
                video: true, 
                audio: false 
            });
            
            console.log('[VIDEO] permission granted');
            console.log('[VIDEO] capture started');
            
            const clip = await this._recordClip(this.mediaStream, maxMs);
            
            console.log('[VIDEO] capture completed');
            
            this._stopStream();
            
            return clip;
            
        } catch (error) {
            console.log('[VIDEO] capture failure:', error.message);
            this._stopStream();
            return null; // Non-fatal: return null
        }
    }
    
    /**
     * Stop any active capture
     */
    stop() {
        console.log('[VIDEO] stop requested');
        this.isCapturing = false;
        this._stopStream();
    }
    
    /**
     * Internal: Record video frames using MediaRecorder
     * @private
     */
    async _recordFrames(stream, durationMs) {
        return new Promise((resolve) => {
            const frames = [];
            const chunks = [];
            
            // Use MediaRecorder to capture video
            const options = { mimeType: 'video/webm;codecs=vp8' };
            
            // Fallback if webm not supported
            if (!MediaRecorder.isTypeSupported(options.mimeType)) {
                options.mimeType = 'video/webm';
            }
            
            this.mediaRecorder = new MediaRecorder(stream, options);
            
            this.mediaRecorder.ondataavailable = (event) => {
                if (event.data && event.data.size > 0) {
                    chunks.push(event.data);
                }
            };
            
            this.mediaRecorder.onstop = () => {
                if (chunks.length > 0) {
                    const blob = new Blob(chunks, { type: options.mimeType });
                    frames.push(blob);
                }
                resolve(frames);
            };
            
            this.mediaRecorder.onerror = (error) => {
                console.log('[VIDEO] capture failure:', error);
                resolve([]); // Non-fatal: return empty array
            };
            
            // Start recording
            this.isCapturing = true;
            this.mediaRecorder.start();
            
            // Stop after max duration
            setTimeout(() => {
                if (this.mediaRecorder && this.mediaRecorder.state !== 'inactive') {
                    this.mediaRecorder.stop();
                }
                this.isCapturing = false;
            }, Math.min(durationMs, this.maxDurationMs));
        });
    }
    
    /**
     * Internal: Record a single video clip
     * @private
     */
    async _recordClip(stream, durationMs) {
        return new Promise((resolve) => {
            const chunks = [];
            
            const options = { mimeType: 'video/webm;codecs=vp8' };
            if (!MediaRecorder.isTypeSupported(options.mimeType)) {
                options.mimeType = 'video/webm';
            }
            
            this.mediaRecorder = new MediaRecorder(stream, options);
            
            this.mediaRecorder.ondataavailable = (event) => {
                if (event.data && event.data.size > 0) {
                    chunks.push(event.data);
                }
            };
            
            this.mediaRecorder.onstop = () => {
                if (chunks.length > 0) {
                    const blob = new Blob(chunks, { type: options.mimeType });
                    resolve(blob);
                } else {
                    resolve(null);
                }
            };
            
            this.mediaRecorder.onerror = (error) => {
                console.log('[VIDEO] capture failure:', error);
                resolve(null);
            };
            
            this.isCapturing = true;
            this.mediaRecorder.start();
            
            setTimeout(() => {
                if (this.mediaRecorder && this.mediaRecorder.state !== 'inactive') {
                    this.mediaRecorder.stop();
                }
                this.isCapturing = false;
            }, Math.min(durationMs, this.maxDurationMs));
        });
    }
    
    /**
     * Internal: Stop media stream and clean up
     * @private
     */
    _stopStream() {
        if (this.mediaStream) {
            this.mediaStream.getTracks().forEach(track => track.stop());
            this.mediaStream = null;
        }
        
        if (this.mediaRecorder) {
            if (this.mediaRecorder.state !== 'inactive') {
                this.mediaRecorder.stop();
            }
            this.mediaRecorder = null;
        }
        
        this.isCapturing = false;
    }
}

// Export for use in HTML (global scope)
if (typeof window !== 'undefined') {
    window.VideoCaptureModule = VideoCaptureModule;
}
