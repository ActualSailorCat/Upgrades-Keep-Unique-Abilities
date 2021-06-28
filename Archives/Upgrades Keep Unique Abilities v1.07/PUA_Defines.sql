-- ///////////////////////////////////////////////////////
-- // Ability handling, allocation, and reallocation.
-- // I hated each and every second of this.
-- ///////////////////////////////////////////////////////

-- // Gather abilities that apply only to uniques.
CREATE TABLE IF NOT EXISTS Sailor_TEMP_Abilities (UnitAbilityType text default null);

INSERT INTO Sailor_TEMP_Abilities (UnitAbilityType)
SELECT DISTINCT Type FROM TypeTags WHERE Type IN (SELECT UnitAbilityType FROM UnitAbilities WHERE Inactive = 0)
AND Tag IN (SELECT Tag FROM TypeTags WHERE Type IN
(SELECT UnitType FROM Units WHERE TraitType IS NOT NULL)
GROUP BY Tag HAVING COUNT(*) = 1)
AND Type NOT LIKE '%SAILOR_WATCH%' AND Type NOT LIKE '%SAILOR_GOODY%' AND Type NOT LIKE '%IGNORE_ZOC%'
AND Tag NOT IN ('CLASS_ALL_UNITS', 'CLASS_ALL_COMBAT_UNITS', 'CLASS_ALL_ERAS', 'CLASS_LANDCIVILIAN', 'CLASS_RECON', 'CLASS_BUILDER', 'CLASS_MELEE', 'CLASS_RANGED', 'CLASS_SIEGE', 'CLASS_HEAVY_CAVALRY', 'CLASS_LIGHT_CAVALRY', 'CLASS_RANGED_CAVALRY', 'CLASS_ANTI_CAVALRY', 'CLASS_HEAVY_CHARIOT', 'CLASS_LIGHT_CHARIOT', 'CLASS_BATTERING_RAM', 'CLASS_NAVAL_MELEE', 'CLASS_NAVAL_RANGED', 'CLASS_NAVAL_RAIDER', 'CLASS_NAVAL_CARRIER', 'CLASS_SIEGE_TOWER', 'CLASS_MEDIC', 'CLASS_TRADER', 'CLASS_RELIGIOUS', 'CLASS_INQUISITOR', 'CLASS_MISSIONARY', 'CLASS_RELIGIOUS_ALL', 'CLASS_RELIGIOUS_SPREAD', 'CLASS_WARRIOR_MONK', 'CLASS_OBSERVATION', 'CLASS_FORWARD_OBSERVER', 'CLASS_AIRCRAFT', 'CLASS_AIR_BOMBER', 'CLASS_AIR_FIGHTER', 'CLASS_ARCHAEOLOGIST', 'CLASS_STEALTH', 'CLASS_REVEAL_STEALTH', 'CLASS_SPY', 'CLASS_ANTI_AIR', 'CLASS_HELICOPTER', 'CLASS_SUPPORT', 'CLASS_SIEGE_SETUP', 'CLASS_MOBILE_RANGED', 'CLASS_SNIPER', 'CLASS_DRONE', 'CLASS_TARGETTING_ASSIST', 'CLASS_FIELD_SETUP', 'CLASS_LOGISTIC_MOVEMENT', 'CLASS_SETTLER', 'CLASS_GURU', 'CLASS_ROCK_BAND', 'CLASS_GIANT_DEATH_ROBOT', 'CLASS_SOOTHSAYER');

-- // Gather uniques to which the above abilities belong.
CREATE TABLE IF NOT EXISTS Sailor_TEMP_Units (UnitType text default null);

INSERT INTO Sailor_TEMP_Units (UnitType) SELECT DISTINCT Type FROM TypeTags WHERE Type IN (SELECT UnitType FROM Units WHERE TraitType IS NOT NULL)
AND Tag IN (SELECT Tag FROM TypeTags WHERE Type IN (SELECT UnitAbilityType FROM Sailor_TEMP_Abilities));

-- // Add empty abilities for unique units that have none. To be used later.
INSERT OR REPLACE INTO Types (Type, Kind) SELECT 'ABILITY_'||UnitType||'_SAILOR', 'KIND_ABILITY' FROM Units WHERE TraitType IS NOT NULL AND UnitType NOT IN (SELECT UnitType FROM Sailor_TEMP_Units);
INSERT OR REPLACE INTO Tags (Tag, Vocabulary) SELECT 'CLASS_'||UnitType||'_SAILOR', 'ABILITY_CLASS' FROM Units WHERE TraitType IS NOT NULL AND UnitType NOT IN (SELECT UnitType FROM Sailor_TEMP_Units);
INSERT OR REPLACE INTO UnitAbilities (UnitAbilityType, Inactive, Permanent) SELECT 'ABILITY_'||UnitType||'_SAILOR', 0, 1 FROM Units WHERE TraitType IS NOT NULL AND UnitType NOT IN (SELECT UnitType FROM Sailor_TEMP_Units);
INSERT OR REPLACE INTO TypeTags (Type, Tag) SELECT 'ABILITY_'||UnitType||'_SAILOR', 'CLASS_'||UnitType||'_SAILOR' FROM Units WHERE TraitType IS NOT NULL AND UnitType NOT IN (SELECT UnitType FROM Sailor_TEMP_Units);
INSERT OR REPLACE INTO TypeTags (Type, Tag) SELECT UnitType, 'CLASS_'||UnitType||'_SAILOR' FROM Units WHERE TraitType IS NOT NULL AND UnitType NOT IN (SELECT UnitType FROM Sailor_TEMP_Units);
INSERT OR REPLACE INTO Sailor_TEMP_Abilities (UnitAbilityType) SELECT 'ABILITY_'||UnitType||'_SAILOR' FROM Units WHERE TraitType IS NOT NULL AND UnitType NOT IN (SELECT UnitType FROM Sailor_TEMP_Units);
INSERT OR REPLACE INTO Sailor_TEMP_Units (UnitType) SELECT UnitType FROM Units WHERE TraitType IS NOT NULL AND UnitType NOT IN (SELECT UnitType FROM Sailor_TEMP_Units);

-- // Temporary table to hold this stupid select statement.
CREATE TABLE Sailor_TEMP_UnitTags AS
SELECT Type, Tag FROM -- // Only those attached to unique unit abilities.
(SELECT Type, Tag FROM TypeTags WHERE Type IN
(SELECT UnitType FROM Units WHERE TraitType IS NOT NULL)) -- // Unique unit classes.
WHERE Tag IN 
(SELECT Tag FROM TypeTags WHERE Type IN
(SELECT UnitAbilityType FROM Sailor_TEMP_Abilities));

-- // Temporary table to connect units, classes, and abilities.
CREATE TABLE Sailor_TEMP_UnitAbilityTags AS SELECT * FROM Sailor_TEMP_UnitTags;
ALTER TABLE Sailor_TEMP_UnitAbilityTags ADD UnitAbilityType text default null;
UPDATE Sailor_TEMP_UnitAbilityTags SET UnitAbilityType = (SELECT Type FROM TypeTags WHERE Tag = Sailor_TEMP_UnitAbilityTags.Tag AND Type IN (SELECT UnitAbilityType FROM Sailor_TEMP_Abilities));
INSERT OR REPLACE INTO Sailor_TEMP_UnitAbilityTags (Type, Tag, UnitAbilityType) SELECT a.Type, a.Tag, b.UnitAbilityType FROM Sailor_TEMP_UnitAbilityTags a, Sailor_TEMP_Abilities b
WHERE b.UnitAbilityType NOT IN (SELECT UnitAbilityType FROM Sailor_TEMP_UnitAbilityTags) AND b.UnitAbilityType IN (SELECT Type FROM TypeTags WHERE Tag IN (SELECT Tag FROM TypeTags WHERE Type = a.Type));

-- // Insert a provision that grants uniques abilities they'd normally get automatically by virtue of class association.
-- // Removed DISTINCT from these. Seems okay.
INSERT OR REPLACE INTO GameModifiers (ModifierId)
SELECT 'SAILOR_'||Type||'_'||UnitAbilityType
FROM Sailor_TEMP_UnitAbilityTags WHERE UnitAbilityType IN (SELECT Type FROM TypeTags WHERE Tag IN (SELECT Tag FROM TypeTags WHERE Type = Type));

INSERT OR REPLACE INTO Modifiers
				(ModifierId,									ModifierType,						SubjectRequirementSetId)
SELECT 'SAILOR_'||Type||'_'||UnitAbilityType,	'MODIFIER_ALL_UNITS_GRANT_ABILITY',	'SAILOR_PUA_IS_'||Type
FROM Sailor_TEMP_UnitAbilityTags WHERE UnitAbilityType IN (SELECT Type FROM TypeTags WHERE Tag IN (SELECT Tag FROM TypeTags WHERE Type = Type));

INSERT OR REPLACE INTO ModifierArguments
				(ModifierId,									Name,			Value)
SELECT 'SAILOR_'||Type||'_'||UnitAbilityType,	'AbilityType',	UnitAbilityType
FROM Sailor_TEMP_UnitAbilityTags WHERE UnitAbilityType IN (SELECT Type FROM TypeTags WHERE Tag IN (SELECT Tag FROM TypeTags WHERE Type = Type));

