#!/usr/bin/env python3
"""
Add Vision Panel to Production Jury-Ready UI
Adds Video Frames panel INSIDE Step 4 section additively
Preserves all existing production UX pixel-for-pixel
"""

import re

# Read production file
with open('Gemini3_AllSensesAI/gemini3-guardian-ux-enhanced.html', 'r', encoding='utf-8') as f:
    content = f.read()

# Vision Panel CSS (add to <style> section)
vision_css = """
        /* Vision Context Analysis Panel */
        .vision-context-panel { background: #f0f8ff; border: 2px solid #4a90e2; padding: 20px; border-radius: 10px; margin: 20px 0; }
        .vision-context-panel h4 { margin: 0 0 15px 0; color: #2c5aa0; font-size: 1.2em; }
        .vision-status-badge { display: inline-block; padding: 6px 14px; border-radius: 20px; font-size: 0.9em; font-weight: bold; margin-bottom: 15px; }
        .vision-status-badge.standby { background: #e9ecef; color: #6c757d; }
        .vision-status-badge.capturing { background: #fff3cd; color: #856404; animation: visionPulse 1.5s infinite; }
        .vision-status-badge.analyzing { background: #cfe2ff; color: #084298; animation: visionPulse 1.5s infinite; }
        .vision-status-badge.complete { background: #d1e7dd; color: #0f5132; }
        .vision-status-badge.error { background: #f8d7da; color: #842029; }
        .vision-explainer { background: #fff; padding: 12px; border-radius: 6px; margin: 10px 0; font-size: 0.95em; color: #495057; border-left: 4px solid #4a90e2; }
        .vision-placeholders { background: #f8f9fa; padding: 15px; border-radius: 6px; margin: 10px 0; color: #adb5bd; font-style: italic; }
        .vision-placeholders p { margin: 5px 0; }
        .vision-frames-placeholder { margin: 15px 0; }
        .frame-placeholder { display: inline-block; margin: 5px; }
        .vision-thumbnails { display: flex; gap: 10px; margin: 15px 0; flex-wrap: wrap; }
        .vision-thumbnail { width: 120px; height: 90px; border-radius: 6px; object-fit: cover; border: 2px solid #dee2e6; }
        .vision-thumbnail.blurred { filter: blur(8px); }
        .vision-thumbnail-toggle { background: #6c757d; color: white; border: none; padding: 6px 12px; border-radius: 4px; cursor: pointer; font-size: 0.85em; margin-top: 8px; }
        .vision-thumbnail-toggle:hover { background: #5a6268; }
        .vision-findings { background: #fff; padding: 15px; border-radius: 6px; margin: 10px 0; }
        .vision-findings ul { margin: 10px 0; padding-left: 20px; }
        .vision-findings li { margin: 6px 0; color: #495057; }
        .vision-confidence { background: #f8f9fa; padding: 10px; border-radius: 6px; margin: 10px 0; display: inline-block; }
        .vision-confidence .badge { padding: 4px 10px; border-radius: 12px; font-size: 0.85em; font-weight: bold; margin-left: 8px; }
        .vision-confidence .badge.low { background: #d1e7dd; color: #0f5132; }
        .vision-confidence .badge.medium { background: #fff3cd; color: #856404; }
        .vision-confidence .badge.high { background: #f8d7da; color: #842029; }
        .vision-evidence-indicator { background: #d1e7dd; padding: 10px 15px; border-radius: 6px; margin: 10px 0; color: #0f5132; font-weight: 500; border-left: 4px solid #198754; }
        .vision-why-helps { font-size: 0.85em; color: #6c757d; margin-top: 10px; font-style: italic; }
        
        @keyframes visionPulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.6; }
        }
"""

# Insert Vision CSS before </style>
content = content.replace('</style>', vision_css + '    </style>')

