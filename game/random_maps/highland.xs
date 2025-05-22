include "lib2/rm_core.xs";
include "lib2/rm_connections.xs";

void generate()
{
   rmSetProgress(0.0);

   // Define mixes.
   int baseMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.075, 5, 0.5);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseGrass2, 1.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseGrass1, 1.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseGrassDirt1, 1.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseGrassDirt2, 1.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseGrassDirt3, 1.0);

    // Set size.
   int playerTiles=20000;
   int cNumberNonGaiaPlayers = 10;
   if(cMapSizeCurrent == 1)
   {
      playerTiles = 30000;
   }
   int size=2.0*sqrt(cNumberNonGaiaPlayers*playerTiles/0.9);
   rmSetMapSize(size, size);

   rmInitializeWater(cWaterNorseRiverDown);

   // Player placement.
   rmSetTeamSpacingModifier(1.0);

   if (gameIs1v1() == true)
   {
      rmPlacePlayersOnCircle(0.325);
   }
   else
   {
      rmPlacePlayersOnCircle(0.4);
   }

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCivFromCulture(cCultureNorse);

   rmSetProgress(0.1);
   
   // Lighting.
   rmSetLighting(cLightingSetRmHighland01);

   // River width in meters.
   float playerRiverWidth = 45.0;
   float centerRiverWidth = 35.0;

   // Chance for center island for games that are not 1v1.
   int playerIslandAvoidCenter = cInvalidID;

   if(gameIs1v1() == false)
   {
      float centerFraction = 0.0075;

      // TODO Do we really want a chance for this NOT to happen?
      if(xsRandBool(0.5) == true)
      {
         int centerIslandID = rmAreaCreate("center island");
         rmAreaSetLoc(centerIslandID, cCenterLoc);
         rmAreaSetSize(centerIslandID, centerFraction);
         rmAreaSetTerrainType(centerIslandID, cTerrainNorseGrass1);

         rmAreaSetHeight(centerIslandID, 0.5);
         rmAreaAddHeightBlend(centerIslandID, cBlendAll, cFilter5x5Gaussian, 10, 5);
         rmAreaSetCoherence(centerIslandID, 0.5);
         rmAreaSetEdgeSmoothDistance(centerIslandID, 10);

         rmAreaBuild(centerIslandID);

         playerIslandAvoidCenter = rmCreateAreaDistanceConstraint(centerIslandID, centerRiverWidth);
      }
      else
      {
         float centerRadiusMeters = rmXFractionToMeters(sqrt(centerFraction / cPi));

         playerIslandAvoidCenter = rmCreateLocDistanceConstraint(cCenterLoc, centerRiverWidth + centerRadiusMeters);
      }
   }

   float connectionWidth = 0.0;

   // Shallows.
   if(gameIs1v1() == true)
   {
      int numCrosses = xsRandInt(2, 3);

      float avoidCenterWidth = 0.0;

      if (numCrosses == 2)
      {
         avoidCenterWidth = rmXFractionToMeters(0.25);
         connectionWidth = 60.0 + (25.0 * getMapAreaSizeFactor());
      }
      else
      {
         avoidCenterWidth = rmXFractionToMeters(0.325);
         connectionWidth = 40.0 + (25.0 * getMapAreaSizeFactor());
      }


      int connectionAvoidCenter = rmCreateLocDistanceConstraint(cCenterLoc, avoidCenterWidth);

      // Player connection definitions.
      // Path.

      int pathDefID = rmPathDefCreate("player connection path");
      // Add cost so the second connection takes the other way around the center.
      rmPathDefSetTerrainCost(pathDefID, cTerrainNorseGrass1, 10.0);
      rmPathDefAddConstraint(pathDefID, connectionAvoidCenter);

      // Areas.
      int pathAreaDefID = rmAreaDefCreate("player connection area");
      // Paint as grass for the second path to avoid, will get overpainted by post load water fixup.
      rmAreaDefSetTerrainType(pathAreaDefID, cTerrainNorseGrass1);
      rmAreaDefSetHeight(pathAreaDefID, -0.8);
      rmAreaDefAddHeightBlend(pathAreaDefID, cBlendAll, cFilter5x5Gaussian);

      createPlayerConnections("player connection 1", pathDefID, pathAreaDefID, connectionWidth);
      createPlayerConnections("player connection 2", pathDefID, pathAreaDefID, connectionWidth);

      // Add Center Crossing if we roll a 3 crossing variation.
      if (numCrosses == 3)
      {
         int centerPathDefID = rmPathDefCreate("player connection center path");
         createPlayerConnections("player connection 3", centerPathDefID, pathAreaDefID, connectionWidth);
      }
   }
   else
   {
      // Player connection definitions.
      // Path.
      int pathDefID = rmPathDefCreate("player connection path");
      // No params to set here, we want direct paths.

      // Areas.
      int pathAreaDefID = rmAreaDefCreate("player connection area");
      // Water depth is 3.0.
      rmAreaDefSetTerrainType(pathAreaDefID, cTerrainNorseGrass1);
      rmAreaDefSetHeight(pathAreaDefID, -0.8);
      rmAreaDefAddHeightBlend(pathAreaDefID, cBlendAll, cFilter5x5Gaussian);
      
      connectionWidth = 55.0 + (25.0 * getMapAreaSizeFactor());

      createPlayerConnections("player connection", pathDefID, pathAreaDefID, connectionWidth);
   }

   rmSetProgress(0.2);

   // Player areas.
   int playerIslandClassID = rmClassCreate();
   int avoidPlayerIsland = rmCreateClassDistanceConstraint(playerIslandClassID, 0.1);
   int playerIslandAvoidPlayerIsland = rmCreateClassDistanceConstraint(playerIslandClassID, playerRiverWidth);

   for(int i = 1; i <= cNumberPlayers; i++)
   {
      int playerIslandID = rmAreaCreate("player island " + i);
      rmAreaSetSize(playerIslandID, 1.0);
      rmAreaSetMix(playerIslandID, baseMixID);
      rmAreaSetLocPlayer(playerIslandID, i);

      // TODO Might need more coherence and smooth distance here.
      rmAreaSetCoherence(playerIslandID, 0.0);
      // rmAreaSetEdgeSmoothDistance(playerIslandID, 10, false);
      rmAreaSetHeight(playerIslandID, 0.5);
      rmAreaSetHeightNoise(playerIslandID, cNoiseFractalSum, 3.0, 0.1, 2, 0.5);
      rmAreaSetHeightNoiseBias(playerIslandID, 1.0); // Grow upwards only.
      rmAreaSetHeightNoiseEdgeFalloffDist(playerIslandID, 10.0); // Avoid shore.
      rmAreaAddHeightBlend(playerIslandID, cBlendAll, cFilter5x5Gaussian, 10, 3);

      rmAreaAddConstraint(playerIslandID, playerIslandAvoidPlayerIsland);
      if(gameIs1v1() == false)
      {
         rmAreaAddConstraint(playerIslandID, playerIslandAvoidCenter);
      }
      rmAreaAddToClass(playerIslandID, playerIslandClassID);
   }

   rmAreaBuildAll();

   rmSetProgress(0.3);

   // KotH.
   if (gameIsKotH() == true)
   {
      int islandKotHID = rmAreaCreate("koth island");
      rmAreaSetSize(islandKotHID, rmRadiusToAreaFraction(26.0 + cNumberPlayers));
      rmAreaSetLoc(islandKotHID, cCenterLoc);
      //rmAreaSetMix(islandKotHID, baseMixID);

      rmAreaSetCoherence(islandKotHID, 0.5);
      rmAreaSetEdgeSmoothDistance(islandKotHID, 5);
      rmAreaSetHeight(islandKotHID, -1.0);
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
   rmObjectDefAddConstraint(startingTowerID, vDefaultAvoidAll);
   addObjectLocsPerPlayer(startingTowerID, true, 4, cStartingTowerMinDist, cStartingTowerMaxDist, cStartingTowerAvoidanceMeters);
   generateLocs("starting tower locs");

   // Settlements.
   int firstSettlementID = rmObjectDefCreate("first settlement");
   rmObjectDefAddItem(firstSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidImpassableLand);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidSiegeShipRange);

   int secondSettlementID = rmObjectDefCreate("second settlement");
   rmObjectDefAddItem(secondSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidImpassableLand);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidSiegeShipRange);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidKotH);

   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(firstSettlementID, false, 1, 80.0, 100.0, cSettlementDist1v1, cBiasBackward);
      addSimObjectLocsPerPlayerPair(secondSettlementID, false, 1, 80.0, 120.0, cSettlementDist1v1, cBiasAggressive);
   }
   else
   {
      addObjectLocsPerPlayer(firstSettlementID, false, 1, 60.0, 80.0, cCloseSettlementDist, cBiasBackward | cBiasAllyInside);
      addObjectLocsPerPlayer(secondSettlementID, false, 1, 60.0, 100.0, cFarSettlementDist, cBiasAggressive | cBiasAllyInside);
   }
   
   // Other map sizes settlements.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int bonusSettlementID = rmObjectDefCreate("bonus settlement");
      rmObjectDefAddItem(bonusSettlementID, cUnitTypeSettlement, 1);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidEdge);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidImpassableLand);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidCorner40);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidSiegeShipRange);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidKotH);
      addObjectLocsPerPlayer(bonusSettlementID, false, 1 * getMapAreaSizeFactor(), 90.0, -1.0, 100.0);
   }

   generateLocs("settlement locs");

   rmSetProgress(0.4);

   // Continent cliffs.
   int cliffClassID = rmClassCreate();
   int numCliffsPerPlayer = 3 * getMapAreaSizeFactor();

   float cliffMinSize = rmTilesToAreaFraction(425);
   float cliffMaxSize = rmTilesToAreaFraction(500);

   int cliffAvoidCliff = rmCreateClassDistanceConstraint(cliffClassID, 30.0);

   for(int i = 1; i <= cNumberPlayers; i++)
   {
      int p = vDefaultTeamPlayerOrder[i];

      int cliffPlayerAreaID = rmAreaGetID("player island " + p);

      for(int j = 0; j < numCliffsPerPlayer; j++)
      {
         int cliffID = rmAreaCreate("cliff " + p + " " + j);
         rmAreaSetParent(cliffID, cliffPlayerAreaID);

         rmAreaSetSize(cliffID, xsRandFloat(cliffMinSize, cliffMaxSize));
         rmAreaAddTerrainLayer(cliffID, cTerrainNorseCliff1, 0);
         rmAreaSetMix(cliffID, baseMixID);

         rmAreaSetCliffType(cliffID, cCliffNorseGrass);
         if (xsRandBool(0.5) == true)
         {
            rmAreaSetCliffRamps(cliffID, 3, 0.125, 0.1, 1.0);
         }
         else
         {
            rmAreaSetCliffRamps(cliffID, 2, 0.2, 0.1, 1.0);
         }
         rmAreaSetCliffRampSteepness(cliffID, 1.5);
         rmAreaSetCliffEmbellishmentDensity(cliffID, 0.25);
         
         rmAreaSetHeightRelative(cliffID, 7.0);
         rmAreaAddHeightBlend(cliffID, cBlendAll, cFilter5x5Gaussian);
         rmAreaSetEdgeSmoothDistance(cliffID, 10);
         rmAreaSetCoherence(cliffID, 0.25);

         rmAreaAddConstraint(cliffID, vDefaultAvoidTowerLOS);
         if (gameIs1v1() == true)
         {
            rmAreaAddConstraint(cliffID, vDefaultAvoidWater8, 1.0, 4.0);
         }
         else
         {
            rmAreaAddConstraint(cliffID, vDefaultAvoidWater4, 1.0, 4.0);
         }
         rmAreaAddConstraint(cliffID, vDefaultAvoidSettlementRange);
         rmAreaAddConstraint(cliffID, cliffAvoidCliff);
         rmAreaSetOriginConstraintBuffer(cliffID, 10.0);

         rmAreaAddToClass(cliffID, cliffClassID);

         rmAreaBuild(cliffID);
      }
   }

   rmSetProgress(0.5);

   // Embellishment.
   // Base beautification.
   int baseBeautificationClassID = rmClassCreate();
   float baseBeautificationSize = rmRadiusToAreaFraction(20.0);

   for(int i = 1; i <= cNumberPlayers; i++)
   {
      int p = vDefaultTeamPlayerOrder[i];

      int baseBeautificationAreaID = rmAreaCreate("base area beautification " + p);
      rmAreaSetLocPlayer(baseBeautificationAreaID, p);
      rmAreaSetSize(baseBeautificationAreaID, baseBeautificationSize);
      rmAreaSetTerrainType(baseBeautificationAreaID, cTerrainNorseGrassDirt2);
      rmAreaAddTerrainLayer(baseBeautificationAreaID, cTerrainNorseGrassDirt1, 0, 1);

      rmAreaAddToClass(baseBeautificationAreaID, baseBeautificationClassID);
   }

   rmAreaBuildAll();

   int beautificationAvoidBase = rmCreateClassDistanceConstraint(baseBeautificationClassID, 0.1);

   rmSetProgress(0.6);

   // Beautification.
   int beautificationArea1ID = rmAreaDefCreate("beautification 1");
   rmAreaDefSetTerrainType(beautificationArea1ID, cTerrainNorseGrassRocks1);
   rmAreaDefSetSizeRange(beautificationArea1ID, rmTilesToAreaFraction(5), rmTilesToAreaFraction(20));
   rmAreaDefAddConstraint(beautificationArea1ID, vDefaultAvoidWater);
   rmAreaDefAddConstraint(beautificationArea1ID, vDefaultAvoidImpassableLand4);
   rmAreaDefSetAvoidSelfDistance(beautificationArea1ID, 1.0);
   rmAreaDefCreateAndBuildAreas(beautificationArea1ID, 15 * cNumberPlayers * getMapAreaSizeFactor());

   int beautificationArea2ID = rmAreaDefCreate("beautification 2");
   rmAreaDefSetTerrainType(beautificationArea2ID, cTerrainNorseGrassRocks2);
   rmAreaDefSetSizeRange(beautificationArea2ID, rmTilesToAreaFraction(5), rmTilesToAreaFraction(10));
   rmAreaDefAddConstraint(beautificationArea2ID, vDefaultAvoidWater);
   rmAreaDefAddConstraint(beautificationArea2ID, vDefaultAvoidImpassableLand4);
   rmAreaDefSetAvoidSelfDistance(beautificationArea2ID, 1.0);
   rmAreaDefCreateAndBuildAreas(beautificationArea2ID, 15 * cNumberPlayers * getMapAreaSizeFactor());

   rmSetProgress(0.7);

   // Starting objects.
   // Starting gold.
   int startingGoldID = rmObjectDefCreate("starting gold");
   rmObjectDefAddItem(startingGoldID, cUnitTypeMineGoldMedium, 1);
   rmObjectDefAddConstraint(startingGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingGoldID, vDefaultAvoidImpassableLand);
   rmObjectDefAddConstraint(startingGoldID, vDefaultStartingGoldAvoidTower);
   rmObjectDefAddConstraint(startingGoldID, vDefaultForceStartingGoldNearTower);
   addObjectLocsPerPlayer(startingGoldID, false, 1, cStartingGoldMinDist, cStartingGoldMaxDist, cStartingObjectAvoidanceMeters, cBiasNotAggressive);

   generateLocs("starting gold locs");

   // Starting hunt.
   int startingHuntID = rmObjectDefCreate("starting hunt");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeAurochs, xsRandInt(2, 3));
      rmObjectDefAddItem(startingHuntID, cUnitTypeDeer, xsRandInt(3, 4));
   }
   else
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeBoar, xsRandInt(3, 4));
      rmObjectDefAddItem(startingHuntID, cUnitTypeDeer, xsRandInt(2, 3));
   }
   rmObjectDefAddConstraint(startingHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(startingHuntID, vDefaultForceInTowerLOS);
   addObjectLocsPerPlayer(startingHuntID, false, 1, cStartingHuntMinDist, cStartingHuntMaxDist, cStartingObjectAvoidanceMeters);

   // Berries.
   int startingBerriesID = rmObjectDefCreate("starting berries");
   rmObjectDefAddItem(startingBerriesID, cUnitTypeBerryBush, xsRandInt(6, 9), cBerryClusterRadius);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidImpassableLand);
   addObjectLocsPerPlayer(startingBerriesID, false, 1, cStartingBerriesMinDist, cStartingBerriesMaxDist, cStartingObjectAvoidanceMeters);

   // Chicken.
   int startingChickenID = rmObjectDefCreate("starting chicken");
   rmObjectDefAddItem(startingChickenID, cUnitTypeChicken, xsRandInt(5, 9));
   rmObjectDefAddConstraint(startingChickenID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidImpassableLand);
   addObjectLocsPerPlayer(startingChickenID, false, 1, cStartingChickenMinDist, cStartingChickenMaxDist, cStartingObjectAvoidanceMeters);

   // Herdables.
   int startingHerdID = rmObjectDefCreate("starting herd");
   rmObjectDefAddItem(startingHerdID, cUnitTypeCow, 2);
   rmObjectDefAddConstraint(startingHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidImpassableLand);
   addObjectLocsPerPlayer(startingHerdID, true, 1, cStartingHerdMinDist, cStartingHerdMaxDist);

   generateLocs("starting food locs");

   // Gold.
   float avoidGoldMeters = 50.0;

   // Close gold.
   int closeGoldID = rmObjectDefCreate("close gold");
   rmObjectDefAddItem(closeGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidWater);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeGoldID, 55.0);
   if(gameIs1v1() == true)
   {
      addMirroredObjectLocsPerPlayerPair(closeGoldID, false, 1, 55.0, 70.0, avoidGoldMeters);
      addSimObjectLocsPerPlayerPair(closeGoldID, false, 1, 55.0, 70.0, avoidGoldMeters, cBiasForward);
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
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidWater);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(bonusGoldID, 80.0);

   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusGoldID, false, xsRandInt(2, 3) * getMapAreaSizeFactor(), 70.0, -1.0, avoidGoldMeters);
   }
   else
   {
      addObjectLocsPerPlayer(bonusGoldID, false, 4 * getMapAreaSizeFactor(), 70.0, -1.0, avoidGoldMeters);
   }

   generateLocs("gold locs");

   // Hunt.
   float avoidHuntMeters = 30.0;

   // Close hunt 1.
   int closeHunt1ID = rmObjectDefCreate("close hunt 1");
   rmObjectDefAddItem(closeHunt1ID, cUnitTypeDeer, xsRandInt(4, 8));
   rmObjectDefAddConstraint(closeHunt1ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHunt1ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHunt1ID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHunt1ID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(closeHunt1ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHunt1ID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeHunt1ID, 50.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeHunt1ID, false, 1, 50.0, 80.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(closeHunt1ID, false, 1, 50.0, 80.0, avoidHuntMeters);
   }

   // Close hunt 2.
   int closeHunt2ID = rmObjectDefCreate("close hunt 2");
   rmObjectDefAddItem(closeHunt2ID, cUnitTypeBoar, xsRandInt(2, 5));
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(closeHunt2ID, cUnitTypeAurochs, xsRandInt(2, 4));
   }
   rmObjectDefAddConstraint(closeHunt2ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHunt2ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHunt2ID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHunt2ID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(closeHunt2ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHunt2ID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeHunt2ID, 50.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeHunt2ID, false, 1, 50.0, 80.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(closeHunt2ID, false, 1, 50.0, 80.0, avoidHuntMeters);
   }

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
   rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(bonusHuntID, 80.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusHuntID, false, 1, 80.0, -1.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(bonusHuntID, false, 1, 80.0, -1.0, avoidHuntMeters);
   }

   // Other map sizes hunt.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      float largeMapHuntFloat = xsRandFloat(0.0, 1.0);
      int largeMapHuntID = rmObjectDefCreate("large map hunt");
      if(largeMapHuntFloat < 1.0 / 3.0)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeDeer, xsRandInt(6, 12));
      }
      else if(largeMapHuntFloat < 2.0 / 3.0)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeAurochs, xsRandInt(2, 4));
      }
      else
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeBoar, xsRandInt(2, 4));
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeDeer, xsRandInt(3, 6));
      }

      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidImpassableLand);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidWater);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidSettlementRange);
      addObjectDefPlayerLocConstraint(largeMapHuntID, 100.0);
      addObjectLocsPerPlayer(largeMapHuntID, false, 1 * getMapSizeBonusFactor(), 100.0, -1.0, avoidHuntMeters);
   }

   generateLocs("hunt locs");

   // No berries on this map.

   // Herdables.
   float avoidHerdMeters = 50.0;

   int closeHerdID = rmObjectDefCreate("close herd");
   rmObjectDefAddItem(closeHerdID, cUnitTypeCow, xsRandInt(1, 2));
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidWater);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidTowerLOS);
   addObjectDefPlayerLocConstraint(closeHerdID, 50.0);
   addObjectLocsPerPlayer(closeHerdID, false, 1, 50.0, 70.0, avoidHerdMeters);

   int bonusHerdID = rmObjectDefCreate("bonus herd");
   rmObjectDefAddItem(bonusHerdID, cUnitTypeCow, xsRandInt(1, 3));
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidWater);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidTowerLOS);
   addObjectDefPlayerLocConstraint(bonusHerdID, 70.0);
   addObjectLocsPerPlayer(bonusHerdID, false, xsRandInt(2, 3) * getMapAreaSizeFactor(), 70.0, -1.0, avoidHerdMeters);

   generateLocs("herd locs");

   // Predators.
   float avoidPredatorMeters = 50.0;

   int predatorID = rmObjectDefCreate("predator");
   rmObjectDefAddItem(predatorID, cUnitTypeBear, 2);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(predatorID, 80.0);
   addObjectLocsPerPlayer(predatorID, false, 2 * getMapAreaSizeFactor(), 80.0, -1.0, avoidPredatorMeters);

   generateLocs("predator locs");

   // Relics.
   float avoidRelicMeters = 80.0;

   int relicID = rmObjectDefCreate("relic");
   rmObjectDefAddItem(relicID, cUnitTypeRelic, 1);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidAll);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidImpassableLand);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidWater);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(relicID, 80.0);
   addObjectLocsPerPlayer(relicID, false, 2 * getMapAreaSizeFactor(), 80.0, -1.0, avoidRelicMeters);

   generateLocs("relic locs");

   rmSetProgress(0.8);

   // Forests.
   float avoidForestMeters = 30.0;

   int forestDefID = rmAreaDefCreate("forest");
   rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(75), rmTilesToAreaFraction(125));
   rmAreaDefSetForestType(forestDefID, cForestNorsePine);
   rmAreaDefSetAvoidSelfDistance(forestDefID, avoidForestMeters);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidImpassableLand8);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidWater8);
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
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidOwnerPaths, 0.0);
   // rmAreaDefSetConstraintBuffer(forestDefID, 0.0, 6.0);

   // Build for each player in the team area.
   buildAreaDefInTeamAreas(forestDefID, 10 * getMapAreaSizeFactor());

   // Stragglers.
   placeStartingStragglers(cUnitTypeTreePine);

   // Fish.
   float fishDistMeters = 30.0;
   int numFishPerPlayer = 7;
   
   int fishAvoidPlayerIsland = rmCreateClassDistanceConstraint(playerIslandClassID, 12.0);

   if(gameIs1v1() == true)
   {
      numFishPerPlayer = 5;
   }

   int fishID = rmObjectDefCreate("global fish");
   rmObjectDefAddItem(fishID, cUnitTypePerch, 3, 5.0);
   rmObjectDefAddConstraint(fishID, fishAvoidPlayerIsland);
   rmObjectDefAddConstraint(fishID, vDefaultAvoidEdge);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(fishID, false, numFishPerPlayer * getMapAreaSizeFactor(), 20.0, rmGetMapXMeters(), fishDistMeters);
   }
   else
   {
      addObjectLocsPerPlayer(fishID, false, numFishPerPlayer * getMapAreaSizeFactor(), 20.0, rmGetMapXMeters(), fishDistMeters);
   }

   generateLocs("fish locs");

   rmSetProgress(0.9);

   // Embellishment.
   
   // Gold areas.
   buildAreaUnderObjectDef(startingGoldID, cTerrainNorseGrassRocks2, cTerrainNorseGrassRocks1, 6.0);
   buildAreaUnderObjectDef(closeGoldID, cTerrainNorseGrassRocks2, cTerrainNorseGrassRocks1, 6.0);
   buildAreaUnderObjectDef(bonusGoldID, cTerrainNorseGrassRocks2, cTerrainNorseGrassRocks1, 6.0);

   // Berries areas.
   buildAreaUnderObjectDef(startingBerriesID, cTerrainNorseGrass2, cTerrainNorseGrass1, 10.0);

   // Random trees.
   int randomTreeID = rmObjectDefCreate("random tree");
   rmObjectDefAddItem(randomTreeID, cUnitTypeTreePine, 1);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidImpassableLand);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidWater);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidTree);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefPlaceAnywhere(randomTreeID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   // Rocks.
   int rockTinyID = rmObjectDefCreate("rock tiny");
   rmObjectDefAddItem(rockTinyID, cUnitTypeRockNorseTiny, 1);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefPlaceAnywhere(rockTinyID, 0, 35 * cNumberPlayers * getMapAreaSizeFactor());

   int rockSmallID = rmObjectDefCreate("rock small");
   rmObjectDefAddItem(rockSmallID, cUnitTypeRockNorseSmall, 1);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefPlaceAnywhere(rockSmallID, 0, 35 * cNumberPlayers * getMapAreaSizeFactor());

   // Plants.
   int grassID = rmObjectDefCreate("grass");
   rmObjectDefAddItem(grassID, cUnitTypePlantNorseGrass, 1);
   rmObjectDefAddConstraint(grassID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(grassID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(grassID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefPlaceAnywhere(grassID, 0, 35 * cNumberPlayers * getMapAreaSizeFactor());

   int weedsID = rmObjectDefCreate("weeds");
   rmObjectDefAddItemRange(weedsID, cUnitTypePlantNorseWeeds, 1, 3, 0.0, 4.0);
   rmObjectDefAddConstraint(weedsID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(weedsID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(weedsID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefPlaceAnywhere(weedsID, 0, 40 * cNumberPlayers * getMapAreaSizeFactor());
   
   int shrubID = rmObjectDefCreate("shrub");
   rmObjectDefAddItemRange(shrubID, cUnitTypePlantNorseShrub, 1, 3, 0.0, 4.0);
   rmObjectDefAddConstraint(shrubID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(shrubID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(shrubID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefPlaceAnywhere(shrubID, 0, 30 * cNumberPlayers * getMapAreaSizeFactor());

   // Seaweed.
   int seaweedID = rmObjectDefCreate("seaweed");
   rmObjectDefAddItemRange(seaweedID, cUnitTypeSeaweed, 1, 3);
   rmObjectDefAddConstraint(seaweedID, rmCreateMinWaterDepthConstraint(0.5));
   rmObjectDefAddConstraint(seaweedID, rmCreateMaxWaterDepthConstraint(1.0));
   rmObjectDefPlaceAnywhere(seaweedID, 0, 20 * cNumberPlayers * getMapAreaSizeFactor());

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeHawk, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   rmSetProgress(1.0);
}
