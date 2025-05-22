include "lib2/rm_core.xs";
include "lib2/rm_connections.xs";

void generate()
{
   rmSetProgress(0.0);

   // Define mixes.
   int baseMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.10, 5, 0.5);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainGreekGrassDirt1, 4.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainGreekGrass1, 4.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainGreekSnowGrass3, 4.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainGreekSnowGrass2, 4.0);

 // Set size.
   int playerTiles=20000;
   int cNumberNonGaiaPlayers = 10;
   if(cMapSizeCurrent == 1)
   {
      playerTiles = 30000;
   }
   int size=2.0*sqrt(cNumberNonGaiaPlayers*playerTiles/0.9);
   rmSetMapSize(size, size);
   rmInitializeWater(cWaterGreekSea);

   // Player placement.
   // TODO Consider using a smaller value here for 1v1.
   rmSetTeamSpacingModifier(0.8);
   rmPlacePlayersOnCircle(0.375);

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCivFromCulture(cCultureGreek);

   // Lighting.
   rmSetLighting(cLightingSetRmBlackSea01);

   rmSetProgress(0.1);

   // Fake center area to avoid for player continents.
   int fakeCenterID = rmAreaCreate("fake center");
   rmAreaSetSize(fakeCenterID, 0.09);
   rmAreaSetLoc(fakeCenterID, cCenterLoc);

   int avoidFakeCenter = rmCreateAreaDistanceConstraint(fakeCenterID, 0.1);

   // Team continents.
   float riverWidth = 0.0;
   int teamContinentClassID = rmClassCreate();
   if (cNumberPlayers < 5)
   {
      riverWidth = 25.0 * getMapAreaSizeFactor();
   }
   else if (cNumberPlayers < 9)
   {
      riverWidth = 35.0 * getMapAreaSizeFactor();
   }
   else
   {
      riverWidth = 45.0 * getMapAreaSizeFactor();
   }
   
   rmSetProgress(0.2);
   
   int teamContinentAvoidTeamContinent = rmCreateClassDistanceConstraint(teamContinentClassID, riverWidth);

   for(int i = 1; i <= cNumberTeams; i++)
   {      
      int teamContinentID = rmAreaCreate("team continent " + i);
      rmAreaSetSize(teamContinentID, 1.0);
      rmAreaSetMix(teamContinentID, baseMixID);
      rmAreaSetLocTeam(teamContinentID, i);

      rmAreaSetHeight(teamContinentID, 0.5);
      rmAreaAddHeightBlend(teamContinentID, cBlendEdge, cFilter5x5Box, 5, 5);
      rmAreaSetHeightNoise(teamContinentID, cNoiseFractalSum, 4.0, 0.1, 1);
      rmAreaSetHeightNoiseBias(teamContinentID, 1.0); // Only grow upwards.
      rmAreaSetHeightNoiseEdgeFalloffDist(teamContinentID, 20.0);

      // Higher coherence gives smoother rivers.
      rmAreaSetEdgeSmoothDistance(teamContinentID, 5, false);
      rmAreaSetCoherence(teamContinentID, 0.25);
   
      rmAreaAddConstraint(teamContinentID, avoidFakeCenter);
      rmAreaAddConstraint(teamContinentID, teamContinentAvoidTeamContinent);
      //rmAreaSetConstraintBuffer(teamContinentID, 0.0, 5.0);
      rmAreaAddToClass(teamContinentID, teamContinentClassID);

      // Register this as the team's area so location generation uses that instead.
      vTeamAreaIDs[i] = teamContinentID;
   }

   rmSetProgress(0.3);
   
   // Hybrid connections.
   if(gameIs1v1() == true)
   {
      int connectionAvoidCenter = rmCreateLocDistanceConstraint(cCenterLoc, rmXFractionToMeters(0.3));

      // Player connection definitions.
      // Path.
      int pathDefID = rmPathDefCreate("player connection path");
      // Add cost so the second connection takes the other way around the center.
      rmPathDefSetTerrainCost(pathDefID, cTerrainGreekGrass1, 10.0);
      rmPathDefAddConstraint(pathDefID, connectionAvoidCenter);

      // Areas.
      int pathAreaDefID = rmAreaDefCreate("player connection area");
      // Water depth is 3.0.
      rmAreaDefSetTerrainType(pathAreaDefID, cTerrainGreekGrass1);
      rmAreaDefSetHeight(pathAreaDefID, -0.99);
      rmAreaDefAddHeightBlend(pathAreaDefID, cBlendAll, cFilter5x5Gaussian);

      createPlayerConnections("player connection 1", pathDefID, pathAreaDefID, 40.0 * getMapAreaSizeFactor());
      createPlayerConnections("player connection 2", pathDefID, pathAreaDefID, 40.0 * getMapAreaSizeFactor());
   }
   else if (gameIsFair() == true)
   {
      int connectionAvoidCenter = rmCreateLocDistanceConstraint(cCenterLoc, rmXFractionToMeters(0.3));
      // Player connection definitions.
      // Path.
      int pathDefID = rmPathDefCreate("team connection path");
      rmPathDefSetTerrainCost(pathDefID, cTerrainGreekGrass1, 10.0);
      rmPathDefAddConstraint(pathDefID, connectionAvoidCenter);

      // Areas.
      int pathAreaDefID = rmAreaDefCreate("team connection area");
      // Water depth is 3.0.
      rmAreaDefSetTerrainType(pathAreaDefID, cTerrainGreekGrass1);
      rmAreaDefSetHeight(pathAreaDefID, -0.99);
      rmAreaDefAddHeightBlend(pathAreaDefID, cBlendAll, cFilter5x5Gaussian);

      createPlayerConnections("player connection", pathDefID, pathAreaDefID, 40.0  * getMapAreaSizeFactor());
   }
   else
   {
      int connectionAvoidCenter = rmCreateLocDistanceConstraint(cCenterLoc, rmXFractionToMeters(0.3));
      // Player connection definitions.
      // Path.
      int pathDefID = rmPathDefCreate("team connection path");
      rmPathDefSetTerrainCost(pathDefID, cTerrainGreekGrass1, 10.0);
      rmPathDefAddConstraint(pathDefID, connectionAvoidCenter);

      // Areas.
      int pathAreaDefID = rmAreaDefCreate("team connection area");
      // Water depth is 3.0.
      rmAreaDefSetTerrainType(pathAreaDefID, cTerrainGreekGrass1);
      rmAreaDefSetHeight(pathAreaDefID, -0.99);
      rmAreaDefAddHeightBlend(pathAreaDefID, cBlendAll, cFilter5x5Gaussian);

      createTeamConnections("team connection", pathDefID, pathAreaDefID, 40.0  * getMapAreaSizeFactor(), 0.0, true);   
   }

   rmAreaBuildAll();
   
   rmSetProgress(0.4);
   
   // KotH.
   if (gameIsKotH() == true)
   {
      int islandKotHID = rmAreaCreate("koth island");
      rmAreaSetSize(islandKotHID, rmRadiusToAreaFraction(26.0 + cNumberPlayers));
      rmAreaSetLoc(islandKotHID, cCenterLoc);
      rmAreaSetMix(islandKotHID, baseMixID);

      rmAreaSetCoherence(islandKotHID, 0.5);
      rmAreaSetEdgeSmoothDistance(islandKotHID, 5);
      rmAreaSetHeight(islandKotHID, 0.5);
      rmAreaSetHeightNoise(islandKotHID, cNoiseFractalSum, 3.0, 0.1, 3, 0.5);
      rmAreaSetHeightNoiseBias(islandKotHID, 1.0); // Only grow upwards.
      rmAreaSetHeightNoiseEdgeFalloffDist(islandKotHID, 20.0);
      rmAreaAddHeightBlend(islandKotHID, cBlendEdge, cFilter5x5Box, 10.0, 5.0);
      
      rmAreaAddToClass(islandKotHID, vKotHClassID);

      rmAreaBuild(islandKotHID);
   }

   placeKotHObjects();

   // Settlements and towers.
   placeStartingTownCenters();

   // Starting towers.
   int startingTowerID = rmObjectDefCreate("starting tower");
   rmObjectDefAddItem(startingTowerID, cUnitTypeSentryTower, 1);
   rmObjectDefAddConstraint(startingTowerID, vDefaultAvoidImpassableLand4);
   addObjectLocsPerPlayer(startingTowerID, true, 4, cStartingTowerMinDist, cStartingTowerMaxDist, cStartingTowerAvoidanceMeters);
   generateLocs("starting tower locs");

   rmSetProgress(0.5);

   // Settlements.
   int firstSettlementID = rmObjectDefCreate("first settlement");
   rmObjectDefAddItem(firstSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidSiegeShipRange);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidTowerLOS);

   int secondSettlementID = rmObjectDefCreate("second settlement");
   rmObjectDefAddItem(secondSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidSiegeShipRange);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidKotH);

   if(gameIs1v1() == true || true)
   {
      addSimObjectLocsPerPlayerPair(firstSettlementID, false, 1, 60.0, 80.0, cSettlementDist1v1, cBiasBackward, cInAreaPlayer);
      addSimObjectLocsPerPlayerPair(secondSettlementID, false, 1, 60.0, 120.0, cSettlementDist1v1, cBiasForward, cInAreaPlayer);
   }
   else if (gameIsFair() == true)
   {
      addObjectLocsPerPlayer(firstSettlementID, false, 1, 60.0, 80.0, cCloseSettlementDist, cBiasBackward, cInAreaPlayer);
      addObjectLocsPerPlayer(secondSettlementID, false, 1, 80.0, 120.0, cFarSettlementDist, cBiasForward, cInAreaPlayer);
   }
   else
   {
      addObjectLocsPerPlayer(firstSettlementID, false, 1, 60.0, 90.0, cCloseSettlementDist);
      addObjectLocsPerPlayer(secondSettlementID, false, 1, 60.0, 120.0, cFarSettlementDist);
   }
   
   // Other map sizes settlements.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int bonusSettlementID = rmObjectDefCreate("bonus settlement");
      rmObjectDefAddItem(bonusSettlementID, cUnitTypeSettlement, 1);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidEdge);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidSiegeShipRange);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidKotH);
      addObjectLocsPerPlayer(bonusSettlementID, false, 1 * getMapAreaSizeFactor(), 90.0, -1.0, 100.0);
   }

   generateLocs("settlement locs");

   rmSetProgress(0.6);

   // Starting objects.
   // Starting gold.
   int startingGoldID = rmObjectDefCreate("starting gold");
   rmObjectDefAddItem(startingGoldID, cUnitTypeMineGoldMedium, 1);
   rmObjectDefAddConstraint(startingGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingGoldID, vDefaultGoldAvoidWater);
   rmObjectDefAddConstraint(startingGoldID, vDefaultStartingGoldAvoidTower);
   rmObjectDefAddConstraint(startingGoldID, vDefaultForceStartingGoldNearTower);
   addObjectLocsPerPlayer(startingGoldID, false, 1, cStartingGoldMinDist, cStartingGoldMaxDist, cStartingObjectAvoidanceMeters, cBiasNotAggressive);

   generateLocs("starting gold locs");

   // Berries.
   int startingBerriesID = rmObjectDefCreate("starting berries");
   rmObjectDefAddItem(startingBerriesID, cUnitTypeBerryBush, xsRandInt(5, 9), cBerryClusterRadius);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidWater);
   addObjectLocsPerPlayer(startingBerriesID, false, 1, cStartingBerriesMinDist, cStartingBerriesMaxDist, cStartingObjectAvoidanceMeters);

   // Starting hunt.
   int startingHuntID = rmObjectDefCreate("starting hunt");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeAurochs, 3);
   }
   else
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeBoar, 4);
   }
   rmObjectDefAddConstraint(startingHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(startingHuntID, vDefaultForceInTowerLOS);
   addObjectLocsPerPlayer(startingHuntID, false, 1, cStartingHuntMinDist, cStartingHuntMaxDist, cStartingObjectAvoidanceMeters);

   // Chicken.
   int startingChickenID = rmObjectDefCreate("starting chicken");
   rmObjectDefAddItem(startingChickenID, cUnitTypeChicken, xsRandInt(5, 9));
   rmObjectDefAddConstraint(startingChickenID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingChickenID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(startingChickenID, vDefaultHerdAvoidWater);
   addObjectLocsPerPlayer(startingChickenID, false, 1, cStartingChickenMinDist, cStartingChickenMaxDist, cStartingObjectAvoidanceMeters);

   // Herdables.
   int startingHerdID = rmObjectDefCreate("starting herd");
   rmObjectDefAddItem(startingHerdID, cUnitTypeCow, 2);
   rmObjectDefAddConstraint(startingHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidAll);
   addObjectLocsPerPlayer(startingHerdID, true, 1, cStartingHerdMinDist, cStartingHerdMaxDist);

   generateLocs("starting food locs");

   // Gold.
   float avoidGoldMeters = 50.0;

   // Close gold.
   int closeGoldID = rmObjectDefCreate("close gold");
   rmObjectDefAddItem(closeGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidWater);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeGoldID, 60.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeGoldID, false, 1, 60.0, 70.0, avoidGoldMeters, cBiasForward);
   }
   else
   {
      addObjectLocsPerPlayer(closeGoldID, false, 1, 60.0, 70.0, avoidGoldMeters);
   }

   // Bonus gold.
   int bonusGoldID = rmObjectDefCreate("bonus gold");
   rmObjectDefAddItem(bonusGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidWater);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(bonusGoldID, createPlayerLocDistanceConstraint(70.0));

   if(gameIs1v1() == true)
   {
      addObjectLocsPerPlayer(bonusGoldID, false, xsRandInt(2, 3) * getMapAreaSizeFactor(), 70.0, -1.0, avoidGoldMeters);
   }
   else
   {
      addObjectLocsPerPlayer(bonusGoldID, false, xsRandInt(2, 3) * getMapAreaSizeFactor(), 70.0, -1.0, avoidGoldMeters);
   }

   generateLocs("gold locs");

   // Hunt.
   float avoidHuntMeters = 25.0;

   // Close hunt 1.
   int closeHunt1ID = rmObjectDefCreate("close hunt 1");
   rmObjectDefAddItem(closeHunt1ID, cUnitTypeDeer, xsRandInt(6, 8));
   rmObjectDefAddConstraint(closeHunt1ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHunt1ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHunt1ID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(closeHunt1ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHunt1ID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeHunt1ID, 50.0);
   addObjectLocsPerPlayer(closeHunt1ID, false, 1, 50.0, 80.0, avoidHuntMeters);

   // Close hunt 2.
   int closeHunt2ID = rmObjectDefCreate("close hunt 2");
   rmObjectDefAddItem(closeHunt2ID, cUnitTypeBoar, xsRandInt(2, 3));
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(closeHunt2ID, cUnitTypeDeer, xsRandInt(2, 3));
   }
   rmObjectDefAddConstraint(closeHunt2ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHunt2ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHunt2ID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(closeHunt2ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHunt2ID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeHunt2ID, 60.0);
   addObjectLocsPerPlayer(closeHunt2ID, false, 1, 60.0, 90.0, avoidHuntMeters);

   // Bonus hunt.
   int bonusHuntID = rmObjectDefCreate("bonus hunt");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(bonusHuntID, cUnitTypeAurochs, xsRandInt(2, 4));
   }
   else
   {
      rmObjectDefAddItem(bonusHuntID, cUnitTypeBoar, xsRandInt(2, 5));
   }
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(bonusHuntID, 80.0);
   addObjectLocsPerPlayer(bonusHuntID, false, 1, 80.0, -1.0, avoidHuntMeters);

   // Other map sizes hunt.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int largeMapHuntID = rmObjectDefCreate("large map hunt");
      if(xsRandBool(0.5) == true)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeDeer, xsRandInt(4, 8));
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeBoar, xsRandInt(1, 3));
      }
      else
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeAurochs, xsRandInt(2, 5));
      }

      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidWater);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidSettlementRange);
      addObjectDefPlayerLocConstraint(largeMapHuntID, 100.0);
      addObjectLocsPerPlayer(largeMapHuntID, false, 1 * getMapSizeBonusFactor(), 100.0, -1.0, avoidHuntMeters);
   }

   generateLocs("hunt locs");

   // Berries.
   float avoidBerriesMeters = 50.0;

   int berriesID = rmObjectDefCreate("berries");
   rmObjectDefAddItem(berriesID, cUnitTypeBerryBush, xsRandInt(5, 9), cBerryClusterRadius);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(berriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(berriesID, vDefaultBerriesAvoidWater);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidSettlementRange);
   addObjectLocsPerPlayer(berriesID, false, xsRandInt(1, 2) * getMapSizeBonusFactor(), 80.0, -1.0, avoidBerriesMeters);

   generateLocs("berries locs");

   // Herdables.
   float avoidHerdMeters = 50.0;

   int closeHerdID = rmObjectDefCreate("close herd");
   rmObjectDefAddItem(closeHerdID, cUnitTypeCow, xsRandInt(1, 2));
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidWater);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidTowerLOS);
   addObjectLocsPerPlayer(closeHerdID, false, 1, 50.0, 70.0, avoidHerdMeters);

   int bonusHerdID = rmObjectDefCreate("bonus herd");
   rmObjectDefAddItem(bonusHerdID, cUnitTypeCow, xsRandInt(1, 3));
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidWater);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidTowerLOS);
   addObjectLocsPerPlayer(bonusHerdID, false, xsRandInt(2, 3) * getMapSizeBonusFactor(), 70.0, -1.0, avoidHerdMeters);

   generateLocs("herd locs");

   // Predators.
   float avoidPredatorMeters = 50.0;

   int predatorID = rmObjectDefCreate("predator");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(predatorID, cUnitTypeWolf, xsRandInt(1, 2));
   }
   else
   {
      rmObjectDefAddItem(predatorID, cUnitTypeBear, xsRandInt(1, 3));
   }
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(predatorID, 80.0);
   addObjectLocsPerPlayer(predatorID, false, xsRandInt(1, 2) * getMapAreaSizeFactor(), 80.0, -1.0, avoidPredatorMeters);

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

   // Fish.
   float fishDistMeters = 20.0;
   int avoidFish = rmCreateTypeDistanceConstraint(cUnitTypeFishResource, fishDistMeters);

   int fishID = rmObjectDefCreate("fish");
   rmObjectDefAddItem(fishID, cUnitTypeHerring, 3, 6.0);
   rmObjectDefAddConstraint(fishID, rmCreatePassabilityDistanceConstraint(cPassabilityWater, false, 6.0));
   rmObjectDefAddConstraint(fishID, avoidFish);
   rmObjectDefAddConstraint(fishID, vDefaultAvoidEdge);
   // Unchecked.
   rmObjectDefPlaceAnywhere(fishID, 0, 5 * cNumberPlayers * getMapAreaSizeFactor());

   rmSetProgress(0.8);

   // Forests.
   float avoidForestMeters = 35.0;

   int forestDefID = rmAreaDefCreate("forest");
   rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(150), rmTilesToAreaFraction(200));
   rmAreaDefSetForestType(forestDefID, cForestGreekPine);
   rmAreaDefSetAvoidSelfDistance(forestDefID, avoidForestMeters);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidWater10);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidTownCenter);

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
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidOwnerPaths);

   // Build for each player in the team area.
   buildAreaDefInTeamAreas(forestDefID, 10 * getMapAreaSizeFactor());

   // Stragglers.
   placeStartingStragglers(cUnitTypeTreePine);

   rmSetProgress(0.9);

   // Embellishment.
   // Gold areas.
   buildAreaUnderObjectDef(startingGoldID, cTerrainGreekGrassRocks2, cTerrainGreekGrassRocks1, 8.0);
   buildAreaUnderObjectDef(closeGoldID, cTerrainGreekGrassRocks2, cTerrainGreekGrassRocks1, 8.0);
   buildAreaUnderObjectDef(bonusGoldID, cTerrainGreekGrassRocks2, cTerrainGreekGrassRocks1, 8.0);

   // Berries areas.
   buildAreaUnderObjectDef(startingBerriesID, cTerrainGreekGrass2, cTerrainGreekGrass1, 10.0);
   buildAreaUnderObjectDef(berriesID, cTerrainGreekGrass2, cTerrainGreekGrass1, 10.0);


   // Random trees.
   int randomTreeID = rmObjectDefCreate("random tree");
   rmObjectDefAddItem(randomTreeID, cUnitTypeTreePine, 1);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidImpassableLand8);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidWater4);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidTree);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefPlaceAnywhere(randomTreeID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   // Rocks.
   int rockTinyID = rmObjectDefCreate("rock tiny");
   rmObjectDefAddItem(rockTinyID, cUnitTypeRockGreekTiny, 1);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockTinyID, vDefaultAvoidWater4);
   rmObjectDefPlaceAnywhere(rockTinyID, 0, 50 * cNumberPlayers * getMapAreaSizeFactor());

   int rockSmallID = rmObjectDefCreate("rock small");
   rmObjectDefAddItem(rockSmallID, cUnitTypeRockGreekSmall, 1);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockSmallID, vDefaultAvoidWater4);
   rmObjectDefPlaceAnywhere(rockSmallID, 0, 50 * cNumberPlayers * getMapAreaSizeFactor());

   // Plants.
   int plantBushID = rmObjectDefCreate("plant bush");
   rmObjectDefAddItem(plantBushID, cUnitTypePlantGreekBush, 1);
   rmObjectDefAddConstraint(plantBushID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantBushID, vDefaultAvoidWater4);
   rmObjectDefPlaceAnywhere(plantBushID, 0, 30 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantShrubID = rmObjectDefCreate("plant shrub");
   rmObjectDefAddItem(plantShrubID, cUnitTypePlantGreekShrub, 1);
   rmObjectDefAddConstraint(plantShrubID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantShrubID, vDefaultAvoidWater4);
   rmObjectDefPlaceAnywhere(plantShrubID, 0, 30 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantGrassID = rmObjectDefCreate("plant grass");
   rmObjectDefAddItem(plantGrassID, cUnitTypePlantGreekGrass, 1);
   rmObjectDefAddConstraint(plantGrassID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantGrassID, vDefaultAvoidWater4);
   rmObjectDefAddConstraint(plantGrassID, vDefaultAvoidEdge);
   rmObjectDefPlaceAnywhere(plantGrassID, 0, 40 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantFernID = rmObjectDefCreate("plant fern");
   rmObjectDefAddItem(plantFernID, cUnitTypePlantGreekFern, 1);
   rmObjectDefAddConstraint(plantFernID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantFernID, vDefaultAvoidWater4);
   rmObjectDefPlaceAnywhere(plantFernID, 0, 15 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantWeedsID = rmObjectDefCreate("plant weeds");
   rmObjectDefAddItem(plantWeedsID, cUnitTypePlantGreekWeeds, 1);
   rmObjectDefAddConstraint(plantWeedsID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantWeedsID, vDefaultAvoidWater4);
   rmObjectDefPlaceAnywhere(plantWeedsID, 0, 15 * cNumberPlayers * getMapAreaSizeFactor());

   // Seaweed.
   int seaweedID = rmObjectDefCreate("seaweed");
   rmObjectDefAddItem(seaweedID, cUnitTypeSeaweed, 2, 2.0);
   rmObjectDefAddConstraint(seaweedID, vDefaultAvoidImpassableLand);
   rmObjectDefAddConstraint(seaweedID, rmCreateWaterMaxDistanceConstraint(true, 0.0));
   rmObjectDefPlaceAnywhere(seaweedID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeHawk, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   rmSetProgress(1.0);
}
