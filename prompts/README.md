# Gemini 3 Prompt Engineering

## Overview

This directory contains all prompts used to interact with Google Gemini 3. All prompts are **original work** created specifically for this hackathon project.

## Prompt Design Philosophy

### 1. Structured Output

All prompts request JSON-formatted responses for reliable parsing:

```json
{
  "risk_level": "HIGH|MEDIUM|LOW|NONE",
  "confidence": 0.0-1.0,
  "reasoning": "explanation",
  "indicators": ["list", "of", "signals"],
  "recommended_action": "action"
}
```

### 2. Multimodal Context

Prompts leverage Gemini 3's multimodal capabilities:
- Text transcripts
- Audio characteristics (tone, urgency, background sounds)
- Visual context (if images provided)

### 3. Explainability

Every risk assessment includes reasoning to enable:
- Human review and validation
- System debugging and improvement
- Compliance and audit trails

## Prompt Files

### gemini_reasoning_prompt.md

**Purpose**: Primary distress detection and risk assessment

**Input**: Multimodal emergency context
**Output**: Structured risk assessment with reasoning

### gemini_multimodal_prompt.md

**Purpose**: Analyze audio and visual cues alongside text

**Input**: Text + audio features + optional images
**Output**: Comprehensive multimodal analysis

### output_schema.json

**Purpose**: Define expected JSON response structure

**Usage**: Validate Gemini 3 responses for consistency

## Prompt Engineering Best Practices

### 1. Clear Instructions

```
You are an emergency detection AI analyzing potential distress situations.
Your goal is to identify genuine emergencies while minimizing false alarms.
```

### 2. Context Provision

```
Context:
- User location: [GPS coordinates]
- Time of day: [timestamp]
- User profile: [age, gender, risk factors]
- Historical patterns: [baseline behavior]
```

### 3. Few-Shot Examples

```
Example 1 (TRUE EMERGENCY):
Input: "Help! Someone is following me. I'm scared."
Output: {"risk_level": "HIGH", "confidence": 0.95, ...}

Example 2 (FALSE ALARM):
Input: "This movie is killing me, so scary!"
Output: {"risk_level": "NONE", "confidence": 0.90, ...}
```

### 4. Safety Guidelines

```
CRITICAL SAFETY RULES:
- When in doubt, escalate (false positive better than false negative)
- Consider cultural and linguistic variations
- Account for indirect distress signals
- Recognize sarcasm and figurative language
```

## Prompt Versioning

All prompts are versioned for tracking and rollback:

- `v1.0` - Initial hackathon implementation
- `v1.1` - Improved multimodal handling
- `v1.2` - Enhanced reasoning explanations

## Testing Prompts

See [../tests/prompt_tests.py](../tests/prompt_tests.py) for prompt validation tests.

## Compliance Note

All prompts in this directory are **original work** created during the Google Gemini 3 Hackathon. No prompts from previous systems (ERNIE, Baidu, or other platforms) have been copied or adapted.
