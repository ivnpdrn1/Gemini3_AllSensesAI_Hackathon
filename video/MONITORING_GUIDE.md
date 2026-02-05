# Video Evidence Monitoring and Alerting Guide

**Build ID**: GEMINI3-GUARDIAN-SMS-VIDEO-20260131-v1  
**Feature**: Video SMS Evidence Capture  
**Task**: 16 - Implement monitoring and alerting

## Overview

This guide documents the CloudWatch monitoring and alerting infrastructure for the Video SMS Evidence Capture feature. The monitoring system tracks video capture success/failure rates, upload performance, SMS delivery status, and regression detection to ensure emergency notifications are never blocked.

## Architecture

### Components

1. **CloudWatch Metrics**: Track video capture, upload, and SMS delivery events
2. **CloudWatch Alarms**: Alert on failure rate thresholds and critical issues
3. **SNS Topics**: Deliver alarm notifications via email
4. **CloudWatch Dashboard**: Visualize system health and performance
5. **Log-Based Metrics**: Extract metrics from application logs

### Metrics Namespace

All metrics are published under the namespace: `AllSenses/VideoEvidence`

## CloudWatch Metrics

### Video Capture Metrics

| Metric Name | Description | Unit | Source |
|-------------|-------------|------|--------|
| `VideoCaptureSuccess` | Successful video captures | Count | Log filter: `[VIDEO] capture completed` |
| `VideoCaptureFailure` | Failed video captures (camera denied, errors) | Count | Log filter: `[VIDEO] permission denied` |

### Video Upload Metrics

| Metric Name | Description | Unit | Source |
|-------------|-------------|------|--------|
| `VideoUploadSuccess` | Successful S3 uploads | Count | Log filter: `[VIDEO] upload success` |
| `VideoUploadFailure` | Failed S3 uploads | Count | Log filter: `[VIDEO] upload failure` |

### SMS Delivery Metrics

| Metric Name | Description | Unit | Source |
|-------------|-------------|------|--------|
| `SMSWithVideo` | SMS sent with video URL | Count | Log filter: `[SMS] sent with video URL` |
| `SMSWithoutVideo` | SMS sent without video URL | Count | Log filter: `[SMS] sent without video URL` |
| `SMSDeliveryFailure` | SMS delivery failures (CRITICAL) | Count | Log filter: `[SMS] delivery failed` |

### System Health Metrics

| Metric Name | Description | Unit | Source |
|-------------|-------------|------|--------|
| `RegressionDetected` | Regression in Steps 1-3 (CRITICAL) | Count | Log filter: `[REGRESSION] detected` |

## CloudWatch Alarms

### Warning Alarms

#### Video Capture Failure Rate Alarm
- **Name**: `AllSenses-VideoCaptureFailureRate-High`
- **Threshold**: > 50% failure rate (configurable)
- **Evaluation**: 2 consecutive periods of 5 minutes
- **Action**: Send notification to Alarm SNS Topic
- **Severity**: Warning

#### Video Upload Failure Rate Alarm
- **Name**: `AllSenses-VideoUploadFailureRate-High`
- **Threshold**: > 30% failure rate (configurable)
- **Evaluation**: 2 consecutive periods of 5 minutes
- **Action**: Send notification to Alarm SNS Topic
- **Severity**: Warning

### Critical Alarms

#### SMS Delivery Failure Alarm
- **Name**: `AllSenses-SMSDeliveryFailure-CRITICAL`
- **Threshold**: ≥ 1 failure
- **Evaluation**: 1 period of 1 minute
- **Action**: Send notification to Critical SNS Topic
- **Severity**: **CRITICAL** - Emergency notifications blocked
- **Response**: Immediate investigation required

#### Regression Detected Alarm
- **Name**: `AllSenses-RegressionDetected-CRITICAL`
- **Threshold**: ≥ 1 regression
- **Evaluation**: 1 period of 1 minute
- **Action**: Send notification to Critical SNS Topic
- **Severity**: **CRITICAL** - Steps 1-3 functionality broken
- **Response**: Immediate rollback required

### Composite Alarm

#### Video Evidence System Health
- **Name**: `AllSenses-VideoEvidenceSystemHealth`
- **Logic**: Triggers if ANY of the above alarms are in ALARM state
- **Action**: Send notification to Alarm SNS Topic
- **Purpose**: Single alarm for overall system health

## Deployment

### Prerequisites