/* These are problem queries that run very slow.
-- // Insert a provision that grants uniques abilities they'd normally get automatically by virtue of class association.
INSERT OR REPLACE INTO GameModifiers (ModifierId)
SELECT DISTINCT	'SAILOR_'||a.UnitType||'_'||b.UnitAbilityType
FROM Sailor_TEMP_Units a, Sailor_TEMP_Abilities b WHERE b.UnitAbilityType IN (SELECT Type FROM TypeTags WHERE Tag IN (SELECT Tag FROM TypeTags WHERE Type = a.UnitType));

INSERT OR REPLACE INTO Modifiers
				(ModifierId,									ModifierType,						SubjectRequirementSetId)
SELECT DISTINCT	'SAILOR_'||a.UnitType||'_'||b.UnitAbilityType,	'MODIFIER_ALL_UNITS_GRANT_ABILITY',	'SAILOR_PUA_IS_'||a.UnitType
FROM Sailor_TEMP_Units a, Sailor_TEMP_Abilities b WHERE b.UnitAbilityType IN (SELECT Type FROM TypeTags WHERE Tag IN (SELECT Tag FROM TypeTags WHERE Type = a.UnitType));

INSERT OR REPLACE INTO ModifierArguments
				(ModifierId,									Name,			Value)
SELECT DISTINCT	'SAILOR_'||a.UnitType||'_'||b.UnitAbilityType,	'AbilityType',	b.UnitAbilityType
FROM Sailor_TEMP_Units a, Sailor_TEMP_Abilities b WHERE b.UnitAbilityType IN (SELECT Type FROM TypeTags WHERE Tag IN (SELECT Tag FROM TypeTags WHERE Type = a.UnitType));
*/

INSERT OR REPLACE INTO RequirementSets (RequirementSetId, RequirementSetType)
SELECT DISTINCT 'SAILOR_PUA_IS_'||UnitType, 'REQUIREMENTSET_TEST_ALL' FROM Sailor_TEMP_Units;

INSERT OR REPLACE INTO RequirementSetRequirements (RequirementSetId, RequirementId)
SELECT DISTINCT 'SAILOR_PUA_IS_'||UnitType, 'SAILOR_PUA_REQUIRES_'||UnitType FROM Sailor_TEMP_Units;

INSERT OR REPLACE INTO Requirements (RequirementId, RequirementType)
SELECT DISTINCT 'SAILOR_PUA_REQUIRES_'||UnitType, 'REQUIREMENT_UNIT_TYPE_MATCHES' FROM Sailor_TEMP_Units;

INSERT OR REPLACE INTO RequirementArguments (RequirementId, Name, Value)
SELECT DISTINCT 'SAILOR_PUA_REQUIRES_'||UnitType, 'UnitType', UnitType FROM Sailor_TEMP_Units;

-- // Set uniques' abilities to inactive, then assign them to the appropriate classes.
UPDATE UnitAbilities SET Inactive = 1 WHERE UnitAbilityType IN (SELECT UnitAbilityType FROM Sailor_TEMP_Abilities);

/* Moved these upstairs for use by the problem queries
-- // Temporary table to hold this stupid select statement.
-- // Temporary table to connect units, classes, and abilities.
*/

-- // Give all unique unit abilities a unique class in order to avoid any byproducts
-- // of granting the class to other units of the same promotion type.
-- // Reassign the abilities to this class, and add uniques to the class.
DELETE FROM TypeTags WHERE Type IN (SELECT UnitAbilityType FROM Sailor_TEMP_Abilities);
UPDATE Sailor_TEMP_UnitTags SET Tag = Tag||'_SAILOR' WHERE Tag NOT LIKE '%_SAILOR';
INSERT OR REPLACE INTO Tags (Tag, Vocabulary) SELECT Tag, 'ABILITY_CLASS' FROM Sailor_TEMP_UnitTags;
UPDATE Sailor_TEMP_UnitAbilityTags SET Tag = Tag||'_SAILOR' WHERE Tag NOT LIKE '%_SAILOR';
INSERT OR REPLACE INTO TypeTags (Type, Tag) SELECT UnitAbilityType AS Type, Tag FROM Sailor_TEMP_UnitAbilityTags;
INSERT OR REPLACE INTO TypeTags (Type, Tag) SELECT Type, Tag FROM Sailor_TEMP_UnitAbilityTags;

-- // Temporary intermediate table to hold promotions from stupid select statement's temporary table.
CREATE TABLE Sailor_TEMP_PromotionClasses AS
SELECT PromotionClass FROM Units WHERE UnitType IN (SELECT Type FROM Sailor_TEMP_UnitTags);

-- // Push promotions from intermediate Sailor_TEMP_PromotionClasses table.
CREATE TABLE Sailor_TEMP_PromotionTags AS SELECT * FROM Sailor_TEMP_UnitTags;
UPDATE Sailor_TEMP_PromotionTags SET Type = (SELECT PromotionClass FROM Sailor_TEMP_PromotionClasses WHERE Sailor_TEMP_PromotionClasses.RowID = Sailor_TEMP_PromotionTags.RowID);

-- // Application of unique unit ability classes to their respective promotion classes.
INSERT OR IGNORE INTO TypeTags (Type, Tag)
SELECT a.UnitType, b.Tag FROM Units a, Sailor_TEMP_PromotionTags b WHERE a.PromotionClass = b.Type; -- AND a.TraitType IS NULL;

-- ///////////////////////////////////////////////////////
-- // Dealing with Units table advantages.
-- ///////////////////////////////////////////////////////
-- // Compile relevant Units table values for uniques that replace units.
CREATE TABLE IF NOT EXISTS Sailor_TEMP_Diff (
CivUniqueUnitType text default null,
BaseMoves1 integer default null,
BaseSightRange1 integer default null,
Combat1 integer default null,
RangedCombat1 integer default null,
Range1 integer default null,
Bombard1 integer default null,
BuildCharges1 integer default null,
ZoneOfControl1 integer default null,
ReplacesUnitType text default null,
BaseMoves2 integer default null,
BaseSightRange2 integer default null,
Combat2 integer default null,
RangedCombat2 integer default null,
Range2 integer default null,
Bombard2 integer default null,
BuildCharges2 integer default null,
ZoneOfControl2 integer default null,
MoveDiff integer default null,
SightDiff integer default null,
CombatDiff integer default null,
RangedCombatDiff integer default null,
RangeDiff integer default null,
BombardDiff integer default null,
BuildChargesDiff integer default null,
ZoneOfControlDiff integer default null,
UnitAbilityType text default null);

INSERT INTO Sailor_TEMP_Diff (CivUniqueUnitType, ReplacesUnitType) SELECT CivUniqueUnitType, ReplacesUnitType FROM UnitReplaces;

-- // Figure the differences between uniques and the units they replace.
UPDATE Sailor_TEMP_Diff SET
BaseMoves1 = (SELECT BaseMoves FROM Units WHERE Sailor_TEMP_Diff.CivUniqueUnitType = Units.UnitType),
BaseMoves2 = (SELECT BaseMoves FROM Units WHERE Sailor_TEMP_Diff.ReplacesUnitType = Units.UnitType), 
BaseSightRange1 = (SELECT BaseSightRange FROM Units WHERE Sailor_TEMP_Diff.CivUniqueUnitType = Units.UnitType),
BaseSightRange2 = (SELECT BaseSightRange FROM Units WHERE Sailor_TEMP_Diff.ReplacesUnitType = Units.UnitType), 
Combat1 = (SELECT Combat FROM Units WHERE Sailor_TEMP_Diff.CivUniqueUnitType = Units.UnitType),
Combat2 = (SELECT Combat FROM Units WHERE Sailor_TEMP_Diff.ReplacesUnitType = Units.UnitType), 
RangedCombat1 = (SELECT RangedCombat FROM Units WHERE Sailor_TEMP_Diff.CivUniqueUnitType = Units.UnitType),
RangedCombat2 = (SELECT RangedCombat FROM Units WHERE Sailor_TEMP_Diff.ReplacesUnitType = Units.UnitType), 
Range1 = (SELECT Range FROM Units WHERE Sailor_TEMP_Diff.CivUniqueUnitType = Units.UnitType),
Range2 = (SELECT Range FROM Units WHERE Sailor_TEMP_Diff.ReplacesUnitType = Units.UnitType), 
Bombard1 = (SELECT Bombard FROM Units WHERE Sailor_TEMP_Diff.CivUniqueUnitType = Units.UnitType),
Bombard2 = (SELECT Bombard FROM Units WHERE Sailor_TEMP_Diff.ReplacesUnitType = Units.UnitType), 
BuildCharges1 = (SELECT BuildCharges FROM Units WHERE Sailor_TEMP_Diff.CivUniqueUnitType = Units.UnitType),
BuildCharges2 = (SELECT BuildCharges FROM Units WHERE Sailor_TEMP_Diff.ReplacesUnitType = Units.UnitType), 
ZoneOfControl1 = (SELECT ZoneOfControl FROM Units WHERE Sailor_TEMP_Diff.CivUniqueUnitType = Units.UnitType),
ZoneOfControl2 = (SELECT ZoneOfControl FROM Units WHERE Sailor_TEMP_Diff.ReplacesUnitType = Units.UnitType), 
UnitAbilityType = (SELECT UnitAbilityType FROM Sailor_TEMP_UnitAbilityTags WHERE Sailor_TEMP_Diff.CivUniqueUnitType = Sailor_TEMP_UnitAbilityTags.Type);

