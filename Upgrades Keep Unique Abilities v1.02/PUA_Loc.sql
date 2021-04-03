-- // Hoplite
UPDATE LocalizedText SET Text = "+{1_Amount} [ICON_Strength] Combat Strength when next to another Hoplite or Hoplite upgrade." WHERE Tag = 'LOC_ABILITY_HOPLITE_NEIGHBOR_COMBAT_MODIFIER_DESCRIPTION';
UPDATE LocalizedText SET Text = "+10 [ICON_Strength] Combat Strength if there is at least one Hoplite adjacent. Applies to upgraded unit types if inherited." WHERE Tag = 'LOC_ABILITY_HOPLITE_DESCRIPTION';

-- // Llanero
UPDATE LocalizedText SET Text = "+2 [ICON_Strength] Combat Strength from each adjacent Llanero unit. Applies to upgraded unit types if inherited." WHERE Tag = 'LOC_ABILITY_LLANERO_ADJACENCY_STRENGTH_DESCRIPTION' AND EXISTS (SELECT Tag FROM LocalizedText WHERE Tag = 'LOC_ABILITY_LLANERO_ADJACENCY_STRENGTH_DESCRIPTION');