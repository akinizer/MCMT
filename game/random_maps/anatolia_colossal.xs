include "lib2/rm_core.xs";

void generate()
{
   rmSetProgress(0.0);

   // Define mixes.
   int baseMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.1, 1);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainGreekSnow1, 1.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainGreekSnowGrass1, 2.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainGreekSnowGrass2, 2.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainGreekSnowGrass3, 2.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainGreekGrass2, 3.0);
   
   int shoreMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(shoreMixID, cNoiseFractalSum, 0.2, 1);
   rmCustomMixAddPaintEntry(shoreMixID, cTerrainGreekGrass1, 2.0);
   rmCustomMixAddPaintEntry(shoreMixID, cTerrainGreekGrass2, 2.0);
   rmCustomMixAddPaintEntry(shoreMixID, cTerrainGreekGrassDirt1, 2.0);
   rmCustomMixAddPaintEntry(shoreMixID, cTerrainGreekGrassDirt2, 2.0);
   rmCustomMixAddPaintEntry(shoreMixID, cTerrainGreekGrassDirt3, 2.0);
   
   int cliffMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(cliffMixID, cNoiseFractalSum, 0.15, 1);
   rmCustomMixAddPaintEntry(cliffMixID, cTerrainGreekSnowRocks2, 2.0);
   rmCustomMixAddPaintEntry(cliffMixID, cTerrainGreekSnowGrass1, 3.0);
   rmCustomMixAddPaintEntry(cliffMixID, cTerrainGreekSnowGrass2, 3.0);

   // Water overrides.
   rmWaterTypeAddBeachLayer(cWaterGreekSea, cTerrainGreekBeach1, 3.0, 2.0);
   rmWaterTypeAddBeachLayer(cWaterGreekSea, cTerrainGreekGrassDirt3, 4.0, 2.0);
   rmWaterTypeAddBeachLayer(cWaterGreekSea, cTerrainGreekGrassDirt2, 6.0, 2.0);
   rmWaterTypeAddBeachLayer(cWaterGreekSea, cTerrainGreekGrassDirt1, 8.0, 2.0);
   rmWaterTypeAddBeachLayer(cWaterGreekSea, cTerrainGreekGrass1, 10.0, 2.0);
   rmWaterTypeAddBeachLayer(cWaterGreekSea, cTerrainGreekSnowGrass3, 13.0, 1.0);

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
   if(gameIs1v1() == true)
   {
      placePlayersOnLine(vectorXZ(0.125, 0.5), vectorXZ(0.875, 0.5));
   }
   else if(cNumberTeams < 3)
   {
      int teamInt = xsRandInt(1, 2);
      int otherTeamInt = 3 - teamInt;
      if(rmGetNumberPlayersOnTeam(teamInt) >= 9)
      {
         placeTeamOnLine(teamInt, vectorXZ(0.2, 0.85), vectorXZ(0.2, 0.15));
      }
      else
      {
         placeTeamOnLine(teamInt, vectorXZ(0.2, 0.75), vectorXZ(0.2, 0.25));
      }

      if(rmGetNumberPlayersOnTeam(otherTeamInt) >= 9)
      {
         placeTeamOnLine(otherTeamInt, vectorXZ(0.8, 0.15), vectorXZ(0.8, 0.85));
      }
      else
      {
         placeTeamOnLine(otherTeamInt, vectorXZ(0.8, 0.25), vectorXZ(0.8, 0.75));
      }

   }
   else
   {
      rmPlacePlayersOnSquare(0.275);
   }

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCivFromCulture(cCultureGreek);

   // KotH.
   placeKotHObjects();

   // Lighting.
   rmSetLighting(cLightingSetRmAnatolia01);

   rmSetProgress(0.1);

   // Global elevation.
   rmAddGlobalHeightNoise(cNoiseFractalSum, 5.0, 0.075, 2, 0.5);

   rmAreaBuildAll();
   
   // Create rivers.
   for(int i = 0; i < 2; i++)
   {
      int riverID = rmAreaCreate("river " + i);
      rmAreaSetWaterType(riverID, cWaterGreekSea);
      if(gameIs1v1() == true)
      {
         rmAreaSetSize(riverID, 0.135);
      }
      else
      {
         rmAreaSetSize(riverID, 0.1);
      }

      rmAreaSetCoherence(riverID, 0.25);
      rmAreaSetEdgeSmoothDistance(riverID, 2, false);

      if(i == 0)
      {
         rmAreaSetLoc(riverID, vectorXZ(0.5, 0.01));
         rmAreaAddInfluenceSegment(riverID, vectorXZ(0.0, 0.0), vectorXZ(1.0, 0.0));
      }
      else if(i == 1)
      {
         rmAreaSetLoc(riverID, vectorXZ(0.5, 0.99));
         rmAreaAddInfluenceSegment(riverID, vectorXZ(0.0, 1.0), vectorXZ(1.0, 1.0));
      }
   }

   rmAreaBuildAll();

   rmSetProgress(0.2);

   // Settlements and towers.
   placeStartingTownCenters();

   // Starting towers.
   int startingTowerID = rmObjectDefCreate("starting tower");
   rmObjectDefAddItem(startingTowerID, cUnitTypeSentryTower, 1);
   addObjectLocsPerPlayer(startingTowerID, true, 4, cStartingTowerMinDist, cStartingTowerMaxDist, cStartingTowerAvoidanceMeters);
   generateLocs("starting tower locs");

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

   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(firstSettlementID, false, 1, 60.0, 80.0, cSettlementDist1v1, cBiasBackward);
      addSimObjectLocsPerPlayerPair(secondSettlementID, false, 1, 80.0, 100.0, cSettlementDist1v1, cBiasForward);
   }
   else
   {
      addObjectLocsPerPlayer(firstSettlementID, false, 1, 60.0, 80.0, cCloseSettlementDist, cBiasBackward | cBiasAllyInside);
      addObjectLocsPerPlayer(secondSettlementID, false, 1, 90.0, 110.0, cFarSettlementDist, cBiasForward); // No ally bias.
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

   rmSetProgress(0.3);

   // Cliffs.
   int cliffClassID = rmClassCreate();
   int numCliffs = 2 * cNumberPlayers;

   float cliffMinSize = rmTilesToAreaFraction(200 * getMapAreaSizeFactor());
   float cliffMaxSize = rmTilesToAreaFraction(400 * getMapAreaSizeFactor());
   int cliffAvoidCliff = rmCreateClassDistanceConstraint(cliffClassID, 25.0);
   int cliffAvoidBuildings = rmCreateTypeDistanceConstraint(cUnitTypeBuilding, 22.5);
   int cliffAvoidPlayerCores = createPlayerLocDistanceConstraint(50.0);
   int cliffForceInBox = createSymmetricBoxConstraint(0.125);

   for(int i = 0; i < numCliffs; i++)
   {
      int cliffID = rmAreaCreate("cliff " + i);

      rmAreaSetSize(cliffID, xsRandFloat(cliffMinSize, cliffMaxSize));
      rmAreaSetMix(cliffID, cliffMixID);
      rmAreaSetCliffType(cliffID, cCliffGreekSnow);
      rmAreaSetCliffRamps(cliffID, 2, 0.35, 0.05, 1.0);
      rmAreaSetCliffRampSteepness(cliffID, 2.0);
      rmAreaSetCliffSideRadius(cliffID, 0, 1);
      rmAreaSetCliffEmbellishmentDensity(cliffID, 0.5);
      // Do not paint the outside layer blending to snow.
      rmAreaSetCliffLayerPaint(cliffID, cCliffLayerOuterSideFar, false);

      if (xsRandBool(0.5) == true)
      {
         rmAreaSetHeightRelative(cliffID, -6.0);
      }
      else
      {
         rmAreaSetHeightRelative(cliffID, 5.0);
      }

      rmAreaAddHeightBlend(cliffID, cBlendAll, cFilter5x5Gaussian);
      rmAreaSetEdgeSmoothDistance(cliffID, 4);
      rmAreaSetCoherence(cliffID, 0.4);

      rmAreaAddConstraint(cliffID, vDefaultAvoidEdge);
      rmAreaAddConstraint(cliffID, vDefaultAvoidWater20);
      rmAreaAddConstraint(cliffID, cliffAvoidCliff);
      rmAreaAddConstraint(cliffID, cliffAvoidBuildings);
      rmAreaAddConstraint(cliffID, cliffAvoidPlayerCores);
      rmAreaAddConstraint(cliffID, cliffForceInBox);

      rmAreaSetOriginConstraintBuffer(cliffID, 8.0);

      rmAreaAddToClass(cliffID, cliffClassID);
      
      rmAreaBuild(cliffID);
   }

   rmSetProgress(0.4);

   int defaultAvoidWater = vDefaultAvoidWater20;

   // Starting objects.
   // Starting gold.
   int startingGoldID = rmObjectDefCreate("starting gold");
   rmObjectDefAddItem(startingGoldID, cUnitTypeMineGoldMedium, 1);
   rmObjectDefAddConstraint(startingGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(startingGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(startingGoldID, vDefaultStartingGoldAvoidTower);
   rmObjectDefAddConstraint(startingGoldID, vDefaultForceStartingGoldNearTower);
   addObjectLocsPerPlayer(startingGoldID, false, 2, cStartingGoldMinDist, cStartingGoldMaxDist, cStartingGoldAvoidanceMeters);

   generateLocs("starting gold locs");

   // Starting food.
   float avoidStartingFoodMeters = 1.0 * cStartingObjectAvoidanceMeters;

   // Starting hunt.
   int startingHuntID = rmObjectDefCreate("starting hunt");
   rmObjectDefAddItem(startingHuntID, cUnitTypeBoar, 4, 4.0);
   rmObjectDefAddConstraint(startingHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(startingHuntID, vDefaultForceInTowerLOS);
   addObjectLocsPerPlayer(startingHuntID, false, 1, cStartingHuntMinDist, cStartingHuntMaxDist, avoidStartingFoodMeters);

   // Berries.
   int startingBerriesID = rmObjectDefCreate("starting berries");
   rmObjectDefAddItem(startingBerriesID, cUnitTypeBerryBush, xsRandInt(6, 9), cBerryClusterRadius);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidImpassableLand);
   addObjectLocsPerPlayer(startingBerriesID, false, 1, cStartingBerriesMinDist, cStartingBerriesMaxDist, avoidStartingFoodMeters);

   // Chicken.
   int startingChickenID = rmObjectDefCreate("starting chicken");
   rmObjectDefAddItem(startingChickenID, cUnitTypeChicken, xsRandInt(5, 7));
   rmObjectDefAddConstraint(startingChickenID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidImpassableLand);
   addObjectLocsPerPlayer(startingChickenID, false, 1, cStartingChickenMinDist, cStartingChickenMaxDist, avoidStartingFoodMeters);

   // Herdables.
   int startingHerdID = rmObjectDefCreate("starting herd");
   rmObjectDefAddItem(startingHerdID, cUnitTypeGoat, xsRandInt(2, 4));
   rmObjectDefAddConstraint(startingHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidImpassableLand);
   addObjectLocsPerPlayer(startingHerdID, true, 1, cStartingHerdMinDist, cStartingHerdMaxDist);

   generateLocs("starting food locs");

   rmSetProgress(0.5);

   // Gold.
   int numCenterGoldPerPlayer = 3 * getMapAreaSizeFactor();
   if(cNumberPlayers > 4)
   {
      numCenterGoldPerPlayer = 2 * getMapAreaSizeFactor();
   }

   float avoidGoldMeters = 30.0;

   // Bonus gold.
   int bonusGoldID = rmObjectDefCreate("bonus gold");
   rmObjectDefAddItem(bonusGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusGoldID, defaultAvoidWater);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(bonusGoldID, createSymmetricBoxConstraint(0.25, 0.0));
   addObjectDefPlayerLocConstraint(bonusGoldID, 70.0);

   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusGoldID, false, numCenterGoldPerPlayer, 70.0, -1.0, avoidGoldMeters);
   }
   else if(gameIsFair() == true)
   {
      addObjectLocsPerPlayer(bonusGoldID, false, numCenterGoldPerPlayer, 70.0, -1.0, avoidGoldMeters, cBiasForward);
   }
   else
   {
      // Just place some gold.
      int numCenterGold = numCenterGoldPerPlayer * cNumberPlayers;
      
      addObjectLocsAtOrigin(bonusGoldID, numCenterGold, cCenterLoc, 0.0, -1.0, avoidGoldMeters);
   }

   generateLocs("gold locs");

   // Hunt.
   float avoidHuntMeters = 40.0;

   // Close hunt.
   int closeHuntID = rmObjectDefCreate("close hunt");
   rmObjectDefAddItem(closeHuntID, cUnitTypeDeer, xsRandInt(8, 10));
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHuntID, defaultAvoidWater);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeHuntID, 60.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeHuntID, false, 1, 60.0, 100.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(closeHuntID, false, 1, 60.0, 100.0, avoidHuntMeters);
   }

   // Bonus hunt.
   if(xsRandBool(0.75) == true)
   {
      int bonusHuntID = rmObjectDefCreate("bonus hunt");
      rmObjectDefAddItem(bonusHuntID, cUnitTypeBoar, xsRandInt(3, 5));
      rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidImpassableLand);
      rmObjectDefAddConstraint(bonusHuntID, defaultAvoidWater);
      rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidSettlementRange);
      if(gameIsFair() == true)
      {
         rmObjectDefAddConstraint(bonusHuntID, createSymmetricBoxConstraint(0.25, 0.0));
      }
      
      if(gameIs1v1() == true)
      {
         addObjectDefPlayerLocConstraint(bonusHuntID, 60.0);
         addSimObjectLocsPerPlayerPair(bonusHuntID, false, 1, 60.0, -1.0, avoidHuntMeters);
      }
      else
      {
         addObjectDefPlayerLocConstraint(bonusHuntID, 80.0);
         addObjectLocsPerPlayer(bonusHuntID, false, 1, 80.0, -1.0, avoidHuntMeters, cBiasNone, (gameIsFair() == true) ? cInAreaTeam : cInAreaNone);
      }
   }

   // Other map sizes hunt.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int largeMapHuntID = rmObjectDefCreate("large map hunt");
      if(xsRandBool(0.5) == true)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeBoar, xsRandInt(2, 5));
      }
      else
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeDeer, xsRandInt(8, 12));
      }

      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidImpassableLand);
      rmObjectDefAddConstraint(largeMapHuntID, defaultAvoidWater);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidSettlementRange);
      addObjectDefPlayerLocConstraint(largeMapHuntID, 100.0);
      addObjectLocsPerPlayer(largeMapHuntID, false, 1 * getMapSizeBonusFactor(), 100.0, -1.0, avoidHuntMeters);
   }

   generateLocs("hunt locs");

   rmSetProgress(0.6);

   // Berries.
   float avoidBerriesMeters = 50.0;

   int berriesID = rmObjectDefCreate("berries");
   rmObjectDefAddItem(berriesID, cUnitTypeBerryBush, xsRandInt(8, 10), cBerryClusterRadius);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(berriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(berriesID, vDefaultBerriesAvoidImpassableLand);
   rmObjectDefAddConstraint(berriesID, defaultAvoidWater);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(berriesID, 65.0);
   addObjectLocsPerPlayer(berriesID, false, 1 * getMapSizeBonusFactor(), 65.0, -1.0, avoidBerriesMeters);

   generateLocs("berries locs");

   // Herdables.
   float avoidHerdMeters = 50.0;

   int closeHerdID = rmObjectDefCreate("close herd");
   rmObjectDefAddItem(closeHerdID, cUnitTypeGoat, 2, 4.0);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHerdID, defaultAvoidWater);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidTowerLOS);
   addObjectLocsPerPlayer(closeHerdID, false, xsRandInt(1, 2), 50.0, 70.0, avoidHerdMeters);

   int bonusHerdID = rmObjectDefCreate("bonus herd");
   rmObjectDefAddItem(bonusHerdID, cUnitTypeGoat, 2, 4.0);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusHerdID, defaultAvoidWater);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidTowerLOS);
   addObjectLocsPerPlayer(bonusHerdID, false, xsRandInt(1, 2) * getMapSizeBonusFactor(), 70.0, -1.0, avoidHerdMeters);

   generateLocs("herd locs");

   // Predators.
   float avoidPredatorMeters = 50.0;

   int predatorID = rmObjectDefCreate("predator");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(predatorID, cUnitTypeWolf, xsRandInt(2, 3), 4.0);
   }
   else
   {
      rmObjectDefAddItem(predatorID, cUnitTypeBear, xsRandInt(1, 2), 4.0);
   }
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(predatorID, defaultAvoidWater);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(predatorID, 70.0);
   addObjectLocsPerPlayer(predatorID, false, xsRandInt(1, 2) * getMapAreaSizeFactor(), 70.0, -1.0, avoidPredatorMeters);

   generateLocs("predator locs");

   // Relics.
   float avoidRelicMeters = 80.0;

   int relicID = rmObjectDefCreate("relic");
   rmObjectDefAddItem(relicID, cUnitTypeRelic, 1);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidAll);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidImpassableLand);
   rmObjectDefAddConstraint(relicID, defaultAvoidWater);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(relicID, 80.0);
   addObjectLocsPerPlayer(relicID, false, 2 * getMapAreaSizeFactor(), 80.0, -1.0, avoidRelicMeters);

   generateLocs("relic locs");

   rmSetProgress(0.7);

   // Forests.
   float avoidForestMeters = 25.0;

   int forestDefID = rmAreaDefCreate("forest");
   rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(70), rmTilesToAreaFraction(90));
   rmAreaDefSetForestType(forestDefID, cForestGreekPineSnowMix);
   rmAreaDefSetAvoidSelfDistance(forestDefID, avoidForestMeters);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidImpassableLand10);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidWater12);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddConstraint(forestDefID, rmCreateClassDistanceConstraint(cliffClassID, 1.0)); // Cliff top.

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
   buildAreaDefInTeamAreas(forestDefID, 5 * getMapAreaSizeFactor());

   // Stragglers.
   placeStartingStragglers(cUnitTypeTreePineSnow);

   rmSetProgress(0.8);

   // Fish.
   if(gameIs1v1() == true)
   {
      // 1v1: 3x3 per river.
      int fishID = rmObjectDefCreate("fish");
      rmObjectDefAddItem(fishID, cUnitTypeHerring, 3, 5.0);
      placeObjectDefInLine(fishID, 0, 6 * getMapAreaSizeFactor(), vectorXZ(0.1, 0.05), vectorXZ(0.9, 0.05), 0.0, 5.0); // Lower river.
      placeObjectDefInLine(fishID, 0, 6 * getMapAreaSizeFactor(), vectorXZ(0.1, 0.95), vectorXZ(0.9, 0.95), 0.0, 5.0); // Upper river.
   }
   else
   {
      // TODO Be smarter here - could consider to mirror this because it really isn't all too interesting.

      // Everything else: Just put 1.5 * cNumberPlayers fish into each half-river (without verifying for now).
      int fishAvoidEdge = createSymmetricBoxConstraint(rmXMetersToFraction(4.0), rmZMetersToFraction(4.0));
      int fishAvoidLand = rmCreatePassabilityDistanceConstraint(cPassabilityLand, true, 6.0);
      int fishAvoidFish = rmCreateTypeDistanceConstraint(cUnitTypeFishResource, 20.0);
      int numFishPerHalfRiver = 1.5 * cNumberPlayers * getMapAreaSizeFactor();

      for(int i = 0; i < 4; i++)
      {
         int fishID = rmObjectDefCreate("fish " + i);
         rmObjectDefAddItem(fishID, cUnitTypeHerring, 3, 5.0);

         rmObjectDefAddConstraint(fishID, fishAvoidEdge);
         rmObjectDefAddConstraint(fishID, fishAvoidLand);
         rmObjectDefAddConstraint(fishID, fishAvoidFish);

         if(i == 0)
         {
            rmObjectDefAddConstraint(fishID, rmCreateBoxConstraint(vectorXZ(0.01, 0.9), vectorXZ(0.5, 1.0)));
            rmObjectDefPlaceInArea(fishID, 0, rmAreaGetID("river 1"), numFishPerHalfRiver);
         }
         else if(i == 1)
         {
            rmObjectDefAddConstraint(fishID, rmCreateBoxConstraint(vectorXZ(0.5, 0.9), vectorXZ(0.99, 1.0)));
            rmObjectDefPlaceInArea(fishID, 0, rmAreaGetID("river 1"), numFishPerHalfRiver);
         }
         else if(i == 2)
         {
            rmObjectDefAddConstraint(fishID, rmCreateBoxConstraint(vectorXZ(0.01, 0.0), vectorXZ(0.5, 0.1)));
            rmObjectDefPlaceInArea(fishID, 0, rmAreaGetID("river 0"), numFishPerHalfRiver);
         }
         else if(i == 3)
         {
            rmObjectDefAddConstraint(fishID, rmCreateBoxConstraint(vectorXZ(0.5, 0.0), vectorXZ(0.99, 0.1)));
            rmObjectDefPlaceInArea(fishID, 0, rmAreaGetID("river 0"), numFishPerHalfRiver);
         }
      }
   }

   rmSetProgress(0.9);

   // Embellishment.
   // Gold areas.
   buildAreaUnderObjectDef(startingGoldID, cTerrainGreekSnowGrassRocks2, cTerrainGreekSnowGrassRocks2, 8.0);
   buildAreaUnderObjectDef(bonusGoldID, cTerrainGreekSnowGrassRocks2, cTerrainGreekSnowGrassRocks2, 8.0);

   // Berries areas.
   buildAreaUnderObjectDef(startingBerriesID, cTerrainGreekSnowGrass3, cTerrainGreekSnowGrass3, 10.0);
   buildAreaUnderObjectDef(berriesID, cTerrainGreekSnowGrass3, cTerrainGreekSnowGrass3, 10.0);

   // Random trees.
   int randomTreeID = rmObjectDefCreate("random tree");
   rmObjectDefAddItem(randomTreeID, cUnitTypeTreePine, 1);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidImpassableLand8);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidWater12);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidTree);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefPlaceAnywhere(randomTreeID, 0, 5 * cNumberPlayers * getMapAreaSizeFactor());

   // Rocks.
   int rockTinyID = rmObjectDefCreate("rock tiny");
   rmObjectDefAddItem(rockTinyID, cUnitTypeRockGreekTiny, 1);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefPlaceAnywhere(rockTinyID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());

   int rockSmallID = rmObjectDefCreate("rock small");
   rmObjectDefAddItem(rockSmallID, cUnitTypeRockGreekSmall, 1);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefPlaceAnywhere(rockSmallID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());

   int avoidGreekSnow1 = rmCreateTerrainTypeDistanceConstraint(cTerrainGreekSnow1, 1.0);
   int avoidGreekSnow2 = rmCreateTerrainTypeDistanceConstraint(cTerrainGreekSnow2, 1.0);
   int avoidGreekSnowRocks1 = rmCreateTerrainTypeDistanceConstraint(cTerrainGreekSnowRocks1, 1.0);
   int avoidGreekSnowRocks2 = rmCreateTerrainTypeDistanceConstraint(cTerrainGreekSnowRocks2, 1.0);
   int avoidGreekSnowGrassRocks1 = rmCreateTerrainTypeDistanceConstraint(cTerrainGreekSnowGrassRocks1, 1.0);
   int avoidGreekSnowGrassRocks2 = rmCreateTerrainTypeDistanceConstraint(cTerrainGreekSnowGrassRocks2, 1.0);
   int avoidGreekSnowGrass1 = rmCreateTerrainTypeDistanceConstraint(cTerrainGreekSnowGrass1, 1.0);
   int avoidGreekSnowGrass2 = rmCreateTerrainTypeDistanceConstraint(cTerrainGreekSnowGrass2, 1.0);

   // Plants.
   // TODO Multi-terrain constraint, any terrain constraint.
   int plantBushID = rmObjectDefCreate("plant bush");
   rmObjectDefAddItem(plantBushID, cUnitTypePlantGreekBush, 1);
   rmObjectDefAddConstraint(plantBushID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantBushID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(plantBushID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefAddConstraint(plantBushID, avoidGreekSnow1);
   rmObjectDefAddConstraint(plantBushID, avoidGreekSnow2);
   rmObjectDefAddConstraint(plantBushID, avoidGreekSnowRocks1);
   rmObjectDefAddConstraint(plantBushID, avoidGreekSnowRocks2);
   rmObjectDefAddConstraint(plantBushID, avoidGreekSnowGrassRocks1);
   rmObjectDefAddConstraint(plantBushID, avoidGreekSnowGrassRocks2);
   rmObjectDefAddConstraint(plantBushID, avoidGreekSnowGrass1);
   rmObjectDefAddConstraint(plantBushID, avoidGreekSnowGrass2);
   rmObjectDefPlaceAnywhere(plantBushID, 0, 30 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantShrubID = rmObjectDefCreate("plant shrub");
   rmObjectDefAddItem(plantShrubID, cUnitTypePlantGreekShrub, 1);
   rmObjectDefAddConstraint(plantShrubID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantShrubID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(plantShrubID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefAddConstraint(plantShrubID, avoidGreekSnow1);
   rmObjectDefAddConstraint(plantShrubID, avoidGreekSnow2);
   rmObjectDefAddConstraint(plantShrubID, avoidGreekSnowRocks1);
   rmObjectDefAddConstraint(plantShrubID, avoidGreekSnowRocks2);
   rmObjectDefAddConstraint(plantShrubID, avoidGreekSnowGrassRocks1);
   rmObjectDefAddConstraint(plantShrubID, avoidGreekSnowGrassRocks2);
   rmObjectDefAddConstraint(plantShrubID, avoidGreekSnowGrass1);
   rmObjectDefAddConstraint(plantShrubID, avoidGreekSnowGrass2);
   rmObjectDefPlaceAnywhere(plantShrubID, 0, 30 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantGrassID = rmObjectDefCreate("plant grass");
   rmObjectDefAddItem(plantGrassID, cUnitTypePlantGreekGrass, 1);
   rmObjectDefAddConstraint(plantGrassID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantGrassID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(plantGrassID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefAddConstraint(plantGrassID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(plantGrassID, avoidGreekSnow1);
   rmObjectDefAddConstraint(plantGrassID, avoidGreekSnow2);
   rmObjectDefAddConstraint(plantGrassID, avoidGreekSnowRocks1);
   rmObjectDefAddConstraint(plantGrassID, avoidGreekSnowRocks2);
   rmObjectDefAddConstraint(plantGrassID, avoidGreekSnowGrassRocks1);
   rmObjectDefAddConstraint(plantGrassID, avoidGreekSnowGrassRocks2);
   rmObjectDefAddConstraint(plantGrassID, avoidGreekSnowGrass1);
   rmObjectDefAddConstraint(plantGrassID, avoidGreekSnowGrass2);
   rmObjectDefPlaceAnywhere(plantGrassID, 0, 20 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantFernID = rmObjectDefCreate("plant fern");
   rmObjectDefAddItem(plantFernID, cUnitTypePlantGreekFern, 1);
   rmObjectDefAddConstraint(plantFernID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantFernID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(plantFernID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefAddConstraint(plantFernID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(plantFernID, avoidGreekSnow1);
   rmObjectDefAddConstraint(plantFernID, avoidGreekSnow2);
   rmObjectDefAddConstraint(plantFernID, avoidGreekSnowRocks1);
   rmObjectDefAddConstraint(plantFernID, avoidGreekSnowRocks2);
   rmObjectDefAddConstraint(plantFernID, avoidGreekSnowGrassRocks1);
   rmObjectDefAddConstraint(plantFernID, avoidGreekSnowGrassRocks2);
   rmObjectDefAddConstraint(plantFernID, avoidGreekSnowGrass1);
   rmObjectDefAddConstraint(plantFernID, avoidGreekSnowGrass2);
   rmObjectDefPlaceAnywhere(plantFernID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantWeedsID = rmObjectDefCreate("plant weeds");
   rmObjectDefAddItem(plantWeedsID, cUnitTypePlantGreekWeeds, 1);
   rmObjectDefAddConstraint(plantWeedsID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantWeedsID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(plantWeedsID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefAddConstraint(plantWeedsID, avoidGreekSnow1);
   rmObjectDefAddConstraint(plantWeedsID, avoidGreekSnow2);
   rmObjectDefAddConstraint(plantWeedsID, avoidGreekSnowRocks1);
   rmObjectDefAddConstraint(plantWeedsID, avoidGreekSnowRocks2);
   rmObjectDefAddConstraint(plantWeedsID, avoidGreekSnowGrassRocks1);
   rmObjectDefAddConstraint(plantWeedsID, avoidGreekSnowGrassRocks2);
   rmObjectDefAddConstraint(plantWeedsID, avoidGreekSnowGrass1);
   rmObjectDefAddConstraint(plantWeedsID, avoidGreekSnowGrass2);
   rmObjectDefPlaceAnywhere(plantWeedsID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());

   int avoidGreekGrass1 = rmCreateTerrainTypeDistanceConstraint(cTerrainGreekGrass1, 1.0);
   int avoidGreekGrass2 = rmCreateTerrainTypeDistanceConstraint(cTerrainGreekGrass2, 1.0);
   int avoidGreekSnowGrass3 = rmCreateTerrainTypeDistanceConstraint(cTerrainGreekSnowGrass3, 1.0);
   
   int plantSnowWeedsID = rmObjectDefCreate("plant snow weeds");
   rmObjectDefAddItem(plantSnowWeedsID, cUnitTypePlantSnowWeeds, 1);
   rmObjectDefAddConstraint(plantSnowWeedsID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantSnowWeedsID, vDefaultAvoidWater8);
   rmObjectDefAddConstraint(plantSnowWeedsID, avoidGreekGrass1);
   rmObjectDefAddConstraint(plantSnowWeedsID, avoidGreekGrass2);
   rmObjectDefAddConstraint(plantSnowWeedsID, avoidGreekSnowGrass3);
   rmObjectDefPlaceAnywhere(plantSnowWeedsID, 0, 20 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantSnowFernID = rmObjectDefCreate("plant snow fern");
   rmObjectDefAddItem(plantSnowFernID, cUnitTypePlantSnowFern, 1);
   rmObjectDefAddConstraint(plantSnowFernID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantSnowFernID, vDefaultAvoidWater8);
   rmObjectDefAddConstraint(plantSnowFernID, avoidGreekGrass1);
   rmObjectDefAddConstraint(plantSnowFernID, avoidGreekGrass2);
   rmObjectDefAddConstraint(plantSnowFernID, avoidGreekSnowGrass3);
   rmObjectDefPlaceAnywhere(plantSnowFernID, 0, 20 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantSnowGrassID = rmObjectDefCreate("plant snow grass");
   rmObjectDefAddItem(plantSnowGrassID, cUnitTypePlantSnowGrass, 1);
   rmObjectDefAddConstraint(plantSnowGrassID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantSnowGrassID, vDefaultAvoidWater8);
   rmObjectDefAddConstraint(plantSnowGrassID, avoidGreekGrass1);
   rmObjectDefAddConstraint(plantSnowGrassID, avoidGreekGrass2);
   rmObjectDefAddConstraint(plantSnowGrassID, avoidGreekSnowGrass3);
   rmObjectDefPlaceAnywhere(plantSnowGrassID, 0, 20 * cNumberPlayers * getMapAreaSizeFactor());

   // Logs.
   int logID = rmObjectDefCreate("log");
   rmObjectDefAddItem(logID, cUnitTypeRottingLog, 1);
   rmObjectDefAddConstraint(logID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(logID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(logID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefAddConstraint(logID, vDefaultAvoidSettlementRange);
   rmObjectDefPlaceAnywhere(logID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeHawk, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   rmSetProgress(1.0);
}
