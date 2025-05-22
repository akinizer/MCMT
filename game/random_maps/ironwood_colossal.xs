include "lib2/rm_core.xs";

void generate()
{
   rmSetProgress(0.0);
   
   // Define mixes.
   int baseMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.15, 1);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainMarshGrass2, 4.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainMarshGrass1, 2.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainMarshGrassWet1, 2.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainMarshGrassWet2, 2.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainMarshGrassRocks1, 3.0);

 // Set size.
   int playerTiles=20000;
   int cNumberNonGaiaPlayers = 10;
   if(cMapSizeCurrent == 1)
   {
      playerTiles = 30000;
   }
   int size=2.0*sqrt(cNumberNonGaiaPlayers*playerTiles/0.9);
   rmSetMapSize(size, size);
   rmInitializeMix(baseMixID);

   // Player placement.
   rmSetTeamSpacingModifier(xsRandFloat(0.75, 0.85));
   //rmPlacePlayersOnCircle(xsRandFloat(0.325, 0.375));
   rmPlacePlayersOnSquare(0.3, 0.3);

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCivFromCulture(cCultureNorse);

   // Lighting.
   rmSetLighting(cLightingSetRmIronwood01);
   
   // Team continents.
   float wallWidth = 20.0 * getMapAreaSizeFactor();

   int teamContinentClassID = rmClassCreate();
   int teamContinentAvoidTeamContinent = rmCreateClassDistanceConstraint(teamContinentClassID, wallWidth);

   for(int i = 1; i <= cNumberTeams; i++)
   {
      int teamContinentID = rmAreaCreate("team continent " + i);
      rmAreaSetSize(teamContinentID, 1.0);
      rmAreaSetLocTeam(teamContinentID, i);

		rmAreaSetHeight(teamContinentID, 0.5);
		rmAreaAddHeightBlend(teamContinentID, cBlendAll, cFilter5x5Box, 2);

		rmAreaAddConstraint(teamContinentID, teamContinentAvoidTeamContinent);
      if (gameIsKotH() == true)
      {
         rmAreaAddConstraint(teamContinentID, rmCreateLocDistanceConstraint(cCenterLoc, 45.0));
      }
		rmAreaAddToClass(teamContinentID, teamContinentClassID);

      // Register this as the team's area so location generation uses that instead.
      vTeamAreaIDs[i] = teamContinentID;
   }

   rmAreaBuildAll();

   // Global elevation.
   rmAddGlobalHeightNoise(cNoiseFractalSum, 5.0, 0.05, 1, 0.5);

   rmSetProgress(0.1);
   
   // Center forest wall.
   int forestClassID = rmClassCreate();
   int centerForestWallID = rmAreaCreate("center forest wall");
   rmAreaSetSize(centerForestWallID, 1.0);
   rmAreaSetForestType(centerForestWallID, cForestMarshOak);
   rmAreaAddToClass(centerForestWallID, forestClassID);
   rmAreaAddConstraint(centerForestWallID, rmCreateClassDistanceConstraint(teamContinentClassID, 1.0));

   rmAreaSetWarnOnBuildFailure(centerForestWallID, cAreaStateIncomplete);
   rmAreaBuild(centerForestWallID);

   // KotH.
   if (gameIsKotH() == true)
   {
      int islandKotHID = rmAreaCreate("koth island");
      rmAreaSetSize(islandKotHID, rmRadiusToAreaFraction(25.0));
      rmAreaSetLoc(islandKotHID, cCenterLoc);
      rmAreaSetMix(islandKotHID, baseMixID);

      rmAreaSetCoherence(islandKotHID, 0.5);
      rmAreaSetEdgeSmoothDistance(islandKotHID, 5);
      rmAreaSetHeight(islandKotHID, -1.0);
      rmAreaSetHeightNoise(islandKotHID, cNoiseFractalSum, 3.0, 0.1, 3, 0.5);
      rmAreaSetHeightNoiseBias(islandKotHID, 1.0); // Only grow upwards.
      rmAreaSetHeightNoiseEdgeFalloffDist(islandKotHID, 20.0);
      rmAreaAddHeightBlend(islandKotHID, cBlendEdge, cFilter5x5Box, 10.0, 5.0);
      rmAreaAddRemoveType(islandKotHID, cUnitTypeTree);
      
      rmAreaAddToClass(islandKotHID, vKotHClassID);

      rmAreaBuild(islandKotHID);
   }

   placeKotHObjects();

   // Settlements and towers.
   placeStartingTownCenters();
   
   int pondClassID = rmClassCreate();

   int numPonds = 3 * cNumberPlayers * getMapAreaSizeFactor();

   float pondMinSize = rmTilesToAreaFraction(250);
   float pondMaxSize = rmTilesToAreaFraction(500);

   for(int i = 0; i < numPonds; i++)
   {
      int pondID = rmAreaCreate("pond " + i);
      
      rmAreaSetSize(pondID, xsRandFloat(pondMinSize, pondMaxSize));
      rmAreaSetWaterType(pondID, cWaterMarshShallow);
      
      rmAreaSetCoherence(pondID, 0.1);
      rmAreaAddHeightBlend(pondID, cBlendAll, cFilter5x5Box, 8.0, 5.0);
      
      rmAreaAddConstraint(pondID, createPlayerLocDistanceConstraint(50.0));
      rmAreaAddConstraint(pondID, rmCreateClassDistanceConstraint(forestClassID, 15.0));
      rmAreaAddToClass(pondID, pondClassID);
      
      rmAreaBuild(pondID);
   }

   // Starting towers.
   int startingTowerID = rmObjectDefCreate("starting tower");
   rmObjectDefAddItem(startingTowerID, cUnitTypeSentryTower, 1);
   addObjectLocsPerPlayer(startingTowerID, true, 4, cStartingTowerMinDist, cStartingTowerMaxDist, cStartingTowerAvoidanceMeters);
   generateLocs("starting tower locs");

   // Settlements.
   
   int firstSettlementID = rmObjectDefCreate("first settlement");
   rmObjectDefAddItem(firstSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidAllWithFarm);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidWater4);
   rmObjectDefAddConstraint(firstSettlementID, rmCreateClassDistanceConstraint(forestClassID, 15.0));

   int secondSettlementID = rmObjectDefCreate("second settlement");
   rmObjectDefAddItem(secondSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidAllWithFarm);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidWater4);
   rmObjectDefAddConstraint(secondSettlementID, rmCreateClassDistanceConstraint(forestClassID, 15.0));

   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(firstSettlementID, false, 1, 60.0, 80.0, cSettlementDist1v1, cBiasBackward);
      addSimObjectLocsPerPlayerPair(secondSettlementID, false, 1, 70.0, 110.0, cSettlementDist1v1, cBiasAggressive);
   }
   else
   {
      // Randomize inside/outside.
      int allyBias = getRandomAllyBias();
      addObjectLocsPerPlayer(firstSettlementID, false, 1, 60.0, 80.0, cCloseSettlementDist, cBiasBackward | cBiasAllyInside);
      addObjectLocsPerPlayer(secondSettlementID, false, 1, 70.0, 90.0, cFarSettlementDist, cBiasAggressive | allyBias);
   }
   
   // Other map sizes settlements.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int bonusSettlementID = rmObjectDefCreate("bonus settlement");
      rmObjectDefAddItem(bonusSettlementID, cUnitTypeSettlement, 1);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidEdge);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidAllWithFarm);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidCorner40);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidWater4);
      addObjectLocsPerPlayer(bonusSettlementID, false, 1 * getMapAreaSizeFactor(), 90.0, -1.0, 100.0);
   }

   generateLocs("settlement locs");

   rmSetProgress(0.3);

   // Starting objects.
   // Starting gold.
   int startingGoldID = rmObjectDefCreate("starting gold");
   rmObjectDefAddItem(startingGoldID, cUnitTypeMineGoldMedium, 1);
   rmObjectDefAddConstraint(startingGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingGoldID, vDefaultStartingGoldAvoidTower);
   rmObjectDefAddConstraint(startingGoldID, vDefaultForceStartingGoldNearTower);
   addObjectLocsPerPlayer(startingGoldID, false, 1, cStartingGoldMinDist, cStartingGoldMaxDist, cStartingObjectAvoidanceMeters, cBiasNotAggressive);

   generateLocs("starting gold locs");

   // Berries.
   int startingBerriesID = rmObjectDefCreate("starting berries");
   rmObjectDefAddItem(startingBerriesID, cUnitTypeBerryBush, xsRandInt(6, 9), cBerryClusterRadius);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidAll);
   addObjectLocsPerPlayer(startingBerriesID, false, 1, cStartingBerriesMinDist, cStartingBerriesMaxDist, cStartingObjectAvoidanceMeters);

   // Starting hunt.
   int startingHuntID = rmObjectDefCreate("starting hunt");
   rmObjectDefAddItem(startingHuntID, cUnitTypeBoar, xsRandInt(4, 5));
   rmObjectDefAddConstraint(startingHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHuntID, vDefaultForceInTowerLOS);
   addObjectLocsPerPlayer(startingHuntID, false, 1, cStartingHuntMinDist, cStartingHuntMaxDist, cStartingObjectAvoidanceMeters);

   // Chicken.
   int startingChickenID = rmObjectDefCreate("starting chicken");
   rmObjectDefAddItem(startingChickenID, cUnitTypeChicken, xsRandInt(5, 9));
   rmObjectDefAddConstraint(startingChickenID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidAll);
   addObjectLocsPerPlayer(startingChickenID, false, 1, cStartingChickenMinDist, cStartingChickenMaxDist, cStartingObjectAvoidanceMeters);

   // Herdables.
   int startingHerdID = rmObjectDefCreate("starting herd");
   rmObjectDefAddItem(startingHerdID, cUnitTypePig, 2);
   rmObjectDefAddConstraint(startingHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidAll);
   addObjectLocsPerPlayer(startingHerdID, true, 1, cStartingHerdMinDist, cStartingHerdMaxDist);

   rmSetProgress(0.4);

   // Gold.
   float avoidGoldMeters = 50.0;

   // Close gold.
   int closeGoldID = rmObjectDefCreate("close gold");
   rmObjectDefAddItem(closeGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidWater);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeGoldID, 60.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeGoldID, false, 1, 60.0, 70.0, avoidGoldMeters, cBiasForward);
      if(xsRandBool(0.5) == true)
      {
         addObjectLocsPerPlayer(closeGoldID, false, 1, 70.0, 80.0, avoidGoldMeters, cBiasForward);
      }
   }
   else
   {
      addObjectLocsPerPlayer(closeGoldID, false, 1, 60.0, 70.0, avoidGoldMeters);
      if(xsRandBool(0.5) == true)
      {
         addObjectLocsPerPlayer(closeGoldID, false, 1, 70.0, 80.0, avoidGoldMeters);
      }
   }

   // Bonus gold.
   int bonusGoldID = rmObjectDefCreate("bonus gold");
   rmObjectDefAddItem(bonusGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidWater);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(bonusGoldID, 70.0);
   addObjectLocsPerPlayer(bonusGoldID, false, xsRandInt(2, 3) * getMapAreaSizeFactor(), 70.0, -1.0, avoidGoldMeters);

   generateLocs("gold locs");

   rmSetProgress(0.5);

   // Hunt.
   float avoidHuntMeters = 50.0;

   // Close hunt.
   int closeHuntID = rmObjectDefCreate("close hunt");
   rmObjectDefAddItem(closeHuntID, cUnitTypeHippopotamus, xsRandInt(2, 4));
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeHuntID, 50.0);
   addObjectLocsPerPlayer(closeHuntID, false, xsRandInt(1, 2), 50.0, 80.0, avoidHuntMeters);

   // Bonus hunt.
   int bonusHuntID = rmObjectDefCreate("bonus hunt");
   rmObjectDefAddItem(bonusHuntID, cUnitTypeWaterBuffalo, xsRandInt(2, 4));
   rmObjectDefAddItem(bonusHuntID, cUnitTypeCrownedCrane, xsRandInt(4, 8));
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(bonusHuntID, 70.0);
   addObjectLocsPerPlayer(bonusHuntID, false, 2, 70.0, -1.0, avoidHuntMeters);

   // Other map sizes hunt.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      float largeMapHuntFloat = xsRandFloat(0.0, 1.0);
      int largeMapHuntID = rmObjectDefCreate("large map hunt");
      if(largeMapHuntFloat < 1.0 / 3.0)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeHippopotamus, xsRandInt(2, 4));
      }
      else if(largeMapHuntFloat < 2.0 / 3.0)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeWaterBuffalo, xsRandInt(2, 5));
      }
      else
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeCrownedCrane, xsRandInt(6, 15));
      }

      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidWater);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidSettlementRange);
      addObjectDefPlayerLocConstraint(largeMapHuntID, 100.0);
      addObjectLocsPerPlayer(largeMapHuntID, false, 1 * getMapSizeBonusFactor(), 100.0, -1.0, avoidHuntMeters);
   }

   // Berries.
   int berriesID = rmObjectDefCreate("berries");
   rmObjectDefAddItem(berriesID, cUnitTypeBerryBush, xsRandInt(7, 13), cBerryClusterRadius);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(berriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(berriesID, vDefaultBerriesAvoidWater);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(berriesID, 70.0);
   addObjectLocsPerPlayer(berriesID, false, 2 * getMapAreaSizeFactor(), 70.0, -1.0, 50.0);

   generateLocs("berries locs");

   // No herdables on this map.

   // Predators.
   float avoidPredatorMeters = 50.0;

   int predatorID = rmObjectDefCreate("predator");
   rmObjectDefAddItem(predatorID, cUnitTypeCrocodile, xsRandInt(2, 3));
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(predatorID, 70.0);
   addObjectLocsPerPlayer(predatorID, false, xsRandInt(2, 3) * getMapAreaSizeFactor(), 70.0, -1.0, avoidPredatorMeters);

   generateLocs("predator locs");

   // Relics.
   float avoidRelicMeters = 80.0;

   int relicID = rmObjectDefCreate("relic");
   rmObjectDefAddItem(relicID, cUnitTypeRelic, 1);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidAll);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidWater);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(relicID, 80.0);
   addObjectLocsPerPlayer(relicID, false, 2 * getMapAreaSizeFactor(), 80.0, -1.0, avoidRelicMeters);

   generateLocs("relic locs");

   rmSetProgress(0.7);
   
   // Forests
   // Forests.
   float avoidForestMeters = 22.0;

   int forestDefID = rmAreaDefCreate("forest");
   rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(40), rmTilesToAreaFraction(80));
   rmAreaDefSetForestType(forestDefID, cForestMarshOak);
   rmAreaDefSetAvoidSelfDistance(forestDefID, avoidForestMeters);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidWater8);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddConstraint(forestDefID, rmCreateClassDistanceConstraint(forestClassID, 16.0));

   // Starting forests.
   if(gameIs1v1() == true)
   {
      addSimAreaLocsPerPlayerPair(forestDefID, 3, cStartingForestMinDist, cStartingForestMaxDist, avoidForestMeters);
   }
   else
   {
      addAreaLocsPerPlayer(forestDefID, 3, cStartingForestMinDist, cStartingForestMaxDist, avoidForestMeters);
   }

   generateLocs("starting forest locs");

   // Global forests.
   // Avoid the owner paths to prevent forests from closing off resources.
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidOwnerPaths, 0.0);
   // rmAreaDefSetConstraintBuffer(forestDefID, 0.0, 6.0);

   // Build for each player in the team area.
   buildAreaDefInTeamAreas(forestDefID, 12 * getMapAreaSizeFactor());

   // Stragglers.
   placeStartingStragglers(cUnitTypeTreeMarsh);

   rmSetProgress(0.8);

   // Embellishment.
   // Gold areas.
   buildAreaUnderObjectDef(startingGoldID, cTerrainMarshGrassRocks2, cTerrainMarshGrassRocks1, 7.0);
   buildAreaUnderObjectDef(closeGoldID, cTerrainMarshGrassRocks2, cTerrainMarshGrassRocks1, 7.0);
   buildAreaUnderObjectDef(bonusGoldID, cTerrainMarshGrassRocks2, cTerrainMarshGrassRocks1, 7.0);

   rmSetProgress(0.9);

   // Random trees.
   int randomTreeID = rmObjectDefCreate("random tree");
   rmObjectDefAddItem(randomTreeID, cUnitTypeTreeMarsh, 1);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidTree);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefPlaceAnywhere(randomTreeID, 0, 6 * cNumberPlayers * getMapAreaSizeFactor());

   // Rocks.
   int rockTinyID = rmObjectDefCreate("rock tiny");
   rmObjectDefAddItem(rockTinyID, cUnitTypeRockNorseTiny, 1);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefPlaceAnywhere(rockTinyID, 0, 50 * cNumberPlayers * getMapAreaSizeFactor());

   int rockSmallID = rmObjectDefCreate("rock small");
   rmObjectDefAddItem(rockSmallID, cUnitTypeRockNorseSmall, 1);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefPlaceAnywhere(rockSmallID, 0, 50 * cNumberPlayers * getMapAreaSizeFactor());

   // Plants.
   int avoidNorseRoad = rmCreateTerrainTypeDistanceConstraint(cTerrainNorseRoad, 1.0);
   
   int plantGrassID = rmObjectDefCreate("plant grass");
   rmObjectDefAddItem(plantGrassID, cUnitTypePlantMarshGrass, 1);
   rmObjectDefAddConstraint(plantGrassID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantGrassID, vDefaultAvoidWater4);
   rmObjectDefPlaceAnywhere(plantGrassID, 0, 40 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantFernID = rmObjectDefCreate("plant fern");
   rmObjectDefAddItemRange(plantFernID, cUnitTypePlantMarshFern, 1, 2, 0.0, 4.0);
   rmObjectDefAddConstraint(plantFernID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantFernID, vDefaultAvoidWater4);
   rmObjectDefPlaceAnywhere(plantFernID, 0, 20 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantWeedsID = rmObjectDefCreate("plant weeds");
   rmObjectDefAddItemRange(plantWeedsID, cUnitTypePlantMarshWeeds, 1, 3, 0.0, 4.0);
   rmObjectDefAddConstraint(plantWeedsID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantWeedsID, vDefaultAvoidWater4);
   rmObjectDefPlaceAnywhere(plantWeedsID, 0, 20 * cNumberPlayers * getMapAreaSizeFactor());

   // Logs.
   int logID = rmObjectDefCreate("log");
   rmObjectDefAddItem(logID, cUnitTypeRottingLog, 1);
   rmObjectDefAddConstraint(logID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(logID, vDefaultAvoidWater4);
   rmObjectDefAddConstraint(logID, vDefaultAvoidSettlementRange);
   rmObjectDefPlaceAnywhere(logID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   // Water lilies.
   int lilyAvoidLand = rmCreateWaterDistanceConstraint(false, 6.0);

   int waterLilyID = rmObjectDefCreate("lily");
   rmObjectDefAddItem(waterLilyID, cUnitTypeWaterLily, 1);
   rmObjectDefAddConstraint(waterLilyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(waterLilyID, lilyAvoidLand);
   rmObjectDefPlaceAnywhere(waterLilyID, 0, 30 * cNumberPlayers * getMapAreaSizeFactor());

   // Reeds.
   int reedAvoidLand = rmCreateWaterDistanceConstraint(false, 2.0);
   int forceReedNearLand = rmCreateWaterMaxDistanceConstraint(false, 4.0);

   int waterReedID = rmObjectDefCreate("reed");
   rmObjectDefAddItem(waterReedID, cUnitTypeWaterReeds, 1);
   rmObjectDefAddConstraint(waterReedID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(waterReedID, reedAvoidLand);
   rmObjectDefAddConstraint(waterReedID, forceReedNearLand);
   rmObjectDefPlaceAnywhere(waterReedID, 0, 40 * cNumberPlayers * getMapAreaSizeFactor());

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeHawk, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   rmSetProgress(1.0);
}
