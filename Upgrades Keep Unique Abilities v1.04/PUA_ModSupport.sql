-- ///////////////////////////////////////////////////////
-- // Steel and Thunder
-- ///////////////////////////////////////////////////////
-- // Abilities
-- Units with abilities attached to other units. RIP
-- UNIT_MONGOLIAN_HUI_HUI_PAO
-- UNIT_NORWEGIAN_ULFHEDNAR
-- UNIT_KHMER_WAR_CANOE
-- UNIT_MALI_SOFA
-- UNIT_PERSIAN_WARSHIP
-- UNIT_CHINESE_SHIGONG
-- UNIT_KONGO_MEDICINE_MAN
-- UNIT_AZTEC_WARRIOR_PRIEST

-- UNIT_ROMAN_EQUITE
INSERT OR REPLACE INTO RequirementSetRequirements (RequirementSetId, RequirementId)
SELECT 'PLOT_IS_NEXT_TO_ROMAN_EARLY_MELEE_REQUIREMENTS', 'SAILOR_PUA_ADJACENT_'||UnitType
FROM Units WHERE UnitType IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_MELEE' AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 1)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 1))))
AND EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_ROMAN_EQUITE');

INSERT OR REPLACE INTO Requirements (RequirementId, RequirementType)
SELECT 'SAILOR_PUA_ADJACENT_'||UnitType, 'REQUIREMENT_PLOT_ADJACENT_FRIENDLY_UNIT_TYPE_MATCHES'
FROM Units WHERE UnitType IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_MELEE' AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 1)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 1))))
AND EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_ROMAN_EQUITE');

INSERT OR REPLACE INTO RequirementArguments (RequirementId, Name, Value)
SELECT 'SAILOR_PUA_ADJACENT_'||UnitType, 'UnitType', UnitType
FROM Units WHERE UnitType IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_MELEE' AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 1)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 1))))
AND EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_ROMAN_EQUITE');

-- UNIT_ENGLISH_LONGBOWMAN
INSERT OR REPLACE INTO RequirementSetRequirements (RequirementSetId, RequirementId)
SELECT 'PLOT_IS_NEXT_TO_LONGBOWMAN_REQUIREMENTS', 'SAILOR_PUA_ADJACENT_'||UnitType
FROM Units WHERE UnitType IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_RANGED' AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2))))
AND EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_ENGLISH_LONGBOWMAN');

INSERT OR REPLACE INTO Requirements (RequirementId, RequirementType)
SELECT 'SAILOR_PUA_ADJACENT_'||UnitType, 'REQUIREMENT_PLOT_ADJACENT_FRIENDLY_UNIT_TYPE_MATCHES'
FROM Units WHERE UnitType IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_RANGED' AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2))))
AND EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_ENGLISH_LONGBOWMAN');

INSERT OR REPLACE INTO RequirementArguments (RequirementId, Name, Value)
SELECT 'SAILOR_PUA_ADJACENT_'||UnitType, 'UnitType', UnitType
FROM Units WHERE UnitType IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_RANGED' AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2))))
AND EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_ENGLISH_LONGBOWMAN');

-- UNIT_ZULU_ASSEGAI
INSERT OR REPLACE INTO RequirementSetRequirements (RequirementSetId, RequirementId)
SELECT 'PLOT_IS_NEXT_TO_ASSEGAI_REQUIREMENTS', 'SAILOR_PUA_ADJACENT_'||UnitType
FROM Units WHERE UnitType IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_RANGED' AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 0)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 0))))
AND EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_ZULU_ASSEGAI');

INSERT OR REPLACE INTO Requirements (RequirementId, RequirementType)
SELECT 'SAILOR_PUA_ADJACENT_'||UnitType, 'REQUIREMENT_PLOT_ADJACENT_FRIENDLY_UNIT_TYPE_MATCHES'
FROM Units WHERE UnitType IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_RANGED' AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 0)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 0))))
AND EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_ZULU_ASSEGAI');

INSERT OR REPLACE INTO RequirementArguments (RequirementId, Name, Value)
SELECT 'SAILOR_PUA_ADJACENT_'||UnitType, 'UnitType', UnitType
FROM Units WHERE UnitType IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_RANGED' AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 0)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 0))))
AND EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_ZULU_ASSEGAI');

-- UNIT_ENGLISH_SHIP_OF_THE_LINE
UPDATE RequirementSets SET RequirementSetType = 'REQUIREMENTSET_TEST_ANY' WHERE RequirementSetId = 'ADJACENT_FRIENDLY_NAVAL_RANGED_REQUIREMENTS';
INSERT OR REPLACE INTO RequirementSetRequirements (RequirementSetId, RequirementId)
SELECT 'ADJACENT_FRIENDLY_NAVAL_RANGED_REQUIREMENTS', 'SAILOR_PUA_ADJACENT_'||UnitType
FROM Units WHERE UnitType IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_NAVAL_RANGED' AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 3)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 3))))
AND EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_ENGLISH_SHIP_OF_THE_LINE');