UPDATE Sailor_TEMP_Diff SET MoveDiff = BaseMoves1 - BaseMoves2, SightDiff = BaseSightRange1 - BaseSightRange2, CombatDiff = Combat1 - Combat2, RangedCombatDiff = RangedCombat1 - RangedCombat2, RangeDiff = Range1 - Range2, BombardDiff = Bombard1 - Bombard2, BuildChargesDiff = BuildCharges1 - BuildCharges2, ZoneOfControlDiff = ZoneOfControl1 - ZoneOfControl2;

-- // Manually doing UnitAbilityModifiers because automation didn't work for inserts. Believe me, I tried. Thanks to those who tried to help figure it out.
-- // Movement
INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '1_SAILOR_PUA_MOVEMENT' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE MoveDiff = 1);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '2_SAILOR_PUA_MOVEMENT' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE MoveDiff = 2);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '3_SAILOR_PUA_MOVEMENT' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE MoveDiff = 3);

INSERT OR REPLACE INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId)
VALUES	('1_SAILOR_PUA_MOVEMENT', 'MODIFIER_PLAYER_UNIT_ADJUST_MOVEMENT', 'SAILOR_PUA_NOT_ORIGINAL_UNIQUE'),
		('2_SAILOR_PUA_MOVEMENT', 'MODIFIER_PLAYER_UNIT_ADJUST_MOVEMENT', 'SAILOR_PUA_NOT_ORIGINAL_UNIQUE'),
		('3_SAILOR_PUA_MOVEMENT', 'MODIFIER_PLAYER_UNIT_ADJUST_MOVEMENT', 'SAILOR_PUA_NOT_ORIGINAL_UNIQUE');

INSERT OR REPLACE INTO ModifierArguments (ModifierId, Name, Value)
VALUES	('1_SAILOR_PUA_MOVEMENT', 'Amount', 1),
		('2_SAILOR_PUA_MOVEMENT', 'Amount', 2),
		('3_SAILOR_PUA_MOVEMENT', 'Amount', 3);
-- At least these requirements can be reused down the line.
INSERT INTO RequirementSets (RequirementSetId, RequirementSetType)
VALUES ('SAILOR_PUA_NOT_ORIGINAL_UNIQUE', 'REQUIREMENTSET_TEST_ALL');

INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId)
SELECT DISTINCT 'SAILOR_PUA_NOT_ORIGINAL_UNIQUE', 'SAILOR_PUA_REQUIRES_NOT'||UnitType FROM Sailor_TEMP_Units;

INSERT INTO Requirements (RequirementId, RequirementType, Inverse)
SELECT DISTINCT 'SAILOR_PUA_REQUIRES_NOT'||UnitType, 'REQUIREMENT_UNIT_TYPE_MATCHES', 1 FROM Sailor_TEMP_Units;

INSERT INTO RequirementArguments (RequirementId, Name, Value)
SELECT DISTINCT 'SAILOR_PUA_REQUIRES_NOT'||UnitType, 'UnitType', UnitType FROM Sailor_TEMP_Units;

-- // Sight
INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '1_SAILOR_PUA_SIGHT' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE SightDiff = 1);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '2_SAILOR_PUA_SIGHT' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE SightDiff = 2);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '3_SAILOR_PUA_SIGHT' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE SightDiff = 3);

INSERT OR REPLACE INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId)
VALUES	('1_SAILOR_PUA_SIGHT', 'MODIFIER_PLAYER_UNIT_ADJUST_SIGHT', 'SAILOR_PUA_NOT_ORIGINAL_UNIQUE'),
		('2_SAILOR_PUA_SIGHT', 'MODIFIER_PLAYER_UNIT_ADJUST_SIGHT', 'SAILOR_PUA_NOT_ORIGINAL_UNIQUE'),
		('3_SAILOR_PUA_SIGHT', 'MODIFIER_PLAYER_UNIT_ADJUST_SIGHT', 'SAILOR_PUA_NOT_ORIGINAL_UNIQUE');

INSERT OR REPLACE INTO ModifierArguments (ModifierId, Name, Value)
VALUES	('1_SAILOR_PUA_SIGHT', 'Amount', 1),
		('2_SAILOR_PUA_SIGHT', 'Amount', 2),
		('3_SAILOR_PUA_SIGHT', 'Amount', 3);

CREATE TABLE IF NOT EXISTS Sailor_TEMP_Counter (Num integer);
INSERT INTO Sailor_TEMP_Counter (Num) VALUES (-15), (-14), (-13), (-12), (-11), (-10), (-9), (-8), (-7), (-6), (-5), (-4), (-3), (-2), (-1), (1), (2), (3), (4), (5), (6), (7), (8), (9), (10), (11), (12), (13), (14), (15);
-- // Combat
INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '-1_SAILOR_PUA_STR' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE CombatDiff = -1);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '-2_SAILOR_PUA_STR' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE CombatDiff = -2);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '-3_SAILOR_PUA_STR' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE CombatDiff = -3);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '-4_SAILOR_PUA_STR' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE CombatDiff = -4);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '-5_SAILOR_PUA_STR' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE CombatDiff = -5 AND CivUniqueUnitType != 'UNIT_KOREAN_HWACHA');

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '-6_SAILOR_PUA_STR' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE CombatDiff = -6 AND CivUniqueUnitType != 'UNIT_PERSIAN_IMMORTAL');

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '-7_SAILOR_PUA_STR' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE CombatDiff = -7);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '-8_SAILOR_PUA_STR' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE CombatDiff = -8);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '-9_SAILOR_PUA_STR' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE CombatDiff = -9);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '-10_SAILOR_PUA_STR' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE CombatDiff = -10);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '-11_SAILOR_PUA_STR' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE CombatDiff = -11);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '-12_SAILOR_PUA_STR' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE CombatDiff = -12);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '-13_SAILOR_PUA_STR' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE CombatDiff = -13);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '-14_SAILOR_PUA_STR' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE CombatDiff = -14);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '-15_SAILOR_PUA_STR' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE CombatDiff = -15);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '1_SAILOR_PUA_STR' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE CombatDiff = 1);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '2_SAILOR_PUA_STR' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE CombatDiff = 2);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '3_SAILOR_PUA_STR' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE CombatDiff = 3);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '4_SAILOR_PUA_STR' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE CombatDiff = 4);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '5_SAILOR_PUA_STR' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE CombatDiff = 5);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '6_SAILOR_PUA_STR' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE CombatDiff = 6);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '7_SAILOR_PUA_STR' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE CombatDiff = 7);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '8_SAILOR_PUA_STR' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE CombatDiff = 8);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '9_SAILOR_PUA_STR' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE CombatDiff = 9);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '10_SAILOR_PUA_STR' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE CombatDiff = 10);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '11_SAILOR_PUA_STR' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE CombatDiff = 11);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '12_SAILOR_PUA_STR' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE CombatDiff = 12);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '13_SAILOR_PUA_STR' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE CombatDiff = 13);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '14_SAILOR_PUA_STR' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE CombatDiff = 14);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '15_SAILOR_PUA_STR' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE CombatDiff = 15);

INSERT OR REPLACE INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId)
SELECT Num||'_SAILOR_PUA_STR', 'MODIFIER_UNIT_ADJUST_COMBAT_STRENGTH', 'SAILOR_PUA_NOT_ORIGINAL_UNIQUE' FROM Sailor_TEMP_Counter;

INSERT OR REPLACE INTO ModifierArguments (ModifierId, Name, Value)
SELECT Num||'_SAILOR_PUA_STR', 'Amount', Num FROM Sailor_TEMP_Counter;

INSERT OR REPLACE INTO ModifierStrings (ModifierId, Context, Text)
SELECT Num||'_SAILOR_PUA_STR', 'Preview', 'LOC_ABILITY_SAILOR_INHERITED_STRENGTH_PREVIEW_TEXT' FROM Sailor_TEMP_Counter;

-- // Ranged Combat
INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '1_SAILOR_PUA_STR_RNGD' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE RangedCombatDiff = 1);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '2_SAILOR_PUA_STR_RNGD' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE RangedCombatDiff = 2);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '3_SAILOR_PUA_STR_RNGD' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE RangedCombatDiff = 3);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '4_SAILOR_PUA_STR_RNGD' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE RangedCombatDiff = 4);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '5_SAILOR_PUA_STR_RNGD' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE RangedCombatDiff = 5);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '6_SAILOR_PUA_STR_RNGD' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE RangedCombatDiff = 6);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '7_SAILOR_PUA_STR_RNGD' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE RangedCombatDiff = 7);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '8_SAILOR_PUA_STR_RNGD' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE RangedCombatDiff = 8);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '9_SAILOR_PUA_STR_RNGD' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE RangedCombatDiff = 9);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '10_SAILOR_PUA_STR_RNGD' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE RangedCombatDiff = 10);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '11_SAILOR_PUA_STR_RNGD' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE RangedCombatDiff = 11);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '12_SAILOR_PUA_STR_RNGD' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE RangedCombatDiff = 12);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '13_SAILOR_PUA_STR_RNGD' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE RangedCombatDiff = 13);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '14_SAILOR_PUA_STR_RNGD' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE RangedCombatDiff = 14);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '15_SAILOR_PUA_STR_RNGD' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE RangedCombatDiff = 15);

