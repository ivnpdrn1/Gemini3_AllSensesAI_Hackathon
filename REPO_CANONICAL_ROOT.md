# Canonical Repository Root Documentation

## Critical Repository Information

**All commits and tags MUST be created from this canonical repository root.**

### Canonical Local Repository Path
```
C:\Users\ivanp\OneDrive\Documents\Kiro\Gemini3_AllSensesAI
```

### Git Repository Root Verification
Expected output from `git rev-parse --show-toplevel`:
```
C:/Users/ivanp/OneDrive/Documents/Kiro/Gemini3_AllSensesAI
```

### GitHub Remote Repository
- **Repository URL**: https://github.com/ivnpdrn1/Gemini3_AllSensesAI_Hackathon.git
- **Owner**: ivnpdrn1 (NOT ivnpdrn)
- **Repository Name**: Gemini3_AllSensesAI_Hackathon

### Production Deployment Configuration
- **CloudFront Distribution ID**: E2NIUI2KOXAO0Q
- **Production URL**: https://dfc8ght8abwqc.cloudfront.net
- **S3 Bucket**: gemini3-guardian-prod-20260127120521

### Current Stable Checkpoint
- **Tag**: v2026.02.05-step2-google-maps-preview-stable
- **Description**: Step2 Google Maps Preview Stable Checkpoint
- **Commit**: 5aae5ddd0aba78fe9f10c28cc47121fc8cf7ab69

### Restore Command
To restore to the current stable checkpoint:
```bash
git checkout v2026.02.05-step2-google-maps-preview-stable
```

## Multiple .git Directories Detected

The following .git directories exist in the parent Kiro folder:
1. `C:\Users\ivanp\OneDrive\Documents\Kiro\.git` (outer repo root)
2. `C:\Users\ivanp\OneDrive\Documents\Kiro\AllSensesAI-ERNIE\.git`
3. `C:\Users\ivanp\OneDrive\Documents\Kiro\Gemini3_AllSensesAI\.git` ✅ **CANONICAL**
4. `C:\Users\ivanp\OneDrive\Documents\Kiro\temp-git-restore\.git`
5. `C:\Users\ivanp\OneDrive\Documents\Kiro\_git_backup_outer_repo\.git`

**IMPORTANT**: Only work inside the canonical repository at `Gemini3_AllSensesAI`. Never create new repositories.

## Verification Commands

Run these commands to verify you're in the correct repository:

```powershell
# Change to canonical repo root
cd C:\Users\ivanp\OneDrive\Documents\Kiro\Gemini3_AllSensesAI

# Verify git root
git rev-parse --show-toplevel
# Expected: C:/Users/ivanp/OneDrive/Documents/Kiro/Gemini3_AllSensesAI

# Verify remote
git remote -v
# Expected: origin https://github.com/ivnpdrn1/Gemini3_AllSensesAI_Hackathon.git

# Verify current branch
git branch --show-current
# Expected: main

# Verify latest commit
git log -1 --oneline
# Expected: 5aae5dd backup(step2): lock stable Step2 checkpoint + documentation

# Verify stable tag exists
git tag -l "v2026.02.05-step2-google-maps-preview-stable"
# Expected: v2026.02.05-step2-google-maps-preview-stable
```

## Hard Rules

1. **Never create a new repository** - Always work inside the canonical repo root
2. **Never use wrong remote** - Always verify remote points to ivnpdrn1/Gemini3_AllSensesAI_Hackathon
3. **Always verify location** - Run `git rev-parse --show-toplevel` before major operations
4. **Tag all stable checkpoints** - Use semantic versioning with date prefix
5. **Push tags immediately** - After creating tags, push them to origin

## Last Updated
- **Date**: 2026-02-05
- **By**: Kiro AI Assistant
- **Purpose**: Enforce canonical repository root and prevent multi-repo confusion