INSERT OR REPLACE INTO Requirements (RequirementId, RequirementType)
SELECT 'SAILOR_PUA_ADJACENT_'||UnitType, 'REQUIREMENT_PLOT_ADJACENT_FRIENDLY_UNIT_TYPE_MATCHES'
FROM Units WHERE UnitType IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_NAVAL_RANGED' AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 3)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 3))))
AND EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_ENGLISH_SHIP_OF_THE_LINE');

INSERT OR REPLACE INTO RequirementArguments (RequirementId, Name, Value)
SELECT 'SAILOR_PUA_ADJACENT_'||UnitType, 'UnitType', UnitType
FROM Units WHERE UnitType IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_NAVAL_RANGED' AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 3)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 3))))
AND EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_ENGLISH_SHIP_OF_THE_LINE');

-- // Units Table (Where replaces nothing.)
-- // Comparing each unit is painful without a reference wiki.
-- Units that don't need addressing:
-- UNIT_JAPANESE_SOHEI
-- UNIT_KONGO_MEDICINE_MAN
-- UNIT_CHINESE_SHIGONG
-- UNIT_NORWEGIAN_ULFHEDNAR
-- UNIT_PERSIAN_CATAPHRACT
-- UNIT_NUBIAN_AFRICAN_FOREST_ELEPHANT
-- UNIT_INDONESIAN_KRIS_SWORDSMAN
-- UNIT_SCOTTISH_GALLOWGLASS
-- UNIT_ELEANOR_TEMPLAR
-- UNIT_MAYAN_HOLKAN
-- UNIT_COLOMBIAN_BRITISH_LEGION
-- UNIT_ETHIOPIAN_MEHAL_SEFARI

-- UNIT_ARABIAN_CAMEL_ARCHER
INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT 'ABILITY_CAMEL_ARCHER', '2_SAILOR_PUA_MOVEMENT'
WHERE EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_ARABIAN_CAMEL_ARCHER');

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT 'ABILITY_CAMEL_ARCHER', '2_SAILOR_PUA_STR_RNGD'
WHERE EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_ARABIAN_CAMEL_ARCHER');

-- UNIT_INDIAN_SEPOY
-- Replaces nothing at the moment unless Steel & Thunder core is active.
-- Shouldn't account for that since the fix is on Deliverator's end.

-- UNIT_MONGOLIAN_HUI_HUI_PAO
INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT 'ABILITY_GRANT_HUI_HUI_PAO_BONUS', '5_SAILOR_PUA_STR_BOMB'
WHERE EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_MONGOLIAN_HUI_HUI_PAO');

-- UNIT_BYZANTINE_VARANGIAN_GUARD
INSERT OR REPLACE INTO Types (Type, Kind) 
SELECT 'ABILITY_SAILOR_VARANGIAN', 'KIND_ABILITY'
WHERE EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_BYZANTINE_VARANGIAN_GUARD');

INSERT OR REPLACE INTO UnitAbilities (UnitAbilityType, Inactive)
SELECT 'ABILITY_SAILOR_VARANGIAN', 1
WHERE EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_BYZANTINE_VARANGIAN_GUARD');

INSERT OR REPLACE INTO TypeTags (Type, Tag)
SELECT 'ABILITY_SAILOR_VARANGIAN', 'CLASS_BYZANTINE_VARANGIAN_GUARD'
WHERE EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_BYZANTINE_VARANGIAN_GUARD');

INSERT OR REPLACE INTO TypeTags (Type, Tag)
SELECT UnitType AS Type, 'CLASS_BYZANTINE_VARANGIAN_GUARD'
FROM Units WHERE UnitType IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_MELEE' AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2))))
AND EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_BYZANTINE_VARANGIAN_GUARD');

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT 'ABILITY_SAILOR_VARANGIAN', '5_SAILOR_PUA_STR_VARANGIAN'
WHERE EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_BYZANTINE_VARANGIAN_GUARD');

INSERT OR REPLACE INTO GameModifiers (ModifierId)
SELECT 'SAILOR_UNIT_BYZANTINE_VARANGIAN_GUARD_GRANT_ABILITY'
WHERE EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_BYZANTINE_VARANGIAN_GUARD');

INSERT OR REPLACE INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId)
SELECT 'SAILOR_UNIT_BYZANTINE_VARANGIAN_GUARD_GRANT_ABILITY', 'MODIFIER_ALL_UNITS_GRANT_ABILITY', 'SAILOR_PUA_REQUIRES_IS_VARANGIAN'
WHERE EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_BYZANTINE_VARANGIAN_GUARD');

INSERT OR REPLACE INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId)
SELECT '5_SAILOR_PUA_STR_VARANGIAN', 'MODIFIER_UNIT_ADJUST_COMBAT_STRENGTH', 'SAILOR_PUA_REQUIRES_NOT_VARANGIAN'
WHERE EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_BYZANTINE_VARANGIAN_GUARD');

INSERT OR REPLACE INTO ModifierArguments (ModifierId, Name, Value)
SELECT '5_SAILOR_PUA_STR_VARANGIAN', 'Amount', 5
WHERE EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_BYZANTINE_VARANGIAN_GUARD');

