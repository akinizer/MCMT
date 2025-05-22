include "lib2/rm_core.xs";

void generate()
{
   rmSetProgress(0.0);

   // Define mixes.
   int baseMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.15, 3, 0.5);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseSnowGrass1, 2.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseSnow2, 1.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseSnow1, 3.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseSnowDirt1, 1.0);

   int iceMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(iceMixID, cNoiseRandom);
   rmCustomMixAddPaintEntry(iceMixID, cTerrainDefaultIce1, 1.0);
   rmCustomMixAddPaintEntry(iceMixID, cTerrainDefaultIce2, 2.0);
   rmCustomMixAddPaintEntry(iceMixID, cTerrainDefaultIce3, 2.0);

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

   rmSetProgress(0.1);

   // Player placement.
   rmSetTeamSpacingModifier(xsRandFloat(0.7, 0.8));
   rmPlacePlayersOnCircle(xsRandFloat(0.35, 0.375));

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCivFromCulture(cCultureNorse);

   // KotH.
   placeKotHObjects();

   // Lighting.
   rmSetLighting(cLightingSetRmGhostLake01);

   // Global elevation.
   rmAddGlobalHeightNoise(cNoiseFractalSum, 4.0, 0.1, 5, 0.3);

   rmSetProgress(0.2);

   // Ghost lake.
   int lakeAreaID = rmAreaCreate("lake");
   rmAreaAddTerrainLayer(lakeAreaID, cTerrainNorseSnowRocks1, 0, 1);
   rmAreaAddTerrainLayer(lakeAreaID, cTerrainNorseShore1, 1, 2);
   rmAreaAddTerrainLayer(lakeAreaID, cTerrainDefaultIce1, 3, 4);
   rmAreaSetMix(lakeAreaID, iceMixID);
   rmAreaSetLoc(lakeAreaID, cCenterLoc);
   rmAreaSetSize(lakeAreaID, 0.175);

   rmAreaSetHeight(lakeAreaID, 0.0);
   // Incremental smoothing so we get a nice transition.
   rmAreaAddHeightBlend(lakeAreaID, cBlendEdge, cFilter5x5Gaussian, 10, 10, true, true);
   rmAreaSetBlobs(lakeAreaID, 8, 10);
   rmAreaSetBlobDistance(lakeAreaID, rmGetMapXTiles() / 12.0, rmGetMapZTiles() / 6.0);
   rmAreaSetEdgeSmoothDistance(lakeAreaID, 5);

   rmAreaAddConstraint(lakeAreaID, createPlayerLocDistanceConstraint(40.0));
   rmAreaAddConstraint(lakeAreaID, createSymmetricBoxConstraint(rmXMetersToFraction(50.0)));

   rmAreaBuild(lakeAreaID);

   // Set up constraints.
   int avoidCenter4 = rmCreateAreaDistanceConstraint(lakeAreaID, 4.0);
   int avoidCenter8 = rmCreateAreaDistanceConstraint(lakeAreaID, 8.0);
   int avoidCenter12 = rmCreateAreaDistanceConstraint(lakeAreaID, 12.0);
   int avoidCenter16 = rmCreateAreaDistanceConstraint(lakeAreaID, 16.0);

   rmSetProgress(0.3);

   // Settlements and towers.
   placeStartingTownCenters();

   // Starting towers.
   // The center avoids player cores sufficiently to not make towers avoid the center.
   int startingTowerID = rmObjectDefCreate("starting tower");
   rmObjectDefAddItem(startingTowerID, cUnitTypeSentryTower, 1);
   addObjectLocsPerPlayer(startingTowerID, true, 4, cStartingTowerMinDist, cStartingTowerMaxDist, cStartingTowerAvoidanceMeters);
   generateLocs("starting tower locs");

   // Settlements.
   int firstSettlementID = rmObjectDefCreate("first settlement");
   rmObjectDefAddItem(firstSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(firstSettlementID, avoidCenter16);

   int secondSettlementID = rmObjectDefCreate("second settlement");
   rmObjectDefAddItem(secondSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidKotH);
   rmObjectDefAddConstraint(secondSettlementID, avoidCenter16);

   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(firstSettlementID, false, 1, 60.0, 80.0, cSettlementDist1v1, cBiasBackward,
                          cInAreaDefault, cLocSideOpposite);
      addSimObjectLocsPerPlayerPair(secondSettlementID, false, 1, 80.0, 120.0, cSettlementDist1v1, cBiasAggressive);
   }
   else
   {
      addObjectLocsPerPlayer(firstSettlementID, false, 1, 60.0, 80.0, cCloseSettlementDist, cBiasBackward | cBiasAllyInside);
      addObjectLocsPerPlayer(secondSettlementID, false, 1, 70.0, 90.0, cFarSettlementDist, cBiasAggressive | cBiasAllyOutside);
   }
   
   // Other map sizes settlements.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int bonusSettlementID = rmObjectDefCreate("bonus settlement");
      rmObjectDefAddItem(bonusSettlementID, cUnitTypeSettlement, 1);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidEdge);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidCorner40);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidKotH);
      rmObjectDefAddConstraint(bonusSettlementID, avoidCenter16);
      addObjectLocsPerPlayer(bonusSettlementID, false, 1 * getMapAreaSizeFactor(), 90.0, -1.0, 100.0);
   }

   generateLocs("settlement locs");

   rmSetProgress(0.4);

   // Cliffs.
   int cliffClassID = rmClassCreate();
   int numCliffsPerPlayer = xsRandInt(1 * getMapAreaSizeFactor(), 2 * getMapAreaSizeFactor());

   // Scale with map size.
   float cliffMinSize = rmTilesToAreaFraction(350 * getMapAreaSizeFactor());
   float cliffMaxSize = rmTilesToAreaFraction(400 * getMapAreaSizeFactor());

   int cliffAvoidCliff = rmCreateClassDistanceConstraint(cliffClassID, 40.0);
   int cliffAvoidBuildings = rmCreateTypeDistanceConstraint(cUnitTypeBuilding, 20.0);

   for(int i = 1; i <= cNumberPlayers; i++)
   {
      int p = vDefaultTeamPlayerOrder[i];
      int teamArea = vTeamAreaIDs[rmGetPlayerTeam(p)];

      for(int j = 0; j < numCliffsPerPlayer; j++)
      {
         int cliffID = rmAreaCreate("cliff " + p + " " + j);
         rmAreaSetParent(cliffID, teamArea);

         rmAreaSetSize(cliffID, xsRandFloat(cliffMinSize, cliffMaxSize));
         rmAreaSetTerrainType(cliffID, cTerrainNorseSnow1);
         rmAreaSetCliffType(cliffID, cCliffNorseSnow);
         rmAreaSetCliffRamps(cliffID, 2, 0.25, 0.0, 1.0);
         rmAreaSetCliffRampSteepness(cliffID, 2.0);
         rmAreaSetCliffEmbellishmentDensity(cliffID, 0.25);
         
         rmAreaSetHeightRelative(cliffID, 7.0);
         rmAreaAddHeightBlend(cliffID, cBlendAll, cFilter5x5Gaussian);
         rmAreaSetEdgeSmoothDistance(cliffID, 10);
         rmAreaSetCoherence(cliffID, 0.25);

         rmAreaAddConstraint(cliffID, cliffAvoidCliff);
         rmAreaAddConstraint(cliffID, cliffAvoidBuildings);
         rmAreaAddConstraint(cliffID, avoidCenter12);
         rmAreaAddConstraint(cliffID, vDefaultAvoidTowerLOS);
         rmAreaAddToClass(cliffID, cliffClassID);

         rmAreaBuild(cliffID);
      }
   }

   rmSetProgress(0.5);

   // Starting objects.
   // Starting gold.
   int startingGoldID = rmObjectDefCreate("starting gold");
   rmObjectDefAddItem(startingGoldID, cUnitTypeMineGoldMedium, 1);
   rmObjectDefAddConstraint(startingGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(startingGoldID, vDefaultStartingGoldAvoidTower);
   rmObjectDefAddConstraint(startingGoldID, vDefaultForceStartingGoldNearTower);
   rmObjectDefAddConstraint(startingGoldID, avoidCenter8);
   addObjectLocsPerPlayer(startingGoldID, false, xsRandInt(1, 2), cStartingGoldMinDist, cStartingGoldMaxDist, cStartingGoldAvoidanceMeters);

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
   rmObjectDefAddConstraint(startingHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(startingHuntID, vDefaultForceInTowerLOS);
   rmObjectDefAddConstraint(startingHuntID, avoidCenter8);
   addObjectLocsPerPlayer(startingHuntID, false, 1, cStartingHuntMinDist, cStartingHuntMaxDist, cStartingObjectAvoidanceMeters);

   // Berries.
   int startingBerriesID = rmObjectDefCreate("starting berries");
   rmObjectDefAddItem(startingBerriesID, cUnitTypeBerryBush, xsRandInt(6, 9), cBerryClusterRadius);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidImpassableLand);
   rmObjectDefAddConstraint(startingBerriesID, avoidCenter8);
   addObjectLocsPerPlayer(startingBerriesID, false, 1, cStartingBerriesMinDist, cStartingBerriesMaxDist, cStartingObjectAvoidanceMeters);

   // Chicken.
   int startingChickenID = rmObjectDefCreate("starting chicken");
   int numChicken = xsRandInt(5, 7);
   // Set chicken variation, excluding whites, as they are hard to see on snow maps.
   for (int i = 0; i < numChicken; i++)
   {
      rmObjectDefAddItem(startingChickenID, cUnitTypeChicken, 1);
      rmObjectDefSetItemVariation(startingChickenID, i, xsRandInt(cChickenVariationBrown, cChickenVariationBlack));
   }
   rmObjectDefAddConstraint(startingChickenID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(startingChickenID, avoidCenter8);
   addObjectLocsPerPlayer(startingChickenID, false, 1, cStartingChickenMinDist, cStartingChickenMaxDist, cStartingObjectAvoidanceMeters);


   // Herdables.
   int startingHerdID = rmObjectDefCreate("starting herd");
   rmObjectDefAddItem(startingHerdID, cUnitTypeGoat, xsRandInt(2, 5));
   rmObjectDefAddConstraint(startingHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidImpassableLand);
   addObjectLocsPerPlayer(startingHerdID, true, 1, cStartingHerdMinDist, cStartingHerdMaxDist);

   generateLocs("starting food locs");
   
   rmSetProgress(0.6);

   // Gold.
   float avoidGoldMeters = 50.0;

   // Bonus gold.
   int bonusGoldID = rmObjectDefCreate("bonus gold");
   rmObjectDefAddItem(bonusGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(bonusGoldID, avoidCenter8);
   addObjectDefPlayerLocConstraint(bonusGoldID, 70.0);
   if(gameIs1v1()== true)
   {
      addSimObjectLocsPerPlayerPair(bonusGoldID, false, xsRandInt(2, 4) * getMapAreaSizeFactor(), 70.0, -1.0, avoidGoldMeters);
   }
   else
   {
      addObjectLocsPerPlayer(bonusGoldID, false, xsRandInt(2, 4) * getMapAreaSizeFactor(), 70.0, -1.0, avoidGoldMeters);
   }

   generateLocs("gold locs");

   // Hunt.
   float avoidHuntMeters = 50.0;

   // Close hunt.
   float closeHuntFloat = xsRandFloat(0.0, 1.0);
   int closeHuntID = rmObjectDefCreate("close hunt");
   if(closeHuntFloat < 2.0 / 3.0)
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeBoar, 1);
   }
   else
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeDeer, xsRandInt(2, 3));
   }
   rmObjectDefAddItem(closeHuntID, cUnitTypeAurochs, xsRandInt(1, 2));
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(closeHuntID, avoidCenter8);
   addObjectDefPlayerLocConstraint(closeHuntID, 55.0);
   rmObjectDefAddConstraint(closeHuntID, createPlayerLocDistanceConstraint(55.0));
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeHuntID, false, 1, 60.0, 80.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(closeHuntID, false, 1, 55.0, 85.0, avoidHuntMeters);
   }

   // Far hunt.
   int farHuntID = rmObjectDefCreate("far hunt");
   int numFarHuntSpawns = 0;
   if (xsRandBool(0.6) == true)
   {
      rmObjectDefAddItem(farHuntID, cUnitTypeCaribou, xsRandInt(7, 11));
      numFarHuntSpawns = 1;
   }
   else
   {
      rmObjectDefAddItem(farHuntID, cUnitTypeCaribou, xsRandInt(5, 6));
      numFarHuntSpawns = 2;
   }
   rmObjectDefAddConstraint(farHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(farHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(farHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(farHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(farHuntID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(farHuntID, avoidCenter8);
   addObjectDefPlayerLocConstraint(farHuntID, 60.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(farHuntID, false, numFarHuntSpawns, 70.0, 100.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(farHuntID, false, numFarHuntSpawns, 60.0, 100.0, avoidHuntMeters);
   }

   // Other map sizes hunt.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      float largeMapHuntFloat = xsRandFloat(0.0, 1.0);
      int largeMapHuntID = rmObjectDefCreate("large map hunt");
      if(largeMapHuntFloat < 1.0 / 3.0)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeCaribou, xsRandInt(6, 12));
      }
      else if(largeMapHuntFloat < 2.0 / 3.0)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeAurochs, xsRandInt(2, 4));
      }
      else
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeBoar, xsRandInt(2, 4));
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeCaribou, xsRandInt(3, 6));
      }
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidImpassableLand);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidSettlementRange);
      rmObjectDefAddConstraint(largeMapHuntID, avoidCenter8);
      addObjectDefPlayerLocConstraint(largeMapHuntID, 70.0);
      addObjectLocsPerPlayer(largeMapHuntID, false, 2 * getMapAreaSizeFactor(), 100.0, -1.0, avoidHuntMeters);
   }

   generateLocs("hunt locs");

   rmSetProgress(0.7);

   // Berries.
   float avoidBerriesMeters = 50.0;

   int berriesID = rmObjectDefCreate("berries");
   rmObjectDefAddItem(berriesID, cUnitTypeBerryBush, xsRandInt(5, 9), cBerryClusterRadius);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(berriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(berriesID, vDefaultBerriesAvoidImpassableLand);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(berriesID, avoidCenter12);
   addObjectDefPlayerLocConstraint(berriesID, 60.0);
   addObjectLocsPerPlayer(berriesID, false, 1 * getMapAreaSizeFactor(), 60.0, -1.0, avoidBerriesMeters);

   generateLocs("berries locs");

   // Herdables.
   float avoidHerdMeters = 50.0;

   int closeHerdID = rmObjectDefCreate("close herd");
   rmObjectDefAddItem(closeHerdID, cUnitTypeGoat, 2);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidTowerLOS);
   addObjectLocsPerPlayer(closeHerdID, false, 2, 50.0, 70.0, avoidHerdMeters);

   int bonusHerdID = rmObjectDefCreate("bonus herd");
   rmObjectDefAddItem(bonusHerdID, cUnitTypeGoat, xsRandInt(2, 3));
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidTowerLOS);
   addObjectLocsPerPlayer(bonusHerdID, false, xsRandInt(1, 2) * getMapSizeBonusFactor(), 70.0, -1.0, avoidHerdMeters);

   int centerHerdID = rmObjectDefCreate("center herd");
   rmObjectDefAddItem(centerHerdID, cUnitTypeGoat, xsRandInt(2, 3));
   rmObjectDefAddConstraint(centerHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(centerHerdID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(centerHerdID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(centerHerdID, rmCreateAreaConstraint(lakeAreaID));
   rmObjectDefAddConstraint(centerHerdID, rmCreateAreaEdgeDistanceConstraint(lakeAreaID, 16.0));
   addObjectDefPlayerLocConstraint(centerHerdID, 60.0);
   addObjectLocsPerPlayer(bonusHerdID, false, 1 * getMapSizeBonusFactor(), 60.0, -1.0, avoidHerdMeters);

   generateLocs("herd locs");

   // Predators.
   float avoidPredatorMeters = 50.0;

   int predatorID = rmObjectDefCreate("predator");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(predatorID, cUnitTypePolarBear, xsRandInt(1, 3));
   }
   else
   {
      rmObjectDefAddItem(predatorID, cUnitTypeArcticWolf, xsRandInt(1, 3));
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
   float avoidRelicMeters = 80.0;

   int relicID = rmObjectDefCreate("relic");
   rmObjectDefAddItem(relicID, cUnitTypeRelic, 1);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidAll);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidImpassableLand);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(relicID, 80.0);
   addObjectLocsPerPlayer(relicID, false, 2 * getMapAreaSizeFactor(), 80.0, -1.0, avoidRelicMeters);

   generateLocs("relic locs");
   
   rmSetProgress(0.8);

   // Forests.
   float avoidForestMeters = 25.0;

   int forestDefID = rmAreaDefCreate("forest");
   rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(80), rmTilesToAreaFraction(100));
   rmAreaDefSetForestType(forestDefID, cForestNorsePineSnow);
   rmAreaDefSetAvoidSelfDistance(forestDefID, avoidForestMeters);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidImpassableLand10);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddConstraint(forestDefID, avoidCenter12);

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
   buildAreaDefInTeamAreas(forestDefID, 5 * getMapAreaSizeFactor());

   // Stragglers.
   placeStartingStragglers(cUnitTypeTreePineSnow);

   rmSetProgress(0.9);

   // Embellishment.
   // Gold areas.
   buildAreaUnderObjectDef(startingGoldID, cTerrainNorseSnowRocks2, cTerrainNorseSnowRocks1, 6.0);
   buildAreaUnderObjectDef(bonusGoldID, cTerrainNorseSnowRocks2, cTerrainNorseSnowRocks1, 6.0);

   // Berries areas.
   buildAreaUnderObjectDef(startingBerriesID, cTerrainNorseSnowGrass2, cTerrainNorseSnowGrass1, 8.0);
   buildAreaUnderObjectDef(berriesID, cTerrainNorseSnowGrass2, cTerrainNorseSnowGrass1, 8.0);

   // Random trees.
   int randomTreeID = rmObjectDefCreate("random tree");
   rmObjectDefAddItem(randomTreeID, cUnitTypeTreePineSnow, 1);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidImpassableLand);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidTree);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefAddConstraint(randomTreeID, avoidCenter12);
   rmObjectDefPlaceAnywhere(randomTreeID, 0, 5 * cNumberPlayers * getMapAreaSizeFactor());

   // Rocks.
   int rockTinyID = rmObjectDefCreate("rock tiny");
   rmObjectDefAddItem(rockTinyID, cUnitTypeRockNorseTiny, 1);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(rockTinyID, avoidCenter4);
   rmObjectDefPlaceAnywhere(rockTinyID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());

   int rockSmallID = rmObjectDefCreate("rock small");
   rmObjectDefAddItem(rockSmallID, cUnitTypeRockNorseSmall, 1);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(rockSmallID, avoidCenter4);
   rmObjectDefPlaceAnywhere(rockSmallID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());

   // Plants.
   int plantGrassID = rmObjectDefCreate("plant shrub");
   rmObjectDefAddItem(plantGrassID, cUnitTypePlantSnowGrass, 1);
   rmObjectDefAddConstraint(plantGrassID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantGrassID, avoidCenter4);
   rmObjectDefAddConstraint(plantGrassID, vDefaultAvoidEdge);
   rmObjectDefPlaceAnywhere(plantGrassID, 0, 40 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantFernID = rmObjectDefCreate("plant fern");
   rmObjectDefAddItemRange(plantFernID, cUnitTypePlantSnowFern, 1, 2, 0.0, 4.0);
   rmObjectDefAddConstraint(plantFernID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantFernID, avoidCenter4);
   rmObjectDefPlaceAnywhere(plantFernID, 0, 30 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantWeedsID = rmObjectDefCreate("plant weeds");
   rmObjectDefAddItemRange(plantWeedsID, cUnitTypePlantSnowWeeds, 1, 3, 0.0, 4.0);
   rmObjectDefAddConstraint(plantWeedsID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantWeedsID, avoidCenter4);
   rmObjectDefPlaceAnywhere(plantWeedsID, 0, 20 * cNumberPlayers * getMapAreaSizeFactor());
   
   // Snow VFX.
   int snowDriftPlainID = rmObjectDefCreate("snow drift plain");
   rmObjectDefAddItem(snowDriftPlainID, cUnitTypeVFXSnowDriftPlain, 1);
   rmObjectDefAddConstraint(snowDriftPlainID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(snowDriftPlainID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(snowDriftPlainID, vDefaultAvoidTowerLOS);
   rmObjectDefPlaceAnywhere(snowDriftPlainID, 0, 3 * cNumberPlayers * getMapAreaSizeFactor());

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeHawk, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   rmSetProgress(1.0);
}
