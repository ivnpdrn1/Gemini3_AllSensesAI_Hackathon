"""
KIRO Risk Scoring Logic
Original work created for Google Gemini 3 Hackathon 2026
"""

import logging
from typing import Dict, Any

logger = logging.getLogger(__name__)


class RiskScorer:
    """
    Calculates risk scores based on Gemini 3 assessments.
    
    KIRO's role is to translate Gemini 3's intelligence into
    actionable scores and thresholds.
    """
    
    def __init__(self):
        """Initialize risk scorer with thresholds."""
        self.thresholds = {
            'CRITICAL': 0.90,
            'HIGH': 0.75,
            'MEDIUM': 0.50,
            'LOW': 0.25
        }
        logger.info("Initialized RiskScorer")
    
    def calculate_score(
        self,
        gemini_response: Dict[str, Any],
        context: Dict[str, Any]
    ) -> float:
        """
        Calculate overall risk score.
        
        Args:
            gemini_response: Risk assessment from Gemini 3
            context: Additional context
            
        Returns:
            Risk score (0.0 to 1.0)
        """
        # Base score from Gemini 3
        base_score = self._risk_level_to_score(gemini_response['risk_level'])
        confidence = gemini_response['confidence']
        
        # Confidence-weighted score
        weighted_score = base_score * confidence
        
        # Context adjustments
        context_multiplier = self._calculate_context_multiplier(context)
        final_score = weighted_score * context_multiplier
        
        # Clamp to [0.0, 1.0]
        final_score = max(0.0, min(1.0, final_score))
        
        logger.info(f"Risk score: {final_score:.3f} (base={base_score:.3f}, confidence={confidence:.3f}, context={context_multiplier:.3f})")
        
        return final_score
    
    def _risk_level_to_score(self, risk_level: str) -> float:
        """Convert risk level to numerical score."""
        level_scores = {
            'CRITICAL': 1.0,
            'HIGH': 0.8,
            'MEDIUM': 0.5,
            'LOW': 0.2,
            'NONE': 0.0
        }
        return level_scores.get(risk_level, 0.5)
    
    def _calculate_context_multiplier(self, context: Dict[str, Any]) -> float:
        """
        Calculate context-based score multiplier.
        
        Args:
            context: Contextual information
            
        Returns:
            Multiplier (0.5 to 1.5)
        """
        multiplier = 1.0
        
        # Time-based adjustment
        if 'timestamp' in context:
            # TODO: Check if late night (higher risk)
            pass
        
        # Location-based adjustment
        if 'location' in context:
            # TODO: Check if high-risk area
            pass
        
        # User profile adjustment
        if 'user_profile' in context:
            profile = context['user_profile']
            
            # Vulnerable populations
            if profile.get('age', 100) < 18:
                multiplier *= 1.2  # Minors get higher priority
            
            if profile.get('vulnerable', False):
                multiplier *= 1.3  # Known vulnerable individuals
        
        # Clamp multiplier
        return max(0.5, min(1.5, multiplier))
    
    def should_alert(self, score: float, risk_level: str) -> bool:
        """
        Determine if alert should be triggered.
        
        Args:
            score: Calculated risk score
            risk_level: Gemini 3 risk level
            
        Returns:
            True if alert should be sent
        """
        # Always alert on CRITICAL
        if risk_level == 'CRITICAL':
            return True
        
        # Alert on HIGH with sufficient confidence
        if risk_level == 'HIGH' and score >= self.thresholds['HIGH']:
            return True
        
        # Alert on MEDIUM with very high confidence
        if risk_level == 'MEDIUM' and score >= self.thresholds['CRITICAL']:
            return True
        
        return False
    
    def get_alert_priority(self, risk_level: str, score: float) -> str:
        """
        Determine alert priority level.
        
        Args:
            risk_level: Gemini 3 risk level
            score: Calculated risk score
            
        Returns:
            Priority level (IMMEDIATE, URGENT, STANDARD)
        """
        if risk_level == 'CRITICAL' or score >= 0.95:
            return 'IMMEDIATE'
        elif risk_level == 'HIGH' or score >= 0.75:
            return 'URGENT'
        else:
            return 'STANDARD'


def create_scorer() -> RiskScorer:
    """
    Factory function to create risk scorer.
    
    Returns:
        Initialized RiskScorer instance
    """
    return RiskScorer()