INSERT OR REPLACE INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId)
SELECT Num||'_SAILOR_PUA_STR_RNGD', 'MODIFIER_UNIT_ADJUST_COMBAT_STRENGTH', 'SAILOR_PUA_NOT_ORIGINAL_UNIQUE_RANGEDCOMBAT' FROM Sailor_TEMP_Counter;

INSERT OR REPLACE INTO ModifierArguments (ModifierId, Name, Value)
SELECT Num||'_SAILOR_PUA_STR_RNGD', 'Amount', Num FROM Sailor_TEMP_Counter;

INSERT OR REPLACE INTO ModifierStrings (ModifierId, Context, Text)
SELECT Num||'_SAILOR_PUA_STR_RNGD', 'Preview', 'LOC_ABILITY_SAILOR_INHERITED_STRENGTH_PREVIEW_TEXT' FROM Sailor_TEMP_Counter;

INSERT INTO RequirementSets (RequirementSetId, RequirementSetType)
VALUES ('SAILOR_PUA_NOT_ORIGINAL_UNIQUE_RANGEDCOMBAT', 'REQUIREMENTSET_TEST_ALL');

INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId)
SELECT DISTINCT 'SAILOR_PUA_NOT_ORIGINAL_UNIQUE_RANGEDCOMBAT', 'SAILOR_PUA_REQUIRES_NOT'||UnitType FROM Sailor_TEMP_Units;

INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId)
VALUES ('SAILOR_PUA_NOT_ORIGINAL_UNIQUE_RANGEDCOMBAT', 'PLAYER_IS_ATTACKER_REQUIREMENTS');

-- // Bombard
INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '-1_SAILOR_PUA_STR_BOMB' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE BombardDiff = -1);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '-2_SAILOR_PUA_STR_BOMB' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE BombardDiff = -2);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '-3_SAILOR_PUA_STR_BOMB' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE BombardDiff = -3);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '-4_SAILOR_PUA_STR_BOMB' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE BombardDiff = -4);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '-5_SAILOR_PUA_STR_BOMB' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE BombardDiff = -5);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '-6_SAILOR_PUA_STR_BOMB' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE BombardDiff = -6);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '-7_SAILOR_PUA_STR_BOMB' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE BombardDiff = -7);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '-8_SAILOR_PUA_STR_BOMB' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE BombardDiff = -8);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '-9_SAILOR_PUA_STR_BOMB' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE BombardDiff = -9);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '-10_SAILOR_PUA_STR_BOMB' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE BombardDiff = -10);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '-11_SAILOR_PUA_STR_BOMB' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE BombardDiff = -11);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '-12_SAILOR_PUA_STR_BOMB' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE BombardDiff = -12);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '-13_SAILOR_PUA_STR_BOMB' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE BombardDiff = -13);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '-14_SAILOR_PUA_STR_BOMB' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE BombardDiff = -14);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '-15_SAILOR_PUA_STR_BOMB' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE BombardDiff = -15);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '1_SAILOR_PUA_STR_BOMB' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE BombardDiff = 1);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '2_SAILOR_PUA_STR_BOMB' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE BombardDiff = 2);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '3_SAILOR_PUA_STR_BOMB' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE BombardDiff = 3);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '4_SAILOR_PUA_STR_BOMB' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE BombardDiff = 4);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '5_SAILOR_PUA_STR_BOMB' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE BombardDiff = 5);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '6_SAILOR_PUA_STR_BOMB' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE BombardDiff = 6);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '7_SAILOR_PUA_STR_BOMB' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE BombardDiff = 7);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '8_SAILOR_PUA_STR_BOMB' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE BombardDiff = 8);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '9_SAILOR_PUA_STR_BOMB' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE BombardDiff = 9);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '10_SAILOR_PUA_STR_BOMB' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE BombardDiff = 10);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '11_SAILOR_PUA_STR_BOMB' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE BombardDiff = 11);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '12_SAILOR_PUA_STR_BOMB' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE BombardDiff = 12);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '13_SAILOR_PUA_STR_BOMB' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE BombardDiff = 13);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '14_SAILOR_PUA_STR_BOMB' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE BombardDiff = 14);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '15_SAILOR_PUA_STR_BOMB' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE BombardDiff = 15);

INSERT OR REPLACE INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId)
SELECT Num||'_SAILOR_PUA_STR_BOMB', 'MODIFIER_UNIT_ADJUST_COMBAT_STRENGTH', 'SAILOR_PUA_NOT_ORIGINAL_UNIQUE_BOMBARD' FROM Sailor_TEMP_Counter;

INSERT OR REPLACE INTO ModifierArguments (ModifierId, Name, Value)
SELECT Num||'_SAILOR_PUA_STR_BOMB', 'Amount', Num FROM Sailor_TEMP_Counter;

INSERT OR REPLACE INTO ModifierStrings (ModifierId, Context, Text)
SELECT Num||'_SAILOR_PUA_STR_BOMB', 'Preview', 'LOC_ABILITY_SAILOR_INHERITED_STRENGTH_PREVIEW_TEXT' FROM Sailor_TEMP_Counter;

INSERT INTO RequirementSets (RequirementSetId, RequirementSetType)
VALUES ('SAILOR_PUA_NOT_ORIGINAL_UNIQUE_BOMBARD', 'REQUIREMENTSET_TEST_ALL');

INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId)
SELECT DISTINCT 'SAILOR_PUA_NOT_ORIGINAL_UNIQUE_BOMBARD', 'SAILOR_PUA_REQUIRES_NOT'||UnitType FROM Sailor_TEMP_Units;

INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId)
VALUES ('SAILOR_PUA_NOT_ORIGINAL_UNIQUE_BOMBARD', 'OPPONENT_IS_DISTRICT');

-- // Range
-- RANGED ATTACK? Giving range doesn't give ranged combat. Either give ranged combat or only apply if unit already has at least 1 base range.
INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '-1_SAILOR_PUA_RANGE' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE RangeDiff = -1 AND RangedCombat2 > 0);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '1_SAILOR_PUA_RANGE' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE RangeDiff = 1 AND RangedCombat2 > 0);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '2_SAILOR_PUA_RANGE' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE RangeDiff = 2 AND RangedCombat2 > 0);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '3_SAILOR_PUA_RANGE' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE RangeDiff = 3 AND RangedCombat2 > 0);

INSERT OR REPLACE INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId)
VALUES	('-1_SAILOR_PUA_RANGE', 'MODIFIER_UNIT_ADJUST_ATTACK_RANGE', 'SAILOR_PUA_NOT_ORIGINAL_UNIQUE'),
		('1_SAILOR_PUA_RANGE', 'MODIFIER_UNIT_ADJUST_ATTACK_RANGE', 'SAILOR_PUA_NOT_ORIGINAL_UNIQUE'),
		('2_SAILOR_PUA_RANGE', 'MODIFIER_UNIT_ADJUST_ATTACK_RANGE', 'SAILOR_PUA_NOT_ORIGINAL_UNIQUE'),
		('3_SAILOR_PUA_RANGE', 'MODIFIER_UNIT_ADJUST_ATTACK_RANGE', 'SAILOR_PUA_NOT_ORIGINAL_UNIQUE');

INSERT OR REPLACE INTO ModifierArguments (ModifierId, Name, Value)
VALUES	('-1_SAILOR_PUA_RANGE', 'Amount', -1),
		('1_SAILOR_PUA_RANGE', 'Amount', 1),
		('2_SAILOR_PUA_RANGE', 'Amount', 2),
		('3_SAILOR_PUA_RANGE', 'Amount', 3);

-- // BuildCharges
INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '1_SAILOR_PUA_CHARGES' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE BuildChargesDiff = 1);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '2_SAILOR_PUA_CHARGES' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE BuildChargesDiff = 2);

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, '3_SAILOR_PUA_CHARGES' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE BuildChargesDiff = 3);

INSERT OR REPLACE INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId)
VALUES	('1_SAILOR_PUA_CHARGES', 'MODIFIER_UNIT_ADJUST_BUILDER_CHARGES', 'SAILOR_PUA_NOT_ORIGINAL_UNIQUE'),
		('2_SAILOR_PUA_CHARGES', 'MODIFIER_UNIT_ADJUST_BUILDER_CHARGES', 'SAILOR_PUA_NOT_ORIGINAL_UNIQUE'),
		('3_SAILOR_PUA_CHARGES', 'MODIFIER_UNIT_ADJUST_BUILDER_CHARGES', 'SAILOR_PUA_NOT_ORIGINAL_UNIQUE');

