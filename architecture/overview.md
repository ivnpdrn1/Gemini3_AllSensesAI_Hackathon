# AllSensesAI Architecture Overview

## System Design Principles

### 1. Gemini-First Architecture

**Gemini 3 is the irreplaceable intelligence core** of this system. All reasoning, understanding, and risk assessment flows through Gemini 3.

```
Input → Gemini 3 (Intelligence) → KIRO (Orchestration) → AWS (Execution)
```

### 2. Separation of Concerns

| Layer | Responsibility | Technology |
|-------|---------------|------------|
| **Intelligence** | Multimodal understanding, reasoning, risk assessment | Google Gemini 3 |
| **Orchestration** | Decision logic, scoring, workflow management | KIRO |
| **Execution** | Messaging, persistence, scaling | AWS Services |

### 3. Why Gemini 3 is Essential

The system **cannot function** without Gemini 3 because:

1. **Multimodal Understanding**: Gemini 3 processes text, audio, and images together to understand context
2. **Nuanced Reasoning**: Detects subtle distress signals that rule-based systems miss
3. **Contextual Adaptation**: Understands cultural, linguistic, and situational variations
4. **Explainability**: Provides reasoning for risk classifications
5. **Continuous Learning**: Adapts to new patterns and edge cases

## High-Level Data Flow

```
┌─────────────────┐
│  User Input     │
│ (Text/Audio/Img)│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Gemini 3 API   │
│  - Analyze      │
│  - Reason       │
│  - Classify     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  KIRO Engine    │
│  - Score        │
│  - Decide       │
│  - Route        │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  AWS Services   │
│  - SNS Alert    │
│  - Lambda Exec  │
│  - DynamoDB Log │
└─────────────────┘
```

## Component Architecture

### Gemini 3 Integration Layer

**Purpose**: Interface with Google Gemini 3 API for intelligence operations

**Responsibilities**:
- Multimodal input preparation
- Prompt engineering and management
- API communication
- Response parsing and validation
- Error handling and retries

**Key Files**:
- `src/gemini/client.py` - Gemini 3 API client
- `src/gemini/multimodal.py` - Multimodal input handler
- `src/gemini/prompts.py` - Prompt template manager

### KIRO Orchestration Layer

**Purpose**: Decision logic and workflow management

**Responsibilities**:
- Risk score calculation
- Threshold evaluation
- Alert routing decisions
- State management
- Audit logging

**Key Files**:
- `src/kiro/orchestrator.py` - Main orchestration engine
- `src/kiro/scoring.py` - Risk scoring logic
- `src/kiro/rules.py` - Decision rules

### AWS Execution Layer

**Purpose**: Execute actions and manage infrastructure

**Responsibilities**:
- Emergency notifications (SNS)
- Serverless execution (Lambda)
- Data persistence (DynamoDB)
- File storage (S3)
- API Gateway

**Key Files**:
- `src/aws/lambda_handler.py` - Lambda entry point
- `src/aws/sns_client.py` - SNS messaging
- `src/aws/dynamodb_client.py` - Data persistence

## Deployment Architecture

```
┌──────────────────────────────────────────┐
│           CloudFront CDN                 │
│         (Static Frontend)                │
└──────────────┬───────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────┐
│         API Gateway                      │
│    (REST API Endpoints)                  │
└──────────────┬───────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────┐
│         AWS Lambda                       │
│  ┌────────────────────────────────────┐  │
│  │  Gemini 3 Client                   │  │
│  │  KIRO Orchestrator                 │  │
│  │  AWS Service Integrations          │  │
│  └────────────────────────────────────┘  │
└──────────────┬───────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────┐
│    External Services                     │
│  - Google Gemini 3 API (Vertex AI)       │
│  - AWS SNS (Notifications)               │
│  - AWS DynamoDB (State)                  │
└──────────────────────────────────────────┘
```

## Security Considerations

1. **API Key Management**: Gemini 3 API keys stored in AWS Secrets Manager
2. **Data Encryption**: All data encrypted at rest and in transit
3. **Access Control**: IAM roles with least privilege
4. **Audit Logging**: All Gemini 3 calls logged for compliance
5. **Rate Limiting**: Prevent API abuse

## Scalability

- **Horizontal**: Lambda auto-scales based on load
- **Vertical**: Gemini 3 API handles concurrent requests
- **Caching**: Reduce redundant Gemini 3 calls
- **Async Processing**: Queue-based for non-critical operations

## Monitoring

- **Gemini 3 Metrics**: API latency, error rates, token usage
- **KIRO Metrics**: Decision accuracy, false positive rate
- **AWS Metrics**: Lambda duration, SNS delivery, DynamoDB throughput
- **End-to-End**: Alert response time, user satisfaction

## Next Steps

1. Review [prompts/README.md](../prompts/README.md) for Gemini 3 prompt engineering
2. See [src/gemini/README.md](../src/gemini/README.md) for integration details
3. Check [compliance/gemini_hackathon_notes.md](../compliance/gemini_hackathon_notes.md) for hackathon compliance