# Vision Panel HTML (insert after Step 4 heading)
vision_panel_html = """
            <!-- NEW: Visual Context Analysis Panel (Always Visible) -->
            <div id="visionContextPanel" class="vision-context-panel">
                <h4>🎥 Visual Context (Gemini Vision) — Video Frames</h4>
                
                <div id="visionStatusBadge" class="vision-status-badge standby">
                    <span>Standby</span>
                </div>
                
                <div id="visionExplainer" class="vision-explainer">
                    <p><strong>Standby:</strong> Activates automatically during detected risk to corroborate audio/text signals.</p>
                    <p><strong>Capture policy:</strong> Captures 1–3 video frames during emergency. No continuous recording.</p>
                </div>
                
                <!-- Video Frames Placeholders (Always Visible Before Trigger) -->
                <div id="visionFramesPlaceholder" class="vision-frames-placeholder">
                    <h5 style="margin: 10px 0; color: #6c757d; font-size: 1em;">📹 Video Frames (Standby)</h5>
                    <div style="display: flex; gap: 10px; flex-wrap: wrap;">
                        <div class="frame-placeholder">
                            <div style="width: 120px; height: 90px; background: #e9ecef; border: 2px dashed #adb5bd; border-radius: 6px; display: flex; align-items: center; justify-content: center; color: #6c757d; font-size: 0.85em; text-align: center; padding: 5px;">
                                Frame 1<br>not captured
                            </div>
                        </div>
                        <div class="frame-placeholder">
                            <div style="width: 120px; height: 90px; background: #e9ecef; border: 2px dashed #adb5bd; border-radius: 6px; display: flex; align-items: center; justify-content: center; color: #6c757d; font-size: 0.85em; text-align: center; padding: 5px;">
                                Frame 2<br>not captured
                            </div>
                        </div>
                        <div class="frame-placeholder">
                            <div style="width: 120px; height: 90px; background: #e9ecef; border: 2px dashed #adb5bd; border-radius: 6px; display: flex; align-items: center; justify-content: center; color: #6c757d; font-size: 0.85em; text-align: center; padding: 5px;">
                                Frame 3<br>not captured
                            </div>
                        </div>
                    </div>
                </div>
                
                <div id="visionPlaceholders" class="vision-placeholders">
                    <p><strong>Findings:</strong> —</p>
                    <p><strong>Confidence:</strong> —</p>
                    <p><strong>Vision/Video Status:</strong> Standby</p>
                </div>
                
                <div id="visionTriggerReason" style="background: #fff3cd; padding: 12px; border-radius: 6px; margin: 10px 0; font-size: 0.95em; color: #856404; border-left: 4px solid #ffc107; display:none;">
                    <p><strong>Activated because:</strong> <span id="visionTriggerText">—</span></p>
                </div>
                
                <div id="visionThumbnails" class="vision-thumbnails" style="display:none;">
                    <!-- Thumbnails will be inserted here -->
                </div>
                
                <div id="visionFindings" class="vision-findings" style="display:none;">
                    <strong>Environmental Risk Indicators:</strong>
                    <ul id="visionFindingsList">
                        <!-- Findings will be inserted here -->
                    </ul>
                </div>
                
                <div id="visionConfidence" class="vision-confidence" style="display:none;">
                    <strong>Confidence:</strong>
                    <span class="badge" id="visionConfidenceBadge">—</span>
                </div>
                
                <div id="visionEvidenceIndicator" class="vision-evidence-indicator" style="display:none;">
                    ✅ Added to Evidence Packet
                </div>
                
                <div class="vision-why-helps">
                    💡 Why this helps: Visual context helps responders validate environment risk when voice is limited or ambiguous.
                </div>
            </div>
            
"""

# Find Step 4 section and insert Vision panel after the heading
step4_pattern = r'(<h3>🤖 Step 4 — Gemini3 Threat Analysis</h3>)'
content = re.sub(step4_pattern, r'\1' + vision_panel_html, content)

# Update build stamp
content = content.replace('Build: GEMINI3-UX-ENHANCED-20260127', 'Build: GEMINI3-VISION-ADDITIVE-20260127')

# Write output
with open('Gemini3_AllSensesAI/gemini3-guardian-vision-additive.html', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Vision panel added to production UI")
print("✅ Output: Gemini3_AllSensesAI/gemini3-guardian-vision-additive.html")
print("✅ Build stamp updated: GEMINI3-VISION-ADDITIVE-20260127")
print("")
print("Next steps:")
print("1. Review the output file")
print("2. Deploy to S3/CloudFront")
print("3. Test on live URL")