INSERT OR REPLACE INTO ModifierArguments (ModifierId, Name, Value)
VALUES	('1_SAILOR_PUA_CHARGES', 'Amount', 1),
		('2_SAILOR_PUA_CHARGES', 'Amount', 2),
		('3_SAILOR_PUA_CHARGES', 'Amount', 3);

-- Assigning improvements to valid units.
INSERT OR REPLACE INTO Improvement_ValidBuildUnits (ImprovementType, UnitType, ConsumesCharge)
SELECT DISTINCT a.ImprovementType, b.UnitType, 1 FROM Improvement_ValidBuildUnits a, Units b WHERE a.UnitType IN (SELECT UnitType FROM Sailor_TEMP_Units) AND a.ImprovementType != 'IMPROVEMENT_SAILOR_WATCHTOWER' AND b.PromotionClass IN (SELECT PromotionClass FROM Units WHERE UnitType IN (SELECT UnitType FROM Improvement_ValidBuildUnits WHERE ImprovementType = a.ImprovementType)) AND b.UnitType NOT IN (SELECT UnitType FROM Sailor_TEMP_Units);

-- Roman Fort needs a trait. Otherwise, it can be built pell mell.
INSERT INTO Types (Type, Kind) VALUES ('TRAIT_CIVILIZATION_IMPROVEMENT_ROMAN_FORT', 'KIND_TRAIT');
INSERT INTO CivilizationTraits (CivilizationType, TraitType) VALUES ('CIVILIZATION_ROME', 'TRAIT_CIVILIZATION_IMPROVEMENT_ROMAN_FORT');
INSERT INTO Traits (TraitType, Name, Description) VALUES ('TRAIT_CIVILIZATION_IMPROVEMENT_ROMAN_FORT', NULL, NULL);
UPDATE Improvements SET TraitType = 'TRAIT_CIVILIZATION_IMPROVEMENT_ROMAN_FORT' WHERE ImprovementType = 'IMPROVEMENT_ROMAN_FORT';

-- // ZoneOfControl
INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT UnitAbilityType, 'SAILOR_PUA_ZOC' FROM Sailor_TEMP_UnitAbilityTags WHERE Type IN (SELECT CivUniqueUnitType FROM Sailor_TEMP_Diff WHERE ZoneOfControlDiff = 1);

INSERT OR REPLACE INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId)
VALUES	('SAILOR_PUA_ZOC', 'MODIFIER_PLAYER_UNIT_ADJUST_EXERT_ZOC', 'SAILOR_PUA_NOT_ORIGINAL_UNIQUE');

INSERT OR REPLACE INTO ModifierArguments (ModifierId, Name, Value)
VALUES	('SAILOR_PUA_ZOC', 'Exert', 1);

-- ///////////////////////////////////////////////////////
-- // Dealing with Units table advantages.*
-- // *Unit replaces nothing edition.
-- // Ultimately decided to do this by hand because
-- // automation would have been sloppy.
-- ///////////////////////////////////////////////////////
-- Inserting _SAILOR abilities to provision for mods that'd
-- cause these to not be created.
-- Also adding a provision for mods that give these units
-- something to replace.

-- Types
INSERT OR REPLACE INTO Types (Type, Kind)
SELECT 'ABILITY_UNIT_SUMERIAN_WAR_CART_SAILOR', 'KIND_ABILITY' WHERE NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_SUMERIAN_WAR_CART');

INSERT OR REPLACE INTO Types (Type, Kind)
SELECT 'ABILITY_UNIT_SCYTHIAN_HORSE_ARCHER_SAILOR', 'KIND_ABILITY' WHERE NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_SCYTHIAN_HORSE_ARCHER');

INSERT OR REPLACE INTO Types (Type, Kind)
SELECT 'ABILITY_UNIT_EGYPTIAN_CHARIOT_ARCHER_SAILOR', 'KIND_ABILITY' WHERE NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_EGYPTIAN_CHARIOT_ARCHER');

INSERT OR REPLACE INTO Types (Type, Kind)
SELECT 'ABILITY_UNIT_CHINESE_CROUCHING_TIGER_SAILOR', 'KIND_ABILITY' WHERE NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_CHINESE_CROUCHING_TIGER');

-- Tags
INSERT OR REPLACE INTO Tags (Tag, Vocabulary)
SELECT 'CLASS_UNIT_SUMERIAN_WAR_CART_SAILOR', 'ABILITY_CLASS' WHERE NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_SUMERIAN_WAR_CART');

INSERT OR REPLACE INTO Tags (Tag, Vocabulary)
SELECT 'CLASS_UNIT_SCYTHIAN_HORSE_ARCHER_SAILOR', 'ABILITY_CLASS' WHERE NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UUNIT_SCYTHIAN_HORSE_ARCHER');

INSERT OR REPLACE INTO Tags (Tag, Vocabulary)
SELECT 'CLASS_UNIT_EGYPTIAN_CHARIOT_ARCHER_SAILOR', 'ABILITY_CLASS' WHERE NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_EGYPTIAN_CHARIOT_ARCHER');

INSERT OR REPLACE INTO Tags (Tag, Vocabulary)
SELECT 'CLASS_UNIT_CHINESE_CROUCHING_TIGER_SAILOR', 'ABILITY_CLASS' WHERE NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_CHINESE_CROUCHING_TIGER');

--UnitAbilities
INSERT OR REPLACE INTO UnitAbilities (UnitAbilityType, Inactive, Permanent)
SELECT 'ABILITY_UNIT_SUMERIAN_WAR_CART_SAILOR', 1, 1 WHERE NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_SUMERIAN_WAR_CART');

INSERT OR REPLACE INTO UnitAbilities (UnitAbilityType, Inactive, Permanent)
SELECT 'ABILITY_UNIT_SCYTHIAN_HORSE_ARCHER_SAILOR', 1, 1 WHERE NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_SCYTHIAN_HORSE_ARCHER');

INSERT OR REPLACE INTO UnitAbilities (UnitAbilityType, Inactive, Permanent)
SELECT 'ABILITY_UNIT_EGYPTIAN_CHARIOT_ARCHER_SAILOR', 1, 1 WHERE NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_EGYPTIAN_CHARIOT_ARCHER');

INSERT OR REPLACE INTO UnitAbilities (UnitAbilityType, Inactive, Permanent)
SELECT 'ABILITY_UNIT_CHINESE_CROUCHING_TIGER_SAILOR', 1, 1 WHERE NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_CHINESE_CROUCHING_TIGER');

-- TypeTags
INSERT OR REPLACE INTO TypeTags (Type, Tag) SELECT 'ABILITY_UNIT_SUMERIAN_WAR_CART_SAILOR', 'CLASS_UNIT_SUMERIAN_WAR_CART_SAILOR'
WHERE NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_SUMERIAN_WAR_CART');

INSERT OR REPLACE INTO TypeTags (Type, Tag) SELECT 'ABILITY_UNIT_SCYTHIAN_HORSE_ARCHER_SAILOR', 'CLASS_UNIT_SCYTHIAN_HORSE_ARCHER_SAILOR'
WHERE NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_SCYTHIAN_HORSE_ARCHER');

INSERT OR REPLACE INTO TypeTags (Type, Tag) SELECT 'ABILITY_UNIT_EGYPTIAN_CHARIOT_ARCHER_SAILOR', 'CLASS_UNIT_EGYPTIAN_CHARIOT_ARCHER_SAILOR'
WHERE NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_EGYPTIAN_CHARIOT_ARCHER');

INSERT OR REPLACE INTO TypeTags (Type, Tag) SELECT 'ABILITY_UNIT_CHINESE_CROUCHING_TIGER_SAILOR', 'CLASS_UNIT_CHINESE_CROUCHING_TIGER_SAILOR'
WHERE NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_CHINESE_CROUCHING_TIGER');

INSERT OR REPLACE INTO TypeTags (Type, Tag) SELECT 'UNIT_SUMERIAN_WAR_CART', 'CLASS_UNIT_SUMERIAN_WAR_CART_SAILOR'
WHERE NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_SUMERIAN_WAR_CART');

INSERT OR REPLACE INTO TypeTags (Type, Tag) SELECT 'UNIT_SCYTHIAN_HORSE_ARCHER', 'CLASS_UNIT_SCYTHIAN_HORSE_ARCHER_SAILOR'
WHERE NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_SCYTHIAN_HORSE_ARCHER');

INSERT OR REPLACE INTO TypeTags (Type, Tag) SELECT 'UNIT_EGYPTIAN_CHARIOT_ARCHER', 'CLASS_UNIT_EGYPTIAN_CHARIOT_ARCHER_SAILOR'
WHERE NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_EGYPTIAN_CHARIOT_ARCHER');

INSERT OR REPLACE INTO TypeTags (Type, Tag) SELECT 'UNIT_CHINESE_CROUCHING_TIGER', 'CLASS_UNIT_CHINESE_CROUCHING_TIGER_SAILOR'
WHERE NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_CHINESE_CROUCHING_TIGER');

INSERT OR REPLACE INTO TypeTags (Type, Tag) SELECT DISTINCT UpgradeUnit, 'CLASS_UNIT_SUMERIAN_WAR_CART_SAILOR'
FROM UnitUpgrades WHERE UpgradeUnit IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_HEAVY_CAVALRY' AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 0)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 0))))
AND NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_SUMERIAN_WAR_CART');

INSERT OR REPLACE INTO TypeTags (Type, Tag) SELECT DISTINCT UpgradeUnit, 'CLASS_UNIT_SCYTHIAN_HORSE_ARCHER_SAILOR'
FROM UnitUpgrades WHERE UpgradeUnit IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_RANGED' AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 1)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 1))))
AND NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_SCYTHIAN_HORSE_ARCHER');

INSERT OR REPLACE INTO TypeTags (Type, Tag) SELECT DISTINCT UpgradeUnit, 'CLASS_UNIT_EGYPTIAN_CHARIOT_ARCHER_SAILOR'
FROM UnitUpgrades WHERE UpgradeUnit IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_RANGED' AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 0)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 0))))
AND NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_EGYPTIAN_CHARIOT_ARCHER');

INSERT OR REPLACE INTO TypeTags (Type, Tag) SELECT DISTINCT UpgradeUnit, 'CLASS_UNIT_CHINESE_CROUCHING_TIGER_SAILOR'
FROM UnitUpgrades WHERE UpgradeUnit IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_RANGED' AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2))))
AND NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_CHINESE_CROUCHING_TIGER');

-- Modifiers
INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT 'ABILITY_UNIT_SUMERIAN_WAR_CART_SAILOR', '2_SAILOR_PUA_STR'
WHERE NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_SUMERIAN_WAR_CART');

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT 'ABILITY_UNIT_SUMERIAN_WAR_CART_SAILOR', '1_SAILOR_PUA_MOVEMENT'
WHERE NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_SUMERIAN_WAR_CART');

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT 'ABILITY_UNIT_SCYTHIAN_HORSE_ARCHER_SAILOR', 'SAILOR_PUA_ZOC'
WHERE NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_SCYTHIAN_HORSE_ARCHER');

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT 'ABILITY_UNIT_SCYTHIAN_HORSE_ARCHER_SAILOR', '2_SAILOR_PUA_MOVEMENT'
WHERE NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_SCYTHIAN_HORSE_ARCHER');

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT 'ABILITY_UNIT_EGYPTIAN_CHARIOT_ARCHER_SAILOR', 'SAILOR_PUA_ZOC'
WHERE NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_EGYPTIAN_CHARIOT_ARCHER');

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT 'ABILITY_UNIT_EGYPTIAN_CHARIOT_ARCHER_SAILOR', '5_SAILOR_PUA_STR_RNGD'
WHERE NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_EGYPTIAN_CHARIOT_ARCHER');
/* April 2021 Patch
INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT 'ABILITY_SAMURAI', '5_SAILOR_PUA_STR'
WHERE NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_JAPANESE_SAMURAI');
*/
INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT 'ABILITY_VARU', '1_SAILOR_PUA_SIGHT'
WHERE NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_INDIAN_VARU');

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT 'ABILITY_VARU', '5_SAILOR_PUA_STR'
WHERE NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_INDIAN_VARU');

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT 'ABILITY_UNIT_CHINESE_CROUCHING_TIGER_SAILOR', 'SAILOR_PUA_ZOC'
WHERE NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_CHINESE_CROUCHING_TIGER');

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT 'ABILITY_UNIT_CHINESE_CROUCHING_TIGER_SAILOR', '5_SAILOR_PUA_STR_RNGD'
WHERE NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_CHINESE_CROUCHING_TIGER');

-- // Khmer DLC
/* April 2021 Patch
INSERT OR REPLACE INTO Types (Type, Kind)
SELECT 'ABILITY_UNIT_KHMER_DOMREY_SAILOR', 'KIND_ABILITY' WHERE NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_KHMER_DOMREY')
AND EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_KHMER_DOMREY');

INSERT OR REPLACE INTO Tags (Tag, Vocabulary)
SELECT 'CLASS_UNIT_KHMER_DOMREY_SAILOR', 'ABILITY_CLASS' WHERE NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_KHMER_DOMREY')
AND EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_KHMER_DOMREY');

INSERT OR REPLACE INTO TypeTags (Type, Tag) SELECT 'ABILITY_UNIT_KHMER_DOMREY_SAILOR', 'CLASS_UNIT_KHMER_DOMREY_SAILOR'
WHERE NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_KHMER_DOMREY')
AND EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_KHMER_DOMREY');

INSERT OR REPLACE INTO TypeTags (Type, Tag) SELECT 'UNIT_KHMER_DOMREY', 'CLASS_UNIT_KHMER_DOMREY_SAILOR'
WHERE NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_KHMER_DOMREY')
AND EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_KHMER_DOMREY');

INSERT OR REPLACE INTO TypeTags (Type, Tag) SELECT DISTINCT UpgradeUnit, 'CLASS_UNIT_KHMER_DOMREY_SAILOR'
FROM UnitUpgrades WHERE UpgradeUnit IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_SIEGE' AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2))))
AND NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_KHMER_DOMREY')
AND EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_KHMER_DOMREY');

INSERT OR REPLACE INTO UnitAbilities (UnitAbilityType, Inactive, Permanent)
SELECT 'ABILITY_UNIT_KHMER_DOMREY_SAILOR', 1, 1
WHERE EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_KHMER_DOMREY')
AND NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_KHMER_DOMREY');

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT 'ABILITY_UNIT_KHMER_DOMREY_SAILOR', 'EXPERT_CREW_BONUS_ATTACK_AFTER_MOVING'
WHERE EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_KHMER_DOMREY')
AND NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_KHMER_DOMREY');
*/

-- // Poland DLC
/* April 2021 Patch
INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT 'ABILITY_PUSHBACK', '7_SAILOR_PUA_STR'
WHERE EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_POLISH_HUSSAR')
AND NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_POLISH_HUSSAR');
*/

-- // Expansion 1
INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT 'ABILITY_MONGOLIAN_KESHIG', '2_SAILOR_PUA_MOVEMENT'
WHERE EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_MONGOLIAN_KESHIG')
AND NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_MONGOLIAN_KESHIG');

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT 'ABILITY_MONGOLIAN_KESHIG', 'SAILOR_PUA_ZOC'
WHERE EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_MONGOLIAN_KESHIG')
AND NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_MONGOLIAN_KESHIG');

-- Nothing to address with Khevsur.
-- Nothing to address with Malon Raider.

-- // Expansion 2
INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT 'ABILITY_MOUNTIE', '2_SAILOR_PUA_SIGHT'
WHERE EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_CANADA_MOUNTIE')
AND NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_CANADA_MOUNTIE');
-- Can't give park charges with modifiers. RIP. Unit doesn't normally upgrade anyway.

-- // Boy Howdy Teddy Persona Pack DLC
/* April 2021 Patch
INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT 'ABILITY_ROUGH_RIDER', '3_SAILOR_PUA_STR'
WHERE EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_AMERICAN_ROUGH_RIDER')
AND NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_AMERICAN_ROUGH_RIDER');

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT 'ABILITY_ROUGH_RIDER', '1_SAILOR_PUA_MOVEMENT'
WHERE EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_AMERICAN_ROUGH_RIDER')
AND NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_AMERICAN_ROUGH_RIDER');
*/

-- // Babylon DLC
INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT 'ABILITY_SABUM_KIBITTUM_ANTI_CAVALRY', '1_SAILOR_PUA_MOVEMENT'
WHERE EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_BABYLONIAN_SABUM_KIBITTUM')
AND NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_BABYLONIAN_SABUM_KIBITTUM_TIGER');

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT 'ABILITY_SABUM_KIBITTUM_ANTI_CAVALRY', '1_SAILOR_PUA_SIGHT'
WHERE EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_BABYLONIAN_SABUM_KIBITTUM')
AND NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_BABYLONIAN_SABUM_KIBITTUM_TIGER');

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT 'ABILITY_SABUM_KIBITTUM_ANTI_CAVALRY', '-3_SAILOR_PUA_STR'
WHERE EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_BABYLONIAN_SABUM_KIBITTUM')
AND NOT EXISTS (SELECT CivUniqueUnitType FROM UnitReplaces WHERE CivUniqueUnitType = 'UNIT_BABYLONIAN_SABUM_KIBITTUM_TIGER');

-- ///////////////////////////////////////////////////////
-- // Dealing with outliers.
-- ///////////////////////////////////////////////////////
-- // UNIT_PERSIAN_IMMORTAL bespoke shit.
-- Give all possible upgrades a RangedCombat of 1. This doesn't enable ranged attacks,
-- but allows them to make ranged attacks when given a Range value > 0.
UPDATE Units SET RangedCombat = 1 WHERE RangedCombat = 0 AND UnitType IN (SELECT UpgradeUnit FROM UnitUpgrades WHERE UpgradeUnit IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_MELEE' AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2)))))
AND EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_PERSIAN_IMMORTAL');

INSERT OR REPLACE INTO UnitAbilities (UnitAbilityType, Inactive, Permanent)
SELECT 'ABILITY_UNIT_PERSIAN_IMMORTAL_SAILOR', 1, 1
WHERE EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_PERSIAN_IMMORTAL');

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT DISTINCT 'ABILITY_UNIT_PERSIAN_IMMORTAL_SAILOR', 'SAILOR_PUA_IMMORTAL_RANGE_'||UpgradeUnit
FROM UnitUpgrades WHERE UpgradeUnit IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_MELEE' AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2))))
AND EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_PERSIAN_IMMORTAL');

INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT DISTINCT 'ABILITY_UNIT_PERSIAN_IMMORTAL_SAILOR', 'SAILOR_PUA_IMMORTAL_RANGE_STR_'||UpgradeUnit
FROM UnitUpgrades WHERE UpgradeUnit IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_MELEE' AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2))))
AND EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_PERSIAN_IMMORTAL');
/* April 2021 Patch
INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT DISTINCT 'ABILITY_UNIT_PERSIAN_IMMORTAL_SAILOR', 'SAILOR_PUA_IMMORTAL_MELEE_STR_'||UpgradeUnit
FROM UnitUpgrades WHERE UpgradeUnit IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_MELEE' AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2))))
AND EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_PERSIAN_IMMORTAL');
*/

-- Modifiers
INSERT OR REPLACE INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId)
SELECT DISTINCT 'SAILOR_PUA_IMMORTAL_RANGE_'||UpgradeUnit, 'MODIFIER_UNIT_ADJUST_ATTACK_RANGE', 'SAILOR_PUA_IMMORTAL_RANGE_'||UpgradeUnit||'_REQUIREMENTS'
FROM UnitUpgrades WHERE UpgradeUnit IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_MELEE' AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2))))
AND EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_PERSIAN_IMMORTAL');

INSERT OR REPLACE INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId)
SELECT DISTINCT 'SAILOR_PUA_IMMORTAL_RANGE_STR_'||UpgradeUnit, 'MODIFIER_UNIT_ADJUST_COMBAT_STRENGTH', 'SAILOR_PUA_IMMORTAL_RANGE_STR_'||UpgradeUnit||'_REQUIREMENTS'
FROM UnitUpgrades WHERE UpgradeUnit IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_MELEE' AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2))))
AND EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_PERSIAN_IMMORTAL');

/* April 2021 Patch
INSERT OR REPLACE INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId)
SELECT DISTINCT 'SAILOR_PUA_IMMORTAL_MELEE_STR_'||UpgradeUnit, 'MODIFIER_UNIT_ADJUST_COMBAT_STRENGTH', 'SAILOR_PUA_IMMORTAL_MELEE_STR_'||UpgradeUnit||'_REQUIREMENTS'
FROM UnitUpgrades WHERE UpgradeUnit IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_MELEE' AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2))))
AND EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_PERSIAN_IMMORTAL');

INSERT OR REPLACE INTO ModifierStrings (ModifierId, Context, Text)
SELECT DISTINCT 'SAILOR_PUA_IMMORTAL_MELEE_STR_'||UpgradeUnit, 'Preview', 'LOC_ABILITY_SAILOR_INHERITED_STRENGTH_PREVIEW_TEXT'
FROM UnitUpgrades WHERE UpgradeUnit IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_MELEE' AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2))))
AND EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_PERSIAN_IMMORTAL');
*/
INSERT OR REPLACE INTO ModifierStrings (ModifierId, Context, Text)
SELECT DISTINCT 'SAILOR_PUA_IMMORTAL_RANGE_STR_'||UpgradeUnit, 'Preview', 'LOC_ABILITY_SAILOR_INHERITED_STRENGTH_PREVIEW_TEXT'
FROM UnitUpgrades WHERE UpgradeUnit IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_MELEE' AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2))))
AND EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_PERSIAN_IMMORTAL');

-- Arguments
INSERT OR REPLACE INTO ModifierArguments (ModifierId, Name, Value)
SELECT DISTINCT 'SAILOR_PUA_IMMORTAL_RANGE_'||UpgradeUnit, 'Amount', 2
FROM UnitUpgrades WHERE UpgradeUnit IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_MELEE' AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2))))
AND EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_PERSIAN_IMMORTAL');

INSERT OR REPLACE INTO ModifierArguments (ModifierId, Name, Value)
SELECT DISTINCT 'SAILOR_PUA_IMMORTAL_RANGE_STR_'||a.UpgradeUnit, 'Amount', b.Combat - 11
FROM UnitUpgrades a, Units b WHERE a.UpgradeUnit IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_MELEE' AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2))))
AND b.Combat IN (SELECT Combat FROM Units WHERE UnitType = a.UpgradeUnit)
AND EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_PERSIAN_IMMORTAL');
/* April 2021 Patch
INSERT OR REPLACE INTO ModifierArguments (ModifierId, Name, Value)
SELECT DISTINCT 'SAILOR_PUA_IMMORTAL_MELEE_STR_'||a.UpgradeUnit, 'Amount', -6
FROM UnitUpgrades a, Units b WHERE a.UpgradeUnit IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_MELEE' AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2))))
AND b.Combat IN (SELECT Combat FROM Units WHERE UnitType = a.UpgradeUnit)
AND EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_PERSIAN_IMMORTAL');
*/

-- RequirementSets
INSERT OR REPLACE INTO RequirementSets (RequirementSetId, RequirementSetType)
SELECT DISTINCT 'SAILOR_PUA_IMMORTAL_RANGE_'||UpgradeUnit||'_REQUIREMENTS', 'REQUIREMENTSET_TEST_ALL'
FROM UnitUpgrades WHERE UpgradeUnit IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_MELEE' AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2))))
AND EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_PERSIAN_IMMORTAL');

INSERT OR REPLACE INTO RequirementSets (RequirementSetId, RequirementSetType)
SELECT DISTINCT 'SAILOR_PUA_IMMORTAL_RANGE_STR_'||UpgradeUnit||'_REQUIREMENTS', 'REQUIREMENTSET_TEST_ALL'
FROM UnitUpgrades WHERE UpgradeUnit IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_MELEE' AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2))))
AND EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_PERSIAN_IMMORTAL');
/* April 2021 Patch
INSERT OR REPLACE INTO RequirementSets (RequirementSetId, RequirementSetType)
SELECT DISTINCT 'SAILOR_PUA_IMMORTAL_MELEE_STR_'||UpgradeUnit||'_REQUIREMENTS', 'REQUIREMENTSET_TEST_ALL'
FROM UnitUpgrades WHERE UpgradeUnit IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_MELEE' AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2))))
AND EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_PERSIAN_IMMORTAL');

	-- Melee Subset
INSERT OR REPLACE INTO RequirementSets (RequirementSetId, RequirementSetType)
SELECT 'SAILOR_PUA_IMMORTAL_MELEE_OR_DEFENDING_REQUIREMENTS', 'REQUIREMENTSET_TEST_ANY'
WHERE EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_PERSIAN_IMMORTAL');
*/

-- Broken up by application.
	-- Range
INSERT OR REPLACE INTO RequirementSetRequirements (RequirementSetId, RequirementId)
SELECT DISTINCT 'SAILOR_PUA_IMMORTAL_RANGE_'||UpgradeUnit||'_REQUIREMENTS', 'SAILOR_PUA_IMMORTAL_IS_'||UpgradeUnit
FROM UnitUpgrades WHERE UpgradeUnit IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_MELEE' AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2))))
AND EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_PERSIAN_IMMORTAL');

	-- Ranged Str
INSERT OR REPLACE INTO RequirementSetRequirements (RequirementSetId, RequirementId)
SELECT DISTINCT 'SAILOR_PUA_IMMORTAL_RANGE_STR_'||UpgradeUnit||'_REQUIREMENTS', 'SAILOR_PUA_IMMORTAL_IS_'||UpgradeUnit
FROM UnitUpgrades WHERE UpgradeUnit IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_MELEE' AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2))))
AND EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_PERSIAN_IMMORTAL');

INSERT OR REPLACE INTO RequirementSetRequirements (RequirementSetId, RequirementId)
SELECT DISTINCT 'SAILOR_PUA_IMMORTAL_RANGE_STR_'||UpgradeUnit||'_REQUIREMENTS', 'PLAYER_IS_ATTACKER_REQUIREMENTS'
FROM UnitUpgrades WHERE UpgradeUnit IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_MELEE' AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2))))
AND EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_PERSIAN_IMMORTAL');

INSERT OR REPLACE INTO RequirementSetRequirements (RequirementSetId, RequirementId)
SELECT DISTINCT 'SAILOR_PUA_IMMORTAL_RANGE_STR_'||UpgradeUnit||'_REQUIREMENTS', 'RANGED_COMBAT_REQUIREMENTS'
FROM UnitUpgrades WHERE UpgradeUnit IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_MELEE' AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2))))
AND EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_PERSIAN_IMMORTAL');