1. AWS CLI configured with appropriate credentials
2. CloudFormation permissions
3. Valid email address for alarm notifications

### Deploy Monitoring Stack

```powershell
# Basic deployment
./Gemini3_AllSensesAI/video/deploy-monitoring.ps1 `
    -AlertEmail "your-email@example.com"

# Custom thresholds
./Gemini3_AllSensesAI/video/deploy-monitoring.ps1 `
    -AlertEmail "your-email@example.com" `
    -VideoCaptureFailureThreshold 60 `
    -VideoUploadFailureThreshold 40 `
    -Region "us-east-1"
```

### Verify Deployment

```powershell
# Test metrics publishing
./Gemini3_AllSensesAI/video/test-monitoring.ps1

# Check stack status
aws cloudformation describe-stacks \
    --stack-name AllSenses-VideoEvidence-Monitoring \
    --region us-east-1
```

### Confirm SNS Subscriptions

After deployment, you will receive confirmation emails for:
1. **Alarm Topic**: General warnings and system health alerts
2. **Critical Topic**: Critical failures requiring immediate action

**IMPORTANT**: Click the confirmation links in both emails to activate notifications.

## Frontend Integration

### Publishing Metrics from JavaScript

The frontend must publish log messages to CloudWatch Logs to trigger metrics. Here's how to integrate:

#### 1. Configure CloudWatch Logs Client

```javascript
// Configure AWS SDK for CloudWatch Logs
const cloudwatchlogs = new AWS.CloudWatchLogs({
    region: 'us-east-1',
    credentials: {
        accessKeyId: 'YOUR_ACCESS_KEY',
        secretAccessKey: 'YOUR_SECRET_KEY'
    }
});

const LOG_GROUP_NAME = '/allsenses/video-evidence/metrics';
const LOG_STREAM_NAME = `frontend-${Date.now()}`;
```

#### 2. Create Log Stream (Once)

```javascript
async function createLogStream() {
    try {
        await cloudwatchlogs.createLogStream({
            logGroupName: LOG_GROUP_NAME,
            logStreamName: LOG_STREAM_NAME
        }).promise();
        console.log('Log stream created');
    } catch (error) {
        if (error.code !== 'ResourceAlreadyExistsException') {
            console.error('Error creating log stream:', error);
        }
    }
}
```

#### 3. Publish Metrics

```javascript
async function publishMetric(message) {
    try {
        await cloudwatchlogs.putLogEvents({
            logGroupName: LOG_GROUP_NAME,
            logStreamName: LOG_STREAM_NAME,
            logEvents: [{
                timestamp: Date.now(),
                message: message
            }]
        }).promise();
    } catch (error) {
        console.error('Error publishing metric:', error);
    }
}
```

#### 4. Integration Points

```javascript
// Video Capture Module
class VideoCaptureModule {
    async captureEmergencyFrames(incidentId) {
        console.log('[VIDEO] init');
        
        try {
            const stream = await navigator.mediaDevices.getUserMedia({ 
                video: true, 
                audio: false 
            });
            console.log('[VIDEO] permission granted');
            
            console.log('[VIDEO] capture started');
            const frames = await this._recordFrames(stream, 3000);
            console.log('[VIDEO] capture completed');
            
            // Publish metric
            await publishMetric('[VIDEO] capture completed');
            
            return frames;
        } catch (error) {
            console.log('[VIDEO] permission denied', error.message);
            
            // Publish metric
            await publishMetric('[VIDEO] permission denied');
            
            throw new VideoCaptureException(error);
        }
    }
}

// Video Storage Service
class VideoStorageService {
    async uploadVideoFrames(incidentId, frames) {
        for (let i = 0; i < frames.length; i++) {
            try {
                await this.s3Client.putObject({...});
                console.log('[VIDEO] upload success', key);
                
                // Publish metric
                await publishMetric('[VIDEO] upload success');
                
                uploadedKeys.push(key);
            } catch (error) {
                console.log('[VIDEO] upload failure', error.message);
                
                // Publish metric
                await publishMetric('[VIDEO] upload failure');
            }
        }
    }
}

// SMS Composer
class SMSComposer {
    async sendEmergencySMS(payload) {
        try {
            await this.smsClient.send(payload);
            
            if (payload.videoEvidenceUrl) {
                console.log('[SMS] sent with video URL');
                await publishMetric('[SMS] sent with video URL');
            } else {
                console.log('[SMS] sent without video URL');
                await publishMetric('[SMS] sent without video URL');
            }
        } catch (error) {
            console.log('[SMS] delivery failed', error.message);
            
            // CRITICAL metric
            await publishMetric('[SMS] delivery failed');
            
            throw error;
        }
    }
}

