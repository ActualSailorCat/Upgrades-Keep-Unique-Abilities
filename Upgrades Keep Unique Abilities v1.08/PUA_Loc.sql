-- ///////////////////////////////////////////////////////
-- // Firaxis
-- ///////////////////////////////////////////////////////
-- // Hoplite
UPDATE LocalizedText SET Text = "+{1_Amount} [ICON_Strength] Combat Strength when next to another Hoplite or upgrade." WHERE Tag = 'LOC_ABILITY_HOPLITE_NEIGHBOR_COMBAT_MODIFIER_DESCRIPTION';
UPDATE LocalizedText SET Text = "+10 [ICON_Strength] Combat Strength if there is at least one Hoplite adjacent. Applies to upgraded unit types if inherited." WHERE Tag = 'LOC_ABILITY_HOPLITE_DESCRIPTION';
-- // Llanero
UPDATE LocalizedText SET Text = "+2 [ICON_Strength] Combat Strength from each adjacent Llanero unit. Applies to upgraded unit types if inherited." WHERE Tag = 'LOC_ABILITY_LLANERO_ADJACENCY_STRENGTH_DESCRIPTION' AND EXISTS (SELECT Tag FROM LocalizedText WHERE Tag = 'LOC_ABILITY_LLANERO_ADJACENCY_STRENGTH_DESCRIPTION');

-- ///////////////////////////////////////////////////////
-- // Mods
-- ///////////////////////////////////////////////////////
-- // Steel & Thunder
-- Longbowman
UPDATE LocalizedText SET Text = "+4 [ICON_Strength] Combat Strength next to Longbowman or upgrade." WHERE Tag = 'PLUS_4_LONGBOWMAN_ADJACENCY_COMBAT_BONUS_DESC' AND EXISTS (SELECT Tag FROM LocalizedText WHERE Tag = 'PLUS_4_LONGBOWMAN_ADJACENCY_COMBAT_BONUS_DESC');
UPDATE LocalizedText SET Text = "+4 [ICON_Strength] Combat Strength against Melee and Cavalry units with a further +4 [ICON_Strength] Combat Strength if adjacent to another Longbowman or Longbowman upgrade." WHERE Tag = 'LOC_ABILITY_LONGBOWMAN_DESCRIPTION' AND EXISTS (SELECT Tag FROM LocalizedText WHERE Tag = 'LOC_ABILITY_LONGBOWMAN_DESCRIPTION');
-- Assegai
UPDATE LocalizedText SET Text = "+4 [ICON_Strength] Combat Strength next to Isijula Warrior or upgrade." WHERE Tag = 'PLUS_4_ASSEGAI_ADJACENCY_COMBAT_BONUS_DESC' AND EXISTS (SELECT Tag FROM LocalizedText WHERE Tag = 'PLUS_4_ASSEGAI_ADJACENCY_COMBAT_BONUS_DESC');
UPDATE LocalizedText SET Text = "+4 [ICON_Strength] when adjacent to another Isijula Warrior or upgrade." WHERE Tag = 'LOC_ABILITY_ZULU_ASSEGAI_DESCRIPTION' AND EXISTS (SELECT Tag FROM LocalizedText WHERE Tag = 'LOC_ABILITY_ZULU_ASSEGAI_DESCRIPTION');
-- Ship of the Line
UPDATE LocalizedText SET Text = "+7 [ICON_Strength] Combat Strength when adjacent to another Ship of the Line or upgrade." WHERE Tag = 'LOC_ABILITY_SHIP_OF_THE_LINE_ADJACENCY_BONUS_DESCRIPTION' AND EXISTS (SELECT Tag FROM LocalizedText WHERE Tag = 'LOC_ABILITY_SHIP_OF_THE_LINE_ADJACENCY_BONUS_DESCRIPTION');