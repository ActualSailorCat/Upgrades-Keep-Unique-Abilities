-- // Steel and Thunder
-- // Too many issues to iron out at the moment.
/*
INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT 'ABILITY_HOPLITE', 'SAILOR_PUA_HOPLITE_'||UnitType
FROM Units WHERE UnitType IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_ANTI_CAVALRY') AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 1)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 1)));

INSERT OR REPLACE INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId)
SELECT 'SAILOR_PUA_HOPLITE_'||UnitType, 'MODIFIER_SINGLE_UNIT_ATTACH_MODIFIER', 'SAILOR_PLOT_IS_'||UnitType||'_REQUIREMENTS'
FROM Units WHERE UnitType IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_ANTI_CAVALRY') AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 1)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 1)));

INSERT OR REPLACE INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId)
SELECT 'SAILOR_PUA_HOPLITE_'||UnitType'||_NEIGHBOR', 'MODIFIER_UNIT_ADJUST_COMBAT_STRENGTH', NULL
FROM Units WHERE UnitType IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_ANTI_CAVALRY') AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 1)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 1)));

INSERT OR REPLACE INTO ModifierArguments (ModifierId, Name, Value)
SELECT 'SAILOR_PUA_HOPLITE_'||UnitType, 'ModifierId', 'SAILOR_PUA_HOPLITE_'||UnitType'||_NEIGHBOR'
FROM Units WHERE UnitType IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_ANTI_CAVALRY') AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 1)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 1)));

INSERT OR REPLACE INTO ModifierArguments (ModifierId, Name, Value)
SELECT 'SAILOR_PUA_HOPLITE_'||UnitType, 'Amount', 10
FROM Units WHERE UnitType IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_ANTI_CAVALRY') AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 1)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 1)));

INSERT OR REPLACE INTO RequirementSets (RequirementSetId, RequirementSetType)
SELECT 'SAILOR_PLOT_IS_'||UnitType||'_REQUIREMENTS', 'REQUIREMENTSET_TEST_ALL'
FROM Units WHERE UnitType IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_ANTI_CAVALRY') AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 1)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 1)));

INSERT OR REPLACE INTO RequirementSetRequirements (RequirementSetId, RequirementId)
SELECT 'SAILOR_PLOT_IS_'||UnitType||'_REQUIREMENTS', 'SAILOR_REQUIRES_UNIT_NEXT_TO_'||UnitType
FROM Units WHERE UnitType IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_ANTI_CAVALRY') AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 1)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 1)));

INSERT OR REPLACE INTO RequirementSetRequirements (RequirementSetId, RequirementId)
SELECT 'SAILOR_PLOT_IS_'||UnitType||'_REQUIREMENTS', 'SAILOR_PUA_REQUIRES_'||UnitType
FROM Units WHERE UnitType IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_ANTI_CAVALRY') AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 1)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 1)));

INSERT OR REPLACE INTO Requirements (RequirementId, RequirementType)
SELECT 'SAILOR_REQUIRES_UNIT_NEXT_TO_'||UnitType, 'REQUIREMENT_PLOT_ADJACENT_FRIENDLY_UNIT_TYPE_MATCHES'
FROM Units WHERE UnitType IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_ANTI_CAVALRY') AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 1)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 1)));

INSERT OR REPLACE INTO Requirements (RequirementId, RequirementType)
SELECT 'SAILOR_PUA_REQUIRES_'||UnitType, 'REQUIREMENT_UNIT_TYPE_MATCHES'
FROM Units WHERE UnitType IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_ANTI_CAVALRY') AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 1)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 1)));

INSERT OR REPLACE INTO RequirementArguments (RequirementId, Name, Value)
SELECT 'SAILOR_REQUIRES_UNIT_NEXT_TO_'||UnitType, 'UnitType', UnitType
FROM Units WHERE UnitType IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_ANTI_CAVALRY') AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 1)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 1)));

INSERT OR REPLACE INTO RequirementArguments (RequirementId, Name, Value)
SELECT 'SAILOR_PUA_REQUIRES_'||UnitType, 'UnitType', UnitType
FROM Units WHERE UnitType IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_ANTI_CAVALRY') AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 1)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 1)));
*/