# Verify S3 Video Evidence Configuration
# Task 15: Verification script for S3 bucket and lifecycle policies
# Build: GEMINI3-GUARDIAN-SMS-VIDEO-20260131-v1

param(
    [string]$Region = "us-east-1",
    [string]$StackName = "allsenses-video-evidence"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "S3 Video Evidence Configuration Verification" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$testsPassed = 0
$testsFailed = 0
$testsWarning = 0

function Test-Requirement {
    param(
        [string]$Name,
        [scriptblock]$Test,
        [string]$Requirement
    )
    
    Write-Host "Testing: $Name" -ForegroundColor Yellow
    Write-Host "  Requirement: $Requirement" -ForegroundColor Gray
    
    try {
        $result = & $Test
        if ($result.Status -eq "PASS") {
            Write-Host "  ✅ PASS: $($result.Message)" -ForegroundColor Green
            $script:testsPassed++
        } elseif ($result.Status -eq "WARN") {
            Write-Host "  ⚠️  WARN: $($result.Message)" -ForegroundColor Yellow
            $script:testsWarning++
        } else {
            Write-Host "  ❌ FAIL: $($result.Message)" -ForegroundColor Red
            $script:testsFailed++
        }
    } catch {
        Write-Host "  ❌ ERROR: $_" -ForegroundColor Red
        $script:testsFailed++
    }
    Write-Host ""
}

# Get stack outputs
Write-Host "Retrieving stack information..." -ForegroundColor Cyan
try {
    $outputs = aws cloudformation describe-stacks `
        --stack-name $StackName `
        --region $Region `
        --query 'Stacks[0].Outputs' `
        --output json 2>&1 | ConvertFrom-Json
    
    $bucket = ($outputs | Where-Object { $_.OutputKey -eq 'VideoEvidenceBucket' }).OutputValue
    $lambdaUrl = ($outputs | Where-Object { $_.OutputKey -eq 'VideoStorageURL' }).OutputValue
    
    Write-Host "  Bucket: $bucket" -ForegroundColor White
    Write-Host "  Lambda URL: $lambdaUrl" -ForegroundColor White
    Write-Host ""
} catch {
    Write-Host "❌ Failed to retrieve stack information: $_" -ForegroundColor Red
    exit 1
}

# Test 1: Bucket Exists
Test-Requirement -Name "S3 Bucket Exists" -Requirement "6.1" -Test {
    try {
        $bucketInfo = aws s3api head-bucket --bucket $bucket --region $Region 2>&1
        if ($LASTEXITCODE -eq 0) {
            return @{ Status = "PASS"; Message = "Bucket exists: $bucket" }
        } else {
            return @{ Status = "FAIL"; Message = "Bucket not found: $bucket" }
        }
    } catch {
        return @{ Status = "FAIL"; Message = $_.Exception.Message }
    }
}

# Test 2: AES-256 Encryption Enabled
Test-Requirement -Name "AES-256 Server-Side Encryption" -Requirement "6.6" -Test {
    try {
        $encryption = aws s3api get-bucket-encryption `
            --bucket $bucket `
            --region $Region `
            --output json 2>&1 | ConvertFrom-Json
        
        $sseAlgorithm = $encryption.ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault.SSEAlgorithm
        
        if ($sseAlgorithm -eq "AES256") {
            return @{ Status = "PASS"; Message = "AES-256 encryption enabled" }
        } else {
            return @{ Status = "FAIL"; Message = "Encryption algorithm: $sseAlgorithm (expected AES256)" }
        }
    } catch {
        return @{ Status = "FAIL"; Message = "Encryption not configured" }
    }
}

# Test 3: Public Access Blocked
Test-Requirement -Name "Block All Public Access" -Requirement "Design" -Test {
    try {
        $publicAccess = aws s3api get-public-access-block `
            --bucket $bucket `
            --region $Region `
            --output json 2>&1 | ConvertFrom-Json
        
        $config = $publicAccess.PublicAccessBlockConfiguration
        
        if ($config.BlockPublicAcls -and $config.BlockPublicPolicy -and 
            $config.IgnorePublicAcls -and $config.RestrictPublicBuckets) {
            return @{ Status = "PASS"; Message = "All 4 public access blocks enabled" }
        } else {
            $enabled = @($config.BlockPublicAcls, $config.BlockPublicPolicy, 
                         $config.IgnorePublicAcls, $config.RestrictPublicBuckets) | Where-Object { $_ } | Measure-Object
            return @{ Status = "FAIL"; Message = "Only $($enabled.Count)/4 public access blocks enabled" }
        }
    } catch {
        return @{ Status = "FAIL"; Message = "Public access block not configured" }
    }
}

# Test 4: CORS Configuration
Test-Requirement -Name "CORS for Signed URL Access" -Requirement "Design" -Test {
    try {
        $cors = aws s3api get-bucket-cors `
            --bucket $bucket `
            --region $Region `
            --output json 2>&1 | ConvertFrom-Json
        
        $corsRule = $cors.CORSRules[0]
        
        if ($corsRule.AllowedMethods -contains "GET" -and $corsRule.AllowedMethods -contains "HEAD") {
            return @{ Status = "PASS"; Message = "CORS configured for GET and HEAD methods" }
        } else {
            return @{ Status = "WARN"; Message = "CORS methods: $($corsRule.AllowedMethods -join ', ')" }
        }
    } catch {
        return @{ Status = "FAIL"; Message = "CORS not configured" }
    }
}

# Test 5: Lifecycle Policy (7-day retention)
Test-Requirement -Name "7-Day Auto-Deletion Lifecycle Policy" -Requirement "6.7, Design" -Test {
    try {
        $lifecycle = aws s3api get-bucket-lifecycle-configuration `
            --bucket $bucket `
            --region $Region `
            --output json 2>&1 | ConvertFrom-Json
        
        $rule = $lifecycle.Rules[0]
        
        if ($rule.Status -eq "Enabled") {
            $days = $rule.Expiration.Days
            if ($days -eq 7) {
                return @{ Status = "PASS"; Message = "Lifecycle policy enabled: $days days retention" }
            } else {
                return @{ Status = "WARN"; Message = "Lifecycle policy: $days days (expected 7)" }
            }
        } else {
            return @{ Status = "FAIL"; Message = "Lifecycle policy not enabled" }
        }
    } catch {
        return @{ Status = "FAIL"; Message = "Lifecycle policy not configured" }
    }
}

# Test 6: Lifecycle Policy Prefix
Test-Requirement -Name "Lifecycle Policy Applies to Correct Prefix" -Requirement "Design" -Test {
    try {
        $lifecycle = aws s3api get-bucket-lifecycle-configuration `
            --bucket $bucket `
            --region $Region `
            --output json 2>&1 | ConvertFrom-Json
        
        $rule = $lifecycle.Rules[0]
        $prefix = $rule.Prefix
        
        if ($prefix -eq "evidence/" -or $prefix -eq "video-evidence/") {
            return @{ Status = "PASS"; Message = "Lifecycle policy prefix: $prefix" }
        } else {
            return @{ Status = "WARN"; Message = "Lifecycle policy prefix: $prefix (expected evidence/ or video-evidence/)" }
        }
    } catch {
        return @{ Status = "FAIL"; Message = "Lifecycle policy prefix not configured" }
    }
}

# Test 7: Bucket Policy - Deny Public ACLs
Test-Requirement -Name "Bucket Policy Denies Public ACLs" -Requirement "6.2, Design" -Test {
    try {
        $policy = aws s3api get-bucket-policy `
            --bucket $bucket `
            --region $Region `
            --output json 2>&1 | ConvertFrom-Json
        
        $policyDoc = $policy.Policy | ConvertFrom-Json
        
        $denyPublicAcl = $policyDoc.Statement | Where-Object { 
            $_.Sid -eq "DenyPublicACLs" -and $_.Effect -eq "Deny" 
        }
        
        if ($denyPublicAcl) {
            return @{ Status = "PASS"; Message = "Public ACLs explicitly denied" }
        } else {
            return @{ Status = "WARN"; Message = "DenyPublicACLs policy statement not found" }
        }
    } catch {
        return @{ Status = "FAIL"; Message = "Bucket policy not configured" }
    }
}

# Test 8: Bucket Policy - Force TLS
Test-Requirement -Name "Bucket Policy Requires TLS/HTTPS" -Requirement "Design" -Test {
    try {
        $policy = aws s3api get-bucket-policy `
            --bucket $bucket `
            --region $Region `
            --output json 2>&1 | ConvertFrom-Json
        
        $policyDoc = $policy.Policy | ConvertFrom-Json
        
        $forceTls = $policyDoc.Statement | Where-Object { 
            $_.Sid -eq "ForceTLS" -and $_.Effect -eq "Deny" 
        }
        
        if ($forceTls) {
            return @{ Status = "PASS"; Message = "TLS/HTTPS required for all operations" }
        } else {
            return @{ Status = "WARN"; Message = "ForceTLS policy statement not found" }
        }
    } catch {
        return @{ Status = "FAIL"; Message = "Bucket policy not configured" }
    }
}

# Test 9: Bucket Versioning
Test-Requirement -Name "Bucket Versioning Enabled" -Requirement "Design (data protection)" -Test {
    try {
        $versioning = aws s3api get-bucket-versioning `
            --bucket $bucket `
            --region $Region `
            --output json 2>&1 | ConvertFrom-Json
        
        if ($versioning.Status -eq "Enabled") {
            return @{ Status = "PASS"; Message = "Versioning enabled" }
        } else {
            return @{ Status = "WARN"; Message = "Versioning status: $($versioning.Status)" }
        }
    } catch {
        return @{ Status = "FAIL"; Message = "Versioning not configured" }
    }
}

# Test 10: Lambda Function URL Accessible
Test-Requirement -Name "Lambda Function URL Accessible" -Requirement "Integration" -Test {
    try {
        $testPayload = @{
            action = "generate_signed_url"
            s3Key = "test/dummy.mp4"
            expirationMinutes = 20
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri $lambdaUrl -Method POST -Body $testPayload -ContentType "application/json" -ErrorAction Stop
        
        if ($response.status -eq "error" -or $response.status -eq "success") {
            return @{ Status = "PASS"; Message = "Lambda Function URL accessible" }
        } else {
            return @{ Status = "WARN"; Message = "Unexpected response: $($response | ConvertTo-Json -Compress)" }
        }
    } catch {
        return @{ Status = "FAIL"; Message = "Lambda Function URL not accessible: $_" }
    }
}

# Test 11: Lambda Function - Store Video Action
Test-Requirement -Name "Lambda Store Video Action" -Requirement "Integration" -Test {
    try {
        # Create a small test video (base64 encoded dummy data)
        $testVideoData = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("test video data"))
        
        $testPayload = @{
            action = "store_video"
            eventId = "test-event-$(Get-Date -Format 'yyyyMMddHHmmss')"
            videoData = $testVideoData
            frameIndex = 0
            metadata = @{
                confidenceLevel = 0.95
            }
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri $lambdaUrl -Method POST -Body $testPayload -ContentType "application/json" -ErrorAction Stop
        
        if ($response.status -eq "success" -and $response.s3Key) {
            # Clean up test object
            try {
                aws s3 rm "s3://$bucket/$($response.s3Key)" --region $Region 2>&1 | Out-Null
            } catch {}
            
            return @{ Status = "PASS"; Message = "Store video action functional (test object created and deleted)" }
        } else {
            return @{ Status = "FAIL"; Message = "Store video action failed: $($response.error)" }
        }
    } catch {
        return @{ Status = "FAIL"; Message = "Store video action error: $_" }
    }
}

# Test 12: Bucket Isolation (not reusing audio/SMS buckets)
Test-Requirement -Name "Bucket Isolation from Audio/SMS Storage" -Requirement "6.2" -Test {
    if ($bucket -match "emergency-evidence" -or $bucket -match "video-evidence") {
        if ($bucket -notmatch "audio" -and $bucket -notmatch "sms") {
            return @{ Status = "PASS"; Message = "Dedicated video evidence bucket (not reusing audio/SMS)" }
        } else {
            return @{ Status = "WARN"; Message = "Bucket name contains audio/sms: $bucket" }
        }
    } else {
        return @{ Status = "WARN"; Message = "Bucket name pattern unexpected: $bucket" }
    }
}

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Verification Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Tests Passed:  $testsPassed" -ForegroundColor Green
Write-Host "Tests Warning: $testsWarning" -ForegroundColor Yellow
Write-Host "Tests Failed:  $testsFailed" -ForegroundColor Red
Write-Host ""

if ($testsFailed -eq 0 -and $testsWarning -eq 0) {
    Write-Host "✅ All tests passed! S3 configuration is fully compliant." -ForegroundColor Green
} elseif ($testsFailed -eq 0) {
    Write-Host "⚠️  All critical tests passed, but $testsWarning warnings detected." -ForegroundColor Yellow
    Write-Host "   Review warnings above for potential improvements." -ForegroundColor Yellow
} else {
    Write-Host "❌ $testsFailed tests failed. S3 configuration needs attention." -ForegroundColor Red
    Write-Host "   Review failed tests above and redeploy if necessary." -ForegroundColor Red
}

Write-Host ""
Write-Host "Configuration Details:" -ForegroundColor Cyan
Write-Host "  Bucket: $bucket" -ForegroundColor White
Write-Host "  Lambda URL: $lambdaUrl" -ForegroundColor White
Write-Host "  Region: $Region" -ForegroundColor White
Write-Host "  Stack: $StackName" -ForegroundColor White
Write-Host ""

# Exit with appropriate code
if ($testsFailed -gt 0) {
    exit 1
} else {
    exit 0
}