INSERT OR REPLACE INTO ModifierArguments (ModifierId, Name, Value)
SELECT 'SAILOR_UNIT_BYZANTINE_VARANGIAN_GUARD_GRANT_ABILITY', 'AbilityType', 'ABILITY_SAILOR_VARANGIAN'
WHERE EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_BYZANTINE_VARANGIAN_GUARD');

INSERT OR REPLACE INTO RequirementSets (RequirementSetId, RequirementSetType)
SELECT 'SAILOR_PUA_REQUIRES_IS_VARANGIAN', 'REQUIREMENTSET_TEST_ALL'
WHERE EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_BYZANTINE_VARANGIAN_GUARD');

INSERT OR REPLACE INTO RequirementSets (RequirementSetId, RequirementSetType)
SELECT 'SAILOR_PUA_REQUIRES_NOT_VARANGIAN', 'REQUIREMENTSET_TEST_ALL'
WHERE EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_BYZANTINE_VARANGIAN_GUARD');

INSERT OR REPLACE INTO RequirementSetRequirements (RequirementSetId, RequirementId)
SELECT 'SAILOR_PUA_REQUIRES_IS_VARANGIAN', 'SAILOR_PUA_IS_VARANGIAN'
WHERE EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_BYZANTINE_VARANGIAN_GUARD');

INSERT OR REPLACE INTO RequirementSetRequirements (RequirementSetId, RequirementId)
SELECT 'SAILOR_PUA_REQUIRES_NOT_VARANGIAN', 'SAILOR_PUA_NOT_VARANGIAN'
WHERE EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_BYZANTINE_VARANGIAN_GUARD');

INSERT OR REPLACE INTO Requirements (RequirementId, RequirementType)
SELECT 'SAILOR_PUA_IS_VARANGIAN', 'REQUIREMENT_UNIT_TYPE_MATCHES'
WHERE EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_BYZANTINE_VARANGIAN_GUARD');

INSERT OR REPLACE INTO Requirements (RequirementId, RequirementType, Inverse)
SELECT 'SAILOR_PUA_NOT_VARANGIAN', 'REQUIREMENT_UNIT_TYPE_MATCHES', 1
WHERE EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_BYZANTINE_VARANGIAN_GUARD');

INSERT OR REPLACE INTO RequirementArguments (RequirementId, Name, Value)
SELECT 'SAILOR_PUA_IS_VARANGIAN', 'UnitType', 'UNIT_BYZANTINE_VARANGIAN_GUARD'
WHERE EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_BYZANTINE_VARANGIAN_GUARD');

INSERT OR REPLACE INTO RequirementArguments (RequirementId, Name, Value)
SELECT 'SAILOR_PUA_NOT_VARANGIAN', 'UnitType', 'UNIT_BYZANTINE_VARANGIAN_GUARD'
WHERE EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_BYZANTINE_VARANGIAN_GUARD');

INSERT OR REPLACE INTO ModifierStrings (ModifierId, Context, Text)
SELECT '5_SAILOR_PUA_STR_VARANGIAN', 'Preview', 'LOC_ABILITY_SAILOR_VARANGIAN_PREVIEW_TEXT'
WHERE EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_BYZANTINE_VARANGIAN_GUARD');

-- ///////////////////////////////////////////////////////
-- // CIVITAS
-- ///////////////////////////////////////////////////////
-- Supported: Berber Arer Warrior, Seljuq Sarbaz, Indonesian Cetbang
-- Malaysian Lancaran & Pesilat, Norman Man-At-Arms, Filipino Katipunero
-- Romanian Vanatori & Calarasi, Seleucid Elephantarchia, Songhai Bari Koy
-- Taino Macana, Swiss Reislaufer
-- Satisfactory: UNIT_CVS_ASWAR Aswar 
-- Partial: Armenian Ayrudzi (Lua)

-- // Abilities
-- Units with abilities attached to other units. RIP
-- UNIT_CVS_AKKAD_UU Nas Qasti
-- UNIT_CVS_SELEUCID_UU Seleucid Argyraspides

-- UNIT_CVS_WILLIAM_UU Norman Familia Regis
/*UPDATE Requirements SET RequirementType = 'REQUIREMENT_UNIT_HAS_ABILITY' WHERE RequirementId = 'REQ_CVS_WILLIAM_UU_IS_UNIQUE'
AND EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_CVS_WILLIAM_UU');
UPDATE RequirementArguments SET Name = 'UnitAbilityType', Value = 'ABILITY_CVS_WILLIAM_UU' WHERE RequirementId = 'REQ_CVS_WILLIAM_UU_IS_UNIQUE'
AND EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_CVS_WILLIAM_UU');*/

-- ///////////////////////////////////////////////////////
-- // Misc
-- ///////////////////////////////////////////////////////
-- // Leugi
-- Supported: Brazilian Pracinha

-- // Merrick
-- Supported: Hittite Ansukurra

-- // SailorCat
-- Supported: Atelier Puni

-- // SeelingCat
-- Supported: Bilqis Qayl
-- Partial: Tongva Ti'aat (Lua)

-- // TCS Kingdom of Jerusalem // Crusader supported.