// Regression Detection
async function detectRegression() {
    // Check Step 1 button
    const step1Button = document.querySelector('button[onclick="completeStep1()"]');
    if (!step1Button || step1Button.textContent !== '✅ Complete Step 1') {
        console.log('[REGRESSION] detected: Step 1 button modified');
        await publishMetric('[REGRESSION] detected');
        return true;
    }
    
    // Check SMS delivery without video
    try {
        await sendTestSMS();
    } catch (error) {
        console.log('[REGRESSION] detected: SMS delivery failed');
        await publishMetric('[REGRESSION] detected');
        return true;
    }
    
    return false;
}
```

### Alternative: Server-Side Logging

For production deployments, consider logging from the backend Lambda functions instead of the frontend:

```python
import boto3
import logging

cloudwatch_logs = boto3.client('logs')
LOG_GROUP_NAME = '/allsenses/video-evidence/metrics'

def publish_metric(message):
    try:
        cloudwatch_logs.put_log_events(
            logGroupName=LOG_GROUP_NAME,
            logStreamName=f'backend-{int(time.time())}',
            logEvents=[{
                'timestamp': int(time.time() * 1000),
                'message': message
            }]
        )
    except Exception as e:
        logging.error(f'Error publishing metric: {e}')
```

## CloudWatch Dashboard

### Accessing the Dashboard

URL: `https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=AllSenses-VideoEvidence-Monitoring`

### Dashboard Widgets

1. **Video Capture Success vs Failure**: Line chart showing capture success/failure over time
2. **Video Upload Success vs Failure**: Line chart showing upload success/failure over time
3. **SMS Delivery With/Without Video**: Line chart showing SMS delivery patterns
4. **CRITICAL: SMS Failures & Regressions**: Line chart highlighting critical issues

### Interpreting the Dashboard

- **Green lines trending up**: System healthy, features working
- **Red lines trending up**: Failures increasing, investigate immediately
- **Flat lines**: No activity (expected during low usage periods)
- **Spikes in critical metrics**: Immediate action required

## Alarm Response Procedures

### Video Capture Failure Rate > 50%

**Severity**: Warning  
**Possible Causes**:
- Camera permissions denied by users
- Browser compatibility issues
- Hardware unavailable (desktop environments)

**Response**:
1. Check browser console logs for error patterns
2. Review user agent strings to identify problematic browsers
3. Verify getUserMedia API compatibility
4. Consider adding fallback messaging for unsupported devices

**Impact**: Video evidence unavailable, but SMS still delivered

### Video Upload Failure Rate > 30%

**Severity**: Warning  
**Possible Causes**:
- S3 service issues
- Network connectivity problems
- Insufficient IAM permissions
- S3 bucket quota exceeded

**Response**:
1. Check AWS Service Health Dashboard
2. Verify S3 bucket accessibility
3. Review IAM role permissions
4. Check S3 bucket metrics for throttling

**Impact**: Video captured but not stored, SMS delivered without video URL

### SMS Delivery Failure

**Severity**: **CRITICAL**  
**Possible Causes**:
- SNS service outage
- Invalid phone numbers
- SMS quota exceeded
- Lambda function errors

**Response**:
1. **IMMEDIATE**: Check AWS Service Health Dashboard
2. Verify SNS service status
3. Review Lambda function logs
4. Check SNS sending quotas
5. Test SMS delivery manually
6. **If persistent**: Activate backup notification channel

**Impact**: **Emergency notifications blocked** - highest priority issue

### Regression Detected

**Severity**: **CRITICAL**  
**Possible Causes**:
- Video code modified Steps 1-3
- Deployment error
- Code merge conflict
- Unintended side effects

**Response**:
1. **IMMEDIATE**: Rollback to previous build
2. Run regression test checklist
3. Compare current vs baseline builds
4. Identify breaking changes
5. Fix and re-test before redeployment

**Impact**: **Core functionality broken** - requires immediate rollback

## Monitoring Best Practices

### 1. Regular Dashboard Reviews

- Check dashboard daily during initial deployment
- Review weekly during stable operation
- Investigate any unusual patterns immediately

### 2. Alarm Threshold Tuning

- Start with conservative thresholds (50%, 30%)
- Adjust based on actual failure patterns
- Avoid alarm fatigue from false positives

### 3. Metric Retention

- Metrics retained for 15 months by default
- Export to S3 for long-term analysis
- Use for capacity planning and trend analysis

### 4. Alert Escalation

- Warning alarms: DevOps team (email)
- Critical alarms: On-call engineer (email + SMS)
- Consider PagerDuty integration for critical alarms

### 5. Runbook Maintenance

- Document response procedures for each alarm
- Update runbooks based on incident learnings
- Test alarm response procedures quarterly

## Troubleshooting

### Metrics Not Appearing

**Problem**: Published log messages but no metrics in CloudWatch

**Solutions**:
1. Wait 5-10 minutes for metrics to propagate
2. Verify log messages match filter patterns exactly
3. Check log group name is correct
4. Verify metric filters are enabled
5. Check CloudWatch Logs Insights for log messages

### Alarms Not Triggering

**Problem**: Metrics show failures but alarms don't trigger

**Solutions**:
1. Verify alarm is in "OK" state (not "INSUFFICIENT_DATA")
2. Check alarm threshold and evaluation periods
3. Ensure SNS topic subscriptions are confirmed
4. Review alarm history in CloudWatch console
5. Test alarm manually using "Set Alarm State" action

### SNS Notifications Not Received

**Problem**: Alarms trigger but no email received

**Solutions**:
1. Check spam/junk folder
2. Verify SNS subscription is confirmed (check email)
3. Test SNS topic manually: `aws sns publish --topic-arn <ARN> --message "Test"`
4. Check SNS topic delivery logs
5. Verify email address is correct

## Cost Considerations

### Estimated Monthly Costs

Based on 1000 emergencies/month with video capture:

| Service | Usage | Cost |
|---------|-------|------|
| CloudWatch Metrics | 8 custom metrics | $2.40 |
| CloudWatch Alarms | 6 alarms | $0.60 |
| CloudWatch Dashboard | 1 dashboard | $3.00 |
| CloudWatch Logs | 10 GB ingestion | $5.00 |
| SNS Notifications | 100 emails | $0.00 |
| **Total** | | **~$11/month** |

### Cost Optimization

1. Use log-based metrics instead of custom metrics where possible
2. Adjust log retention to 7-30 days for cost savings
3. Use composite alarms to reduce alarm count
4. Archive old logs to S3 for long-term storage

## Security Considerations

### IAM Permissions

The monitoring stack requires:
- `logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents`
- `cloudwatch:PutMetricData`
- `sns:Publish` (for alarm notifications)

### Data Privacy

- Log messages should NOT contain PII (names, phone numbers, addresses)
- Use incident IDs instead of user identifiers
- Redact sensitive data before logging
- Enable log encryption at rest

### Access Control

- Restrict CloudWatch dashboard access to authorized personnel
- Use IAM roles for service-to-service communication
- Enable CloudTrail logging for audit trail
- Review SNS topic access policies

## Appendix

### Metric Filter Patterns

```
Video Capture Success:  [VIDEO] capture completed
Video Capture Failure:  [VIDEO] permission denied
Video Upload Success:   [VIDEO] upload success
Video Upload Failure:   [VIDEO] upload failure
SMS With Video:         [SMS] sent with video URL
SMS Without Video:      [SMS] sent without video URL
SMS Delivery Failure:   [SMS] delivery failed
Regression Detected:    [REGRESSION] detected
```

### CloudFormation Stack Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `AlertEmail` | alerts@allsenses.example.com | Email for alarm notifications |
| `VideoCaptureFailureThreshold` | 50 | Video capture failure rate threshold (%) |
| `VideoUploadFailureThreshold` | 30 | Video upload failure rate threshold (%) |
| `EvaluationPeriods` | 2 | Number of periods before triggering alarm |

### Related Documentation

- [Video SMS Evidence Capture Requirements](../../.kiro/specs/video-sms-evidence-capture/requirements.md)
- [Video SMS Evidence Capture Design](../../.kiro/specs/video-sms-evidence-capture/design.md)
- [Video SMS Evidence Capture Tasks](../../.kiro/specs/video-sms-evidence-capture/tasks.md)
- [S3 Video Evidence Storage](../../infrastructure/video-evidence-storage.yaml)

---

**Last Updated**: 2026-01-31  
**Build ID**: GEMINI3-GUARDIAN-SMS-VIDEO-20260131-v1  
**Maintainer**: AllSenses DevOps Team