/* April 2021 Patch
	-- Melee Str
INSERT OR REPLACE INTO RequirementSetRequirements (RequirementSetId, RequirementId)
SELECT DISTINCT 'SAILOR_PUA_IMMORTAL_MELEE_STR_'||UpgradeUnit||'_REQUIREMENTS', 'SAILOR_PUA_IMMORTAL_IS_'||UpgradeUnit
FROM UnitUpgrades WHERE UpgradeUnit IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_MELEE' AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2))))
AND EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_PERSIAN_IMMORTAL');

INSERT OR REPLACE INTO RequirementSetRequirements (RequirementSetId, RequirementId)
SELECT DISTINCT 'SAILOR_PUA_IMMORTAL_MELEE_STR_'||UpgradeUnit||'_REQUIREMENTS', 'SAILOR_PUA_IMMORTAL_MELEE_REQSET_IS_MET'
FROM UnitUpgrades WHERE UpgradeUnit IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_MELEE' AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2))))
AND EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_PERSIAN_IMMORTAL');

	-- Melee Reqset
INSERT OR REPLACE INTO RequirementSetRequirements (RequirementSetId, RequirementId)
SELECT 'SAILOR_PUA_IMMORTAL_MELEE_OR_DEFENDING_REQUIREMENTS', 'MELEE_COMBAT_REQUIREMENTS'
WHERE EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_PERSIAN_IMMORTAL');

INSERT OR REPLACE INTO RequirementSetRequirements (RequirementSetId, RequirementId)
SELECT 'SAILOR_PUA_IMMORTAL_MELEE_OR_DEFENDING_REQUIREMENTS', 'PLAYER_IS_DEFENDER_REQUIREMENTS'
WHERE EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_PERSIAN_IMMORTAL');

INSERT OR REPLACE INTO Requirements (RequirementId, RequirementType)
SELECT 'SAILOR_PUA_IMMORTAL_MELEE_REQSET_IS_MET', 'REQUIREMENT_REQUIREMENTSET_IS_MET'
WHERE EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_PERSIAN_IMMORTAL');

INSERT OR REPLACE INTO RequirementArguments (RequirementId, Name, Value)
SELECT 'SAILOR_PUA_IMMORTAL_MELEE_REQSET_IS_MET', 'RequirementSetId', 'SAILOR_PUA_IMMORTAL_MELEE_OR_DEFENDING_REQUIREMENTS'
WHERE EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_PERSIAN_IMMORTAL');
*/

-- UnitType
INSERT OR REPLACE INTO Requirements (RequirementId, RequirementType)
SELECT DISTINCT 'SAILOR_PUA_IMMORTAL_IS_'||UpgradeUnit, 'REQUIREMENT_UNIT_TYPE_MATCHES'
FROM UnitUpgrades WHERE UpgradeUnit IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_MELEE' AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2))))
AND EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_PERSIAN_IMMORTAL');

INSERT OR REPLACE INTO RequirementArguments (RequirementId, Name, Value)
SELECT DISTINCT 'SAILOR_PUA_IMMORTAL_IS_'||UpgradeUnit, 'UnitType', UpgradeUnit
FROM UnitUpgrades WHERE UpgradeUnit IN (SELECT UnitType FROM Units WHERE PromotionClass = 'PROMOTION_CLASS_MELEE' AND (PrereqTech IS NOT NULL OR PrereqCivic IS NOT NULL) AND 
(PrereqTech IN (SELECT TechnologyType FROM Technologies WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2)) OR
PrereqCivic IN (SELECT CivicType FROM Civics WHERE EraType IN (SELECT EraType FROM Eras WHERE ROWID > 2))))
AND EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_PERSIAN_IMMORTAL');

-- // UNIT_GREEK_HOPLITE, UNIT_COLOMBIAN_LLANERO need requirements redefined.
-- Hoplite
UPDATE RequirementSets SET RequirementSetType = 'REQUIREMENTSET_TEST_ANY' WHERE RequirementSetId = 'HOPLITE_PLOT_IS_HOPLITE_REQUIREMENTS';

INSERT OR REPLACE INTO RequirementSetRequirements (RequirementSetId, RequirementId)
SELECT 'HOPLITE_PLOT_IS_HOPLITE_REQUIREMENTS', 'SAILOR_REQUIRES_UNIT_NEXT_TO_'||UnitType
FROM Units WHERE UnitType IN ('UNIT_PIKEMAN', 'UNIT_PIKE_AND_SHOT', 'UNIT_AT_CREW', 'UNIT_MODERN_AT');

INSERT OR REPLACE INTO Requirements (RequirementId, RequirementType)
SELECT 'SAILOR_REQUIRES_UNIT_NEXT_TO_'||UnitType, 'REQUIREMENT_PLOT_ADJACENT_FRIENDLY_UNIT_TYPE_MATCHES'
FROM Units WHERE UnitType IN ('UNIT_PIKEMAN', 'UNIT_PIKE_AND_SHOT', 'UNIT_AT_CREW', 'UNIT_MODERN_AT');

INSERT OR REPLACE INTO RequirementArguments (RequirementId, Name, Value)
SELECT 'SAILOR_REQUIRES_UNIT_NEXT_TO_'||UnitType, 'UnitType', UnitType
FROM Units WHERE UnitType IN ('UNIT_PIKEMAN', 'UNIT_PIKE_AND_SHOT', 'UNIT_AT_CREW', 'UNIT_MODERN_AT');

-- Llanero
INSERT OR REPLACE INTO UnitAbilityModifiers (UnitAbilityType, ModifierId)
SELECT 'ABILITY_LLANERO_ADJACENCY_STRENGTH', 'SAILOR_LLANERO_ADJACENCY_STRENGTH_UNIT_HELICOPTER'
WHERE EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_COLOMBIAN_LLANERO');

INSERT OR REPLACE INTO Modifiers (ModifierId, ModifierType, OwnerRequirementSetId)
SELECT 'SAILOR_LLANERO_ADJACENCY_STRENGTH_UNIT_HELICOPTER', 'GRANT_STRENGTH_PER_ADJACENT_UNIT_TYPE', 'SAILOR_UNIT_HELICOPTER_IS_ADJACENT_REQUIREMENTS'
WHERE EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_COLOMBIAN_LLANERO');

INSERT OR REPLACE INTO ModifierArguments (ModifierId, Name, Value)
SELECT 'SAILOR_LLANERO_ADJACENCY_STRENGTH_UNIT_HELICOPTER', 'Amount', 2
WHERE EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_COLOMBIAN_LLANERO');

INSERT OR REPLACE INTO ModifierArguments (ModifierId, Name, Value)
SELECT 'SAILOR_LLANERO_ADJACENCY_STRENGTH_UNIT_HELICOPTER', 'UnitType', 'UNIT_HELICOPTER'
WHERE EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_COLOMBIAN_LLANERO');

INSERT OR REPLACE INTO RequirementSets (RequirementSetId, RequirementSetType)
SELECT 'SAILOR_UNIT_HELICOPTER_IS_ADJACENT_REQUIREMENTS', 'REQUIREMENTSET_TEST_ALL'
WHERE EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_COLOMBIAN_LLANERO');

INSERT OR REPLACE INTO RequirementSetRequirements (RequirementSetId, RequirementId)
SELECT 'SAILOR_UNIT_HELICOPTER_IS_ADJACENT_REQUIREMENTS', 'SAILOR_REQUIRES_UNIT_NEXT_TO_UNIT_HELICOPTER'
WHERE EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_COLOMBIAN_LLANERO');

INSERT OR REPLACE INTO Requirements (RequirementId, RequirementType)
SELECT 'SAILOR_REQUIRES_UNIT_NEXT_TO_UNIT_HELICOPTER', 'REQUIREMENT_PLOT_ADJACENT_FRIENDLY_UNIT_TYPE_MATCHES'
WHERE EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_COLOMBIAN_LLANERO');

INSERT OR REPLACE INTO RequirementArguments (RequirementId, Name, Value)
SELECT 'SAILOR_REQUIRES_UNIT_NEXT_TO_UNIT_HELICOPTER', 'UnitType', 'UNIT_HELICOPTER'
WHERE EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_COLOMBIAN_LLANERO');

INSERT OR REPLACE INTO ModifierStrings (ModifierId, Context, Text)
SELECT 'SAILOR_LLANERO_ADJACENCY_STRENGTH_UNIT_HELICOPTER', 'Preview', 'LOC_SAILOR_LLANERO_ADJACENCY_STRENGTH_UNIT_HELICOPTER_DESCRIPTION'
WHERE EXISTS (SELECT UnitType FROM Units WHERE UnitType = 'UNIT_COLOMBIAN_LLANERO');

-- ///////////////////////////////////////////////////////
-- // Clean up tables.
-- ///////////////////////////////////////////////////////
DROP TABLE Sailor_TEMP_Abilities;
DROP TABLE Sailor_TEMP_Counter;
DROP TABLE Sailor_TEMP_Diff;
DROP TABLE Sailor_TEMP_PromotionClasses;
DROP TABLE Sailor_TEMP_PromotionTags;
DROP TABLE Sailor_TEMP_Units;
DROP TABLE Sailor_TEMP_UnitTags;
DROP TABLE Sailor_TEMP_UnitAbilityTags;