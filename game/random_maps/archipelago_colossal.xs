include "lib2/rm_core.xs";

void generate()
{
   rmSetProgress(0.0);
   
   // Define Mixes.
   int baseMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.05, 5, 0.5);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainGreekGrass2, 4.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainGreekGrass1, 4.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainGreekGrassDirt1, 4.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainGreekGrassDirt2, 4.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainGreekGrassDirt3, 4.0);

 // Set size.
   int playerTiles=20000;
   int cNumberNonGaiaPlayers = 10;
   if(cMapSizeCurrent == 1)
   {
      playerTiles = 30000;
   }
   int size=2.0*sqrt(cNumberNonGaiaPlayers*playerTiles/0.9);
   rmSetMapSize(size, size);
   rmInitializeWater(cWaterGreekSeaAegean);

   // Player placement.
   rmSetTeamSpacingModifier(1.0);
   rmPlacePlayersOnCircle(0.25 + 0.005 * cNumberPlayers);

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCivFromCulture(cCultureGreek);

   // Lighting.
   rmSetLighting(cLightingSetRmArchipelago01);

   rmSetProgress(0.1);

   // Player areas.
   int playerIslandClassID = rmClassCreate();

   int avoidPlayerIsland = rmCreateClassDistanceConstraint(playerIslandClassID, 0.1);
   int playerIslandAvoidPlayerIsland = rmCreateClassDistanceConstraint(playerIslandClassID, 25.0);

   float playerIslandSize = 0.3 / cNumberPlayers;

   for(int i = 1; i <= cNumberPlayers; i++)
   {
      int p = vDefaultTeamPlayerOrder[i];

      int playerIslandID = rmAreaCreate("player island " + p);
      rmAreaSetSize(playerIslandID, playerIslandSize);
      rmAreaSetMix(playerIslandID, baseMixID);
      rmAreaSetLocPlayer(playerIslandID, p);

      rmAreaSetCoherence(playerIslandID, 0.1);
      rmAreaSetHeight(playerIslandID, 0.5);
      rmAreaSetEdgeSmoothDistance(playerIslandID, 5);
      rmAreaAddHeightBlend(playerIslandID, cBlendEdge, cFilter5x5Box, 10.0, 10.0);

      // rmAreaSetHeightFactors(playerIslandID, 0.25, 0.5, 0.75, 1.0);
      rmAreaSetHeightNoise(playerIslandID, cNoiseFractalSum, 3.0, 0.1, 3, 0.5);
      rmAreaSetHeightNoiseBias(playerIslandID, 1.0); // Only grow upwards.
      rmAreaSetHeightNoiseEdgeFalloffDist(playerIslandID, 20.0);

      rmAreaSetBlobs(playerIslandID, 3, 7);
      rmAreaSetBlobDistance(playerIslandID, 20.0, 40.0);

      rmAreaAddConstraint(playerIslandID, playerIslandAvoidPlayerIsland, 0.0, 10.0);
      rmAreaAddToClass(playerIslandID, playerIslandClassID);
   }

   rmAreaBuildAll();

   // Randomly place some bonus islands.
   int numBonusIslands = xsRandInt(6, 8) * cNumberPlayers * getMapAreaSizeFactor();
   int bonusIslandClassID = rmClassCreate();
   int bonusIslandAvoidBonusIsland = rmCreateClassDistanceConstraint(bonusIslandClassID, 20.0);
   
   float bonusIslandMinSize = rmTilesToAreaFraction(800);
   float bonusIslandMaxSize = rmTilesToAreaFraction(1200);

   for(int i = 1; i <= numBonusIslands; i++)
   {
      int bonusIslandID = rmAreaCreate("bonus island " + i);
      rmAreaSetSize(bonusIslandID, xsRandFloat(bonusIslandMinSize, bonusIslandMaxSize));
      rmAreaSetMix(bonusIslandID, baseMixID);

      rmAreaSetCoherence(bonusIslandID, 0.1);
      rmAreaSetEdgeSmoothDistance(bonusIslandID, 5);
      rmAreaSetHeight(bonusIslandID, 0.5);
      rmAreaSetHeightNoise(bonusIslandID, cNoiseFractalSum, 3.0, 0.1, 3, 0.5);
      rmAreaSetHeightNoiseBias(bonusIslandID, 1.0); // Only grow upwards.
      rmAreaSetHeightNoiseEdgeFalloffDist(bonusIslandID, 20.0);
      rmAreaAddHeightBlend(bonusIslandID, cBlendEdge, cFilter5x5Box, 10.0, 10.0);

      rmAreaSetBlobs(bonusIslandID, 0, 7);
      rmAreaSetBlobDistance(bonusIslandID, 10.0, 30.0);
      
      if (xsRandBool(0.25) == true)
      {
         rmAreaAddConstraint(bonusIslandID, bonusIslandAvoidBonusIsland, 0.0, 10.0);
      }
      
      rmAreaAddToClass(bonusIslandID, bonusIslandClassID);

      rmAreaBuild(bonusIslandID);
   }

   // KotH.
   if (gameIsKotH() == true)
   {
      int islandKotHID = rmAreaCreate("koth island");
      rmAreaSetSize(islandKotHID, xsRandFloat(bonusIslandMinSize, bonusIslandMaxSize));
      rmAreaSetLoc(islandKotHID, cCenterLoc);
      rmAreaSetMix(islandKotHID, baseMixID);

      rmAreaSetCoherence(islandKotHID, 0.1);
      rmAreaSetEdgeSmoothDistance(islandKotHID, 5);
      rmAreaSetHeight(islandKotHID, 0.5);
      rmAreaSetHeightNoise(islandKotHID, cNoiseFractalSum, 3.0, 0.1, 3, 0.5);
      rmAreaSetHeightNoiseBias(islandKotHID, 1.0); // Only grow upwards.
      rmAreaSetHeightNoiseEdgeFalloffDist(islandKotHID, 20.0);
      rmAreaAddHeightBlend(islandKotHID, cBlendEdge, cFilter5x5Box, 10.0, 10.0);

      rmAreaSetBlobs(islandKotHID, 0, 7);
      rmAreaSetBlobDistance(islandKotHID, 10.0, 30.0);
      
      rmAreaAddToClass(islandKotHID, vKotHClassID);
      rmAreaAddToClass(islandKotHID, bonusIslandClassID);

      rmAreaBuild(islandKotHID);
   }

   placeKotHObjects();

   // TODO For 1v1, build a connection if players are not connected?
   // We could also fill up the remaining space with islands.

   rmSetProgress(0.2);

   // Settlements and towers.
   placeStartingTownCenters();

   // Starting towers.
   int startingTowerID = rmObjectDefCreate("starting tower");
   rmObjectDefAddItem(startingTowerID, cUnitTypeSentryTower, 1);
   rmObjectDefAddConstraint(startingTowerID, vDefaultAvoidImpassableLand4);
   addObjectLocsPerPlayer(startingTowerID, true, 4, cStartingTowerMinDist, cStartingTowerMaxDist, cStartingTowerAvoidanceMeters);
   generateLocs("starting tower locs");

   // Settlements.
   int firstSettlementID = rmObjectDefCreate("first settlement");
   rmObjectDefAddItem(firstSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidImpassableLand);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidWater);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidKotH);

   int secondSettlementID = rmObjectDefCreate("second settlement");
   rmObjectDefAddItem(secondSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidImpassableLand);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidWater);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidKotH);

   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(firstSettlementID, false, 1, 50.0, 100.0, cCloseSettlementDist);
      addSimObjectLocsPerPlayerPair(secondSettlementID, false, 1, 50.0, 100.0, cFarSettlementDist);
   }
   else
   {
      addObjectLocsPerPlayer(firstSettlementID, false, 1, 50.0, 100.0, cCloseSettlementDist, cBiasNone, cInAreaPlayer);
      addObjectLocsPerPlayer(secondSettlementID, false, 1, 50.0, 100.0, cFarSettlementDist, cBiasNone, cInAreaPlayer);
   }
   
   // Other map sizes settlements.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int bonusSettlementID = rmObjectDefCreate("bonus settlement");
      rmObjectDefAddItem(bonusSettlementID, cUnitTypeSettlement, 1);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidImpassableLand);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidWater);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidEdge);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidKotH);
      addObjectLocsPerPlayer(bonusSettlementID, false, 1 * getMapAreaSizeFactor(), 90.0, -1.0, 100.0);
   }

   generateLocs("settlement locs");

   rmSetProgress(0.3);

   // Cliffs.
   int cliffClassID = rmClassCreate();
   int numCliffsPerPlayer = xsRandInt(2, 4) * getMapAreaSizeFactor();

   float cliffMinSize = rmTilesToAreaFraction(150);
   float cliffMaxSize = rmTilesToAreaFraction(350);

   int cliffAvoidCliff = rmCreateClassDistanceConstraint(cliffClassID, 30.0);
   int cliffAvoidLand = rmCreatePassabilityDistanceConstraint(cPassabilityLand, true, 15.0);
   int cliffAvoidBuildings = rmCreateTypeDistanceConstraint(cUnitTypeBuilding, 25.0);

   for(int i = 1; i <= cNumberPlayers; i++)
   {
      int p = vDefaultTeamPlayerOrder[i];

      int teamAreaID = vTeamAreaIDs[rmGetPlayerTeam(p)];
      
      for(int j = 0; j < numCliffsPerPlayer; j++)
      {
         int cliffID = rmAreaCreate("cliff " + p + " " + j);
         rmAreaSetParent(cliffID, teamAreaID);

         rmAreaSetSize(cliffID, xsRandFloat(cliffMinSize, cliffMaxSize));
         rmAreaSetTerrainType(cliffID, cTerrainGreekCliff1);
         rmAreaSetCliffType(cliffID, cCliffGreekGrass);
         rmAreaSetCliffSideRadius(cliffID, 0, 2);
         rmAreaSetCliffPaintInsideAsSide(cliffID, true);
         rmAreaSetCliffEmbellishmentDensity(cliffID, 0.25);
         rmAreaAddCliffOuterLayerConstraint(cliffID, vDefaultAvoidWater);
         
         rmAreaSetHeightRelative(cliffID, 11.0);
         rmAreaSetHeightNoise(cliffID, cNoiseFractalSum, 12.0, 0.2, 2, 0.5);
         rmAreaAddHeightBlend(cliffID, cBlendEdge, cFilter5x5Gaussian, 2);

         rmAreaSetCoherence(cliffID, 0.15);
         rmAreaSetEdgeSmoothDistance(cliffID, 2);
         rmAreaSetBlobs(cliffID, 0, 2);
         rmAreaSetBlobDistance(cliffID, 5.0, 15.0);

         if (xsRandBool(0.4) == true)
         {
            rmAreaAddConstraint(cliffID, cliffAvoidLand);
         }
         else
         {
            rmAreaAddConstraint(cliffID, rmCreatePassabilityMaxDistanceConstraint(cPassabilityLand, true, 5.0));
         }
         rmAreaAddToClass(cliffID, cliffClassID);
         rmAreaAddConstraint(cliffID, cliffAvoidCliff);
         rmAreaAddConstraint(cliffID, cliffAvoidBuildings);

         rmAreaBuild(cliffID);
      }
   }

   int resourceAvoidWater = vDefaultAvoidWater12;

   // Starting objects.
   // Starting gold.
   int startingGoldID = rmObjectDefCreate("starting gold");
   rmObjectDefAddItem(startingGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(startingGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(startingGoldID, resourceAvoidWater);
   rmObjectDefAddConstraint(startingGoldID, vDefaultStartingGoldAvoidTower);
   rmObjectDefAddConstraint(startingGoldID, vDefaultForceStartingGoldNearTower);
   addObjectLocsPerPlayer(startingGoldID, false, 1, cStartingGoldMinDist, cStartingGoldMaxDist, cStartingObjectAvoidanceMeters);

   generateLocs("starting gold locs");

   // Starting hunt.
   int startingHuntID = rmObjectDefCreate("starting hunt");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeBoar, 4);
   }
   else
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeAurochs, xsRandInt(3, 4));
   }
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(startingHuntID, resourceAvoidWater);
   rmObjectDefAddConstraint(startingHuntID, vDefaultForceInTowerLOS);
   addObjectLocsPerPlayer(startingHuntID, false, 1, cStartingHuntMinDist, cStartingHuntMaxDist, cStartingObjectAvoidanceMeters);

   // Chicken.
   int startingChickenID = rmObjectDefCreate("starting chicken");
   rmObjectDefAddItem(startingChickenID, cUnitTypeChicken, xsRandInt(6, 10));
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(startingChickenID, resourceAvoidWater);
   addObjectLocsPerPlayer(startingChickenID, false, 1, cStartingChickenMinDist, cStartingChickenMaxDist, cStartingObjectAvoidanceMeters);

   // Berries.
   int startingBerriesID = rmObjectDefCreate("starting berries");
   rmObjectDefAddItem(startingBerriesID, cUnitTypeBerryBush, xsRandInt(6, 10), cBerryClusterRadius);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidImpassableLand);
   rmObjectDefAddConstraint(startingBerriesID, resourceAvoidWater);
   addObjectLocsPerPlayer(startingBerriesID, false, 1, cStartingBerriesMinDist, cStartingBerriesMaxDist, cStartingObjectAvoidanceMeters);

   // Herdables.
   int startingHerdID = rmObjectDefCreate("starting herd");
   rmObjectDefAddItem(startingHerdID, cUnitTypePig, xsRandInt(2, 4));
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(startingHerdID, resourceAvoidWater);
   addObjectLocsPerPlayer(startingHerdID, true, 1, cStartingHerdMinDist, cStartingHerdMaxDist);

   generateLocs("starting food locs");

   rmSetProgress(0.4);

   // Gold.
   float avoidGoldMeters = 40.0;

   // Player gold.
   int playerGoldID = rmObjectDefCreate("player gold");
   rmObjectDefAddItem(playerGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(playerGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(playerGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(playerGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(playerGoldID, resourceAvoidWater);
   rmObjectDefAddConstraint(playerGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(playerGoldID, vDefaultAvoidSettlementRange);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(playerGoldID, false, xsRandInt(3, 4) * getMapAreaSizeFactor(), 50.0, -1.0, avoidGoldMeters, cBiasNone, cInAreaPlayer);
   }
   else
   {
      addObjectLocsPerPlayer(playerGoldID, false, xsRandInt(3, 4) * getMapAreaSizeFactor(), 50.0, -1.0, avoidGoldMeters, cBiasNone, cInAreaPlayer);
   }

   generateLocs("gold locs");

   rmSetProgress(0.5);

   // Hunt.
   float avoidHuntMeters = 30.0;

   // Player hunt.
   int numPlayerHunt = xsRandInt(1, 2);

   for(int i = 0; i < numPlayerHunt; i++)
   {
      float huntFloat = xsRandFloat(0.0, 1.0);
      int playerHuntID = rmObjectDefCreate("player hunt " + i);
      if(huntFloat < 1.0 / 3.0)
      {
         rmObjectDefAddItem(playerHuntID, cUnitTypeDeer, xsRandInt(5, 9));
      }
      else if(huntFloat < 2.0 / 3.0)
      {
         rmObjectDefAddItem(playerHuntID, cUnitTypeBoar, xsRandInt(2, 4));
      }
      else
      {
         rmObjectDefAddItem(playerHuntID, cUnitTypeAurochs, xsRandInt(2, 4));
      }
      rmObjectDefAddConstraint(playerHuntID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(playerHuntID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(playerHuntID, vDefaultFoodAvoidImpassableLand);
      rmObjectDefAddConstraint(playerHuntID, resourceAvoidWater);
      rmObjectDefAddConstraint(playerHuntID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(playerHuntID, vDefaultAvoidSettlementRange);
      addObjectLocsPerPlayer(playerHuntID, false, 1, 50.0, 100.0, avoidHuntMeters, cBiasNone, cInAreaPlayer);
   }

   // Other map sizes hunt.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      float huntFloat = xsRandFloat(0.0, 1.0);
      int largeMapHuntID = rmObjectDefCreate("large map hunt");
      if(huntFloat < 1.0 / 3.0)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeDeer, xsRandInt(6, 13));
      }
      else if(huntFloat < 2.0 / 3.0)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeBoar, xsRandInt(3, 6));
      }
      else
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeAurochs, xsRandInt(2, 5));
      }

      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidImpassableLand);
      rmObjectDefAddConstraint(largeMapHuntID, resourceAvoidWater);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidSettlementRange);
      addObjectLocsPerPlayer(largeMapHuntID, false, 1 * getMapSizeBonusFactor(), 100.0, -1.0, avoidHuntMeters);
   }

   generateLocs("hunt locs");

   rmSetProgress(0.6);

   // Berries.
   float avoidBerriesMeters = 40.0;

   int berriesID = rmObjectDefCreate("berries");
   rmObjectDefAddItem(berriesID, cUnitTypeBerryBush, xsRandInt(5, 9), cBerryClusterRadius);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(berriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(berriesID, vDefaultBerriesAvoidImpassableLand);
   rmObjectDefAddConstraint(berriesID, resourceAvoidWater);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidSettlementRange);
   addObjectLocsPerPlayer(berriesID, false, 1 * getMapSizeBonusFactor(), 50.0, -1.0, avoidBerriesMeters);

   generateLocs("berries locs");

   // Herdables.
   float avoidHerdMeters = 50.0;

   int closeHerdID = rmObjectDefCreate("close herd");
   rmObjectDefAddItem(closeHerdID, cUnitTypePig, 2);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHerdID, resourceAvoidWater);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidTowerLOS);
   addObjectLocsPerPlayer(closeHerdID, false, 2, 50.0, 70.0, avoidHerdMeters, cBiasNone, cInAreaPlayer);

   int bonusHerdID = rmObjectDefCreate("bonus herd");
   rmObjectDefAddItem(bonusHerdID, cUnitTypePig, 2);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusHerdID, resourceAvoidWater);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidTowerLOS);
   addObjectLocsPerPlayer(bonusHerdID, false, 3 * getMapSizeBonusFactor(), 60.0, -1.0, avoidHerdMeters, cBiasNone, cInAreaPlayer);

   generateLocs("herd locs");

   // Predators.
   float avoidPredatorMeters = 40.0;

   int predatorID = objectDefCreateTracked("predator");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(predatorID, cUnitTypeLion, xsRandInt(2, 3));
   }
   else
   {
      rmObjectDefAddItem(predatorID, cUnitTypeWolf, xsRandInt(2, 3));
   }
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(predatorID, 80.0);
   addObjectLocsPerPlayer(predatorID, false, xsRandInt(1, 2) * getMapAreaSizeFactor(), 80.0, -1.0, avoidPredatorMeters);

   generateLocs("predator locs");

   // Relics.
   float avoidRelicMeters = 10.0;

   int relicID = rmObjectDefCreate("relic");
   rmObjectDefAddItem(relicID, cUnitTypeRelic, 1);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidAll);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidImpassableLand);
   rmObjectDefAddConstraint(relicID, resourceAvoidWater);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidSettlementRange);
   addObjectLocsPerPlayer(relicID, false, 2 * getMapAreaSizeFactor(), 60.0, -1.0, avoidRelicMeters);

   generateLocs("relic locs");

   // Forests.
   float avoidForestMeters = 23.0;

   int forestDefID = rmAreaDefCreate("forest");
   rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(60), rmTilesToAreaFraction(100));
   rmAreaDefSetForestType(forestDefID, cForestGreekPalm);
   rmAreaDefSetAvoidSelfDistance(forestDefID, avoidForestMeters);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidImpassableLand8);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidWater4);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidTownCenter);

   rmSetProgress(0.7);

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
   buildAreaDefInTeamAreas(forestDefID, 12 * getMapAreaSizeFactor());

   // Stragglers.
   placeStartingStragglers(cUnitTypeTreePalm);

   rmSetProgress(0.8);

   // Fish.
   int fishAvoidCliff = rmCreateClassDistanceConstraint(cliffClassID, 5.0);

   float fishDistMeters = 25.0;

   int fishID = rmObjectDefCreate("global fish");
   rmObjectDefAddItem(fishID, cUnitTypeHerring, 3, 5.0);
   rmObjectDefAddConstraint(fishID, rmCreatePassabilityDistanceConstraint(cPassabilityLand, true, 6.0));
   rmObjectDefAddConstraint(fishID, fishAvoidCliff);
   rmObjectDefAddConstraint(fishID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(fishID, rmCreateTypeDistanceConstraint(cUnitTypeFishResource, fishDistMeters));
   addObjectLocsPerPlayer(fishID, false, 15 * getMapAreaSizeFactor(), 20.0, -1.0, fishDistMeters, cBiasNone, cInAreaTeam);

   generateLocs("fish locs");

   rmSetProgress(0.9);

   // Embellishment.
   // Gold areas.
   buildAreaUnderObjectDef(startingGoldID, cTerrainGreekGrassRocks2, cTerrainGreekGrassRocks1, 8.0);
   buildAreaUnderObjectDef(playerGoldID, cTerrainGreekGrassRocks2, cTerrainGreekGrassRocks1, 8.0);

   // Berries areas.
   buildAreaUnderObjectDef(startingBerriesID, cTerrainGreekGrass2, cTerrainGreekGrass1, 10.0);
   buildAreaUnderObjectDef(berriesID, cTerrainGreekGrass2, cTerrainGreekGrass1, 10.0);

   // Random trees.
   int randomTreeID = rmObjectDefCreate("random tree");
   rmObjectDefAddItem(randomTreeID, cUnitTypeTreePalm, 1);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidImpassableLand8);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidWater4);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidTree);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefPlaceAnywhere(randomTreeID, 0, 5 * cNumberPlayers * getMapAreaSizeFactor());

   // Rocks.
   int rockTinyID = rmObjectDefCreate("rock tiny");
   rmObjectDefAddItem(rockTinyID, cUnitTypeRockGreekTiny, 1);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefAddConstraint(rockTinyID, vDefaultAvoidWater4);
   rmObjectDefPlaceAnywhere(rockTinyID, 0, 15 * cNumberPlayers * getMapAreaSizeFactor());

   int rockSmallID = rmObjectDefCreate("rock small");
   rmObjectDefAddItem(rockSmallID, cUnitTypeRockGreekSmall, 1);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefPlaceAnywhere(rockSmallID, 0, 15 * cNumberPlayers * getMapAreaSizeFactor());

   // Plants.
   int plantBushID = rmObjectDefCreate("plant bush");
   rmObjectDefAddItem(plantBushID, cUnitTypePlantGreekBush, 1);
   rmObjectDefAddConstraint(plantBushID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantBushID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(plantBushID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefPlaceAnywhere(plantBushID, 0, 30 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantShrubID = rmObjectDefCreate("plant shrub");
   rmObjectDefAddItem(plantShrubID, cUnitTypePlantGreekShrub, 1);
   rmObjectDefAddConstraint(plantShrubID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantShrubID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(plantShrubID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefPlaceAnywhere(plantShrubID, 0, 30 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantGrassID = rmObjectDefCreate("plant grass");
   rmObjectDefAddItem(plantGrassID, cUnitTypePlantGreekGrass, 1);
   rmObjectDefAddConstraint(plantGrassID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantGrassID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(plantGrassID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefPlaceAnywhere(plantGrassID, 0, 40 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantFernID = rmObjectDefCreate("plant fern");
   rmObjectDefAddItem(plantFernID, cUnitTypePlantGreekFern, 1);
   rmObjectDefAddConstraint(plantFernID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantFernID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(plantFernID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefPlaceAnywhere(plantFernID, 0, 15 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantWeedsID = rmObjectDefCreate("plant weeds");
   rmObjectDefAddItem(plantWeedsID, cUnitTypePlantGreekWeeds, 1);
   rmObjectDefAddConstraint(plantWeedsID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantWeedsID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(plantWeedsID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefPlaceAnywhere(plantWeedsID, 0, 15 * cNumberPlayers * getMapAreaSizeFactor());

   // Seaweed.
   int seaweedID = rmObjectDefCreate("seaweed");
   rmObjectDefAddItemRange(seaweedID, cUnitTypeSeaweed, 1, 3);
   rmObjectDefAddConstraint(seaweedID, rmCreateMinWaterDepthConstraint(2.25));
   rmObjectDefPlaceAnywhere(seaweedID, 0, 100 * cNumberPlayers * getMapAreaSizeFactor());

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeHawk, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   rmSetProgress(1.0);
}
