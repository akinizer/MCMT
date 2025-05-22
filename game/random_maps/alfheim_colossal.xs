include "lib2/rm_core.xs";
include "lib2/rm_connections.xs";

void generate()
{
   rmSetProgress(0.0);

   // Define mixes.
   int baseMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.15, 5, 0.5);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseGrass2, 4.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseGrass1, 4.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseGrassRocks1, 1.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseGrassDirt1, 5.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseGrassDirt2, 5.0);

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
   rmSetTeamSpacingModifier(0.8);
   rmPlacePlayersOnCircle(xsRandFloat(0.325, 0.35));

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCivFromCulture(cCultureNorse);

   // KotH.
   placeKotHObjects();

   // Lighting.
   rmSetLighting(cLightingSetRmAlfheim01);

   rmSetProgress(0.1);

   // Global elevation.
   rmAddGlobalHeightNoise(cNoiseFractalSum, 4.0, 0.1, 5, 0.3);

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
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidCorner40);

   int secondSettlementID = rmObjectDefCreate("second settlement");
   rmObjectDefAddItem(secondSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidKotH);

   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(firstSettlementID, false, 1, 60.0, 80.0, cSettlementDist1v1, cBiasBackward, cInAreaDefault, cLocSideOpposite);

      if(xsRandBool(0.5) == true)
      {
         setLocPairBindingDistance(120.0);
      }
      addSimObjectLocsPerPlayerPair(secondSettlementID, false, 1, 80.0, 120.0, cSettlementDist1v1, cBiasAggressive, cInAreaDefault, cLocSideOpposite);
   }
   else
   {
      setLocsPerPlayerType(cPerPlayerInner);
      addObjectLocsPerPlayer(firstSettlementID, false, 1, 60.0, 80.0, cCloseSettlementDist, cBiasVeryDefensive);
      setLocsPerPlayerType(cPerPlayerOuter);
      addObjectLocsPerPlayer(firstSettlementID, false, 1, 60.0, 80.0, cCloseSettlementDist, cBiasDefensive | cBiasAllyInside);
      
      setLocsPerPlayerType(cPerPlayerInner);
      addObjectLocsPerPlayer(secondSettlementID, false, 1, 70.0, 90.0, cFarSettlementDist, cBiasVeryAggressive);
      setLocsPerPlayerType(cPerPlayerOuter);
      addObjectLocsPerPlayer(secondSettlementID, false, 1, 70.0, 90.0, cFarSettlementDist, cBiasAggressive | cBiasAllyOutside);
   }

   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int bonusSettlementID = rmObjectDefCreate("bonus settlement");
      rmObjectDefAddItem(bonusSettlementID, cUnitTypeSettlement, 1);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidEdge);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidCorner40);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidKotH);
      addObjectLocsPerPlayer(bonusSettlementID, false, 1 * getMapAreaSizeFactor(), 90.0, -1.0, 100.0);
   }

   generateLocs("settlement locs");

   rmSetProgress(0.2);

   // Cliffs.
   int numCliffsPerPlayer = 4 * getMapAreaSizeFactor();

   float cliffMinSize = rmTilesToAreaFraction(200);
   float cliffMaxSize = rmTilesToAreaFraction(250);
   int cliffAvoidBuilding = rmCreateTypeDistanceConstraint(cUnitTypeBuilding, 20.0);
   int cliffAvoidTownCenter = rmCreateTypeDistanceConstraint(cUnitTypeTownCenter, 30.0);

   int cliffID = rmAreaDefCreate("cliff area");

   rmAreaDefSetSizeRange(cliffID, cliffMinSize, cliffMaxSize);

   rmAreaDefSetCliffType(cliffID, cCliffNorseGrass);
   rmAreaDefSetCliffSideRadius(cliffID, 0, 2);
   rmAreaDefSetCliffPaintInsideAsSide(cliffID, true);
   rmAreaDefSetCliffEmbellishmentDensity(cliffID, 0.25);

   rmAreaDefSetHeightRelative(cliffID, 5.0);
   rmAreaDefSetHeightNoise(cliffID, cNoiseFractalSum, 10.0, 0.2, 2, 0.5);
   rmAreaDefSetHeightNoiseBias(cliffID, 1.0); // Only grow on top of the cliff height.
   rmAreaDefAddHeightBlend(cliffID, cBlendEdge, cFilter5x5Gaussian, 2);

   rmAreaDefSetBlobs(cliffID, 2, 3);
   rmAreaDefSetBlobDistance(cliffID, 10.0, 20.0);

   rmAreaDefAddConstraint(cliffID, cliffAvoidBuilding, 0.0, 10.0);
   rmAreaDefAddConstraint(cliffID, cliffAvoidTownCenter, 0.0, 10.0);
   rmAreaDefSetAvoidSelfDistance(cliffID, 45.0, 10.0);

   if (gameIs1v1() == true)
   {
      addSimAreaLocsPerPlayerPair(cliffID, 2, 40.0, -1.0, 60.0, cBiasAggressive);
      addSimAreaLocsPerPlayerPair(cliffID, numCliffsPerPlayer - 2, 40.0, -1.0, 60.0, cBiasNone);
   }
   else
   {
      addAreaLocsPerPlayer(cliffID, numCliffsPerPlayer, 40.0, -1.0, 60.0);
   }

   generateLocs("cliff locs");

   rmSetProgress(0.3);

   // Starting objects.
   // Starting gold.
   int startingGoldID = rmObjectDefCreate("starting gold");
   rmObjectDefAddItem(startingGoldID, cUnitTypeMineGoldMedium, 1);
   rmObjectDefAddConstraint(startingGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(startingGoldID, vDefaultStartingGoldAvoidTower);
   rmObjectDefAddConstraint(startingGoldID, vDefaultForceStartingGoldNearTower);
   addObjectLocsPerPlayer(startingGoldID, false, 1, cStartingGoldMinDist, cStartingGoldMaxDist, cStartingGoldAvoidanceMeters);

   generateLocs("starting gold locs");

   // Berries.
   int startingBerriesID = rmObjectDefCreate("starting berries");
   rmObjectDefAddItem(startingBerriesID, cUnitTypeBerryBush, xsRandInt(6, 9), cBerryClusterRadius);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidImpassableLand);
   addObjectLocsPerPlayer(startingBerriesID, false, 1, cStartingBerriesMinDist, cStartingBerriesMaxDist, cStartingObjectAvoidanceMeters);

   // Starting hunt.
   int startingHuntID = rmObjectDefCreate("starting hunt");
   rmObjectDefAddItem(startingHuntID, cUnitTypeElk, xsRandInt(8, 9));
   rmObjectDefAddConstraint(startingHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(startingHuntID, vDefaultForceInTowerLOS);
   addObjectLocsPerPlayer(startingHuntID, false, 1, cStartingHuntMinDist, cStartingHuntMaxDist, cStartingObjectAvoidanceMeters);

   // Chicken.
   int startingChickenID = rmObjectDefCreate("starting chicken");
   rmObjectDefAddItem(startingChickenID, cUnitTypeChicken, xsRandInt(5, 7));
   rmObjectDefAddConstraint(startingChickenID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidImpassableLand);
   addObjectLocsPerPlayer(startingChickenID, false, 1, cStartingChickenMinDist, cStartingChickenMaxDist, cStartingObjectAvoidanceMeters);

   // Herdables.
   int startingHerdID = rmObjectDefCreate("starting herd");
   rmObjectDefAddItem(startingHerdID, cUnitTypeCow, xsRandInt(2, 4));
   rmObjectDefAddConstraint(startingHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidImpassableLand);
   addObjectLocsPerPlayer(startingHerdID, true, 1, cStartingHerdMinDist, cStartingHerdMaxDist);

   generateLocs("starting food locs");

   rmSetProgress(0.4);

   // Gold.
   float avoidGoldMeters = 40.0;

   // Medium gold.
   int closeGoldID = objectDefCreateTracked("close gold");
   rmObjectDefAddItem(closeGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeGoldID, 55.0);
   if(gameIs1v1() == true)
   {
      addMirroredObjectLocsPerPlayerPair(closeGoldID, false, 1, 55.0, 65.0, avoidGoldMeters);
   }
   else
   {
      addObjectLocsPerPlayer(closeGoldID, false, 1, 50.0, 75.0, avoidGoldMeters);
   }

   // Bonus gold.
   int bonusGoldID = objectDefCreateTracked("bonus gold");
   rmObjectDefAddItem(bonusGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(bonusGoldID, 70.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusGoldID, false, xsRandInt(3, 4) * getMapAreaSizeFactor(), 70.0, -1.0, avoidGoldMeters);
   }
   else
   {
      addObjectLocsPerPlayer(bonusGoldID, false, xsRandInt(3, 4) * getMapAreaSizeFactor(), 70.0, -1.0, avoidGoldMeters);
   }

   generateLocs("gold locs");

   rmSetProgress(0.5);

   // Hunt.
   float avoidHuntMeters = 40.0;

   // Close hunt.
   int closeHuntID = objectDefCreateTracked("close hunt");
   rmObjectDefAddItem(closeHuntID, cUnitTypeDeer, xsRandInt(5, 9));
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeHuntID, 55.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeHuntID, false, 1, 55.0, 80.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(closeHuntID, false, 1, 55.0, 85.0, avoidHuntMeters);
   }

   // Far hunt.
   float farHuntFloat = xsRandFloat(0.0, 1.0);
   int farHuntID = objectDefCreateTracked("far hunt");
   if(farHuntFloat < 1.0 / 3.0)
   {
      rmObjectDefAddItem(farHuntID, cUnitTypeElk, xsRandInt(6, 9));
   }
   else if(farHuntFloat < 2.0 / 3.0)
   {
      rmObjectDefAddItem(farHuntID, cUnitTypeCaribou, xsRandInt(6, 9));
   }
   else
   {
      rmObjectDefAddItem(farHuntID, cUnitTypeAurochs, xsRandInt(2, 4));
   }
   rmObjectDefAddConstraint(farHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(farHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(farHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(farHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(farHuntID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(farHuntID, 75.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(farHuntID, false, 1, 75.0, -1.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(farHuntID, false, 1, 75.0, -1.0, avoidHuntMeters);
   }

   // Other map sizes hunt.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int largeMapHuntID = objectDefCreateTracked("large map hunt");
      float largeHuntFloat = xsRandFloat(0.0, 1.0);
      if(largeHuntFloat < 1.0 / 3.0)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeElk, xsRandInt(6, 11));
      }
      else if(largeHuntFloat < 2.0 / 3.0)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeCaribou, xsRandInt(8, 12));
      }
      else
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeAurochs, xsRandInt(2, 4));
      }

      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidImpassableLand);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidSettlementRange);
      addObjectDefPlayerLocConstraint(largeMapHuntID, 100.0);
      addObjectLocsPerPlayer(largeMapHuntID, false, 1 * getMapSizeBonusFactor(), 100.0, -1.0, avoidHuntMeters);
   }

   generateLocs("hunt locs");

   // Berries.
   float avoidBerriesMeters = 40.0;

   int farBerries1ID = objectDefCreateTracked("far berries 1");
   rmObjectDefAddItem(farBerries1ID, cUnitTypeBerryBush, xsRandInt(7, 10), cBerryClusterRadius);
   rmObjectDefAddConstraint(farBerries1ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(farBerries1ID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(farBerries1ID, vDefaultBerriesAvoidImpassableLand);
   rmObjectDefAddConstraint(farBerries1ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(farBerries1ID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(farBerries1ID, 70.0);
   addObjectLocsPerPlayer(farBerries1ID, false, 1 * getMapSizeBonusFactor(), 70.0, -1.0, avoidBerriesMeters);

   int farBerries2ID = objectDefCreateTracked("far berries 2");
   rmObjectDefAddItem(farBerries2ID, cUnitTypeBerryBush, xsRandInt(6, 10), cBerryClusterRadius);
   rmObjectDefAddConstraint(farBerries2ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(farBerries2ID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(farBerries2ID, vDefaultBerriesAvoidImpassableLand);
   rmObjectDefAddConstraint(farBerries2ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(farBerries2ID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(farBerries2ID, 70.0);
   addObjectLocsPerPlayer(farBerries2ID, false, 1 * getMapSizeBonusFactor(), 70.0, -1.0, avoidBerriesMeters);

   generateLocs("berries locs");

   // Herdables.
   float avoidHerdMeters = 40.0;

   int closeHerdID = objectDefCreateTracked("close herd");
   rmObjectDefAddItem(closeHerdID, cUnitTypeCow, xsRandInt(2, 3));
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidTowerLOS);
   addObjectLocsPerPlayer(closeHerdID, false, 1, 50.0, 70.0, avoidHerdMeters);

   int bonusHerdID = objectDefCreateTracked("bonus herd");
   rmObjectDefAddItem(bonusHerdID, cUnitTypeCow, xsRandInt(1, 2));
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidTowerLOS);
   addObjectLocsPerPlayer(bonusHerdID, false, xsRandInt(1, 2) * getMapSizeBonusFactor(), 70.0, -1.0, avoidHerdMeters);

   generateLocs("herd locs");

   // Predators.
   float avoidPredatorMeters = 40.0;

   int predatorID = objectDefCreateTracked("predator");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(predatorID, cUnitTypeWolf, xsRandInt(2, 3));
   }
   else
   {
      rmObjectDefAddItem(predatorID, cUnitTypeBear, xsRandInt(1, 2));
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

   int relicID = objectDefCreateTracked("relic");
   rmObjectDefAddItem(relicID, cUnitTypeRelic, 1);
   rmObjectDefAddItem(relicID, cUnitTypeColumns, xsRandInt(2, 3), 4.0);
   rmObjectDefAddItem(relicID, cUnitTypeColumnsBroken, xsRandInt(2, 3), 4.0);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidAll);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidImpassableLand);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(relicID, 70.0);
   addObjectLocsPerPlayer(relicID, false, 2 * getMapAreaSizeFactor(), 70.0, -1.0, avoidRelicMeters);

   generateLocs("relic locs");

   rmSetProgress(0.6);

   // Forests.
   float avoidForestMeters = 30.0;

   int forestDefID = rmAreaDefCreate("forest");
   rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(80), rmTilesToAreaFraction(120));
   rmAreaDefSetForestType(forestDefID, cForestNorseOakLateAutumn);
   rmAreaDefSetAvoidSelfDistance(forestDefID, avoidForestMeters);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidImpassableLand10);
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
   buildAreaDefInTeamAreas(forestDefID, 7 * getMapAreaSizeFactor());

   // Stragglers.
   placeStartingStragglers(cUnitTypeTreeOak);

   rmSetProgress(0.7);

   // Embellishment.
   // Player road path definition.
   int pathDefID = rmPathDefCreate("player connection path");
   rmPathDefSetCostNoise(pathDefID, 0.0, 10.0);
   rmPathDefAddConstraint(pathDefID, vDefaultAvoidImpassableLand4);
   rmPathDefAddConstraint(pathDefID, vDefaultAvoidKotH);
   rmPathDefAddConstraint(pathDefID, rmCreateTypeDistanceConstraint(cUnitTypeResource, 3.0));

   // Player road areas built on the connections.
   int pathAreaDefID = rmAreaDefCreate("player connection area");
   rmAreaDefSetTerrainType(pathAreaDefID, cTerrainNorseRoad);

   // Use both to build player connections (only 1 tile wide, so minPathWidth 0.0).
   createPlayerConnections("player connection", pathDefID, pathAreaDefID, 0.0);

   rmSetProgress(0.8);

   // Relic decoration.
   float relicAreaMinFraction = rmTilesToAreaFraction(10);
   float relicAreaMaxFraction = rmTilesToAreaFraction(20);

   int numRelics = rmObjectDefGetNumberCreatedObjects(relicID);

   for(int i = 0; i < numRelics; i++)
   {
      int objectID = rmObjectDefGetCreatedObject(relicID, i);
      vector objectLoc = rmObjectGetLoc(objectID);

      if(objectLoc == cInvalidVector)
      {
         continue;
      }

      int relicAreaID = rmAreaCreate("relic area " + i);
      rmAreaSetLoc(relicAreaID, objectLoc);
      rmAreaSetTerrainType(relicAreaID, cTerrainNorseRoad);
      rmAreaSetSize(relicAreaID, xsRandFloat(relicAreaMinFraction, relicAreaMaxFraction));

      rmAreaAddConstraint(relicAreaID, vDefaultAvoidImpassableLand4);

      rmAreaBuild(relicAreaID);
   }

   // Gold areas.
   buildAreaUnderObjectDef(startingGoldID, cTerrainNorseGrassRocks2, cTerrainNorseGrassRocks1, 6.0);
   buildAreaUnderObjectDef(closeGoldID, cTerrainNorseGrassRocks2, cTerrainNorseGrassRocks1, 6.0);
   buildAreaUnderObjectDef(bonusGoldID, cTerrainNorseGrassRocks2, cTerrainNorseGrassRocks1, 6.0);

   // Berries areas.
   buildAreaUnderObjectDef(startingBerriesID, cTerrainNorseGrass2, cTerrainNorseGrass1, 10.0);
   buildAreaUnderObjectDef(farBerries1ID, cTerrainNorseGrass2, cTerrainNorseGrass1, 10.0);
   buildAreaUnderObjectDef(farBerries2ID, cTerrainNorseGrass2, cTerrainNorseGrass1, 10.0);

   rmSetProgress(0.9);

   // Random trees.
   int randomTreeID = rmObjectDefCreate("random tree");
   rmObjectDefAddItem(randomTreeID, cUnitTypeTreeOak, 1);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidImpassableLand);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidTree);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefAddConstraint(randomTreeID, rmCreateTerrainTypeDistanceConstraint(cTerrainNorseRoad, 2.0));
   rmObjectDefPlaceAnywhere(randomTreeID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   // Rocks.
   int rockTinyID = rmObjectDefCreate("rock tiny");
   rmObjectDefAddItem(rockTinyID, cUnitTypeRockNorseTiny, 1);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefPlaceAnywhere(rockTinyID, 0, 40 * cNumberPlayers * getMapAreaSizeFactor());

   // Grass.
   int grassID = rmObjectDefCreate("grass");
   rmObjectDefAddItem(grassID, cUnitTypePlantNorseGrass, 1);
   rmObjectDefAddConstraint(grassID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(grassID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefPlaceAnywhere(grassID, 0, 40 * cNumberPlayers * getMapAreaSizeFactor());

   // Bush.
   int bushID = rmObjectDefCreate("bush");
   rmObjectDefAddItem(bushID, cUnitTypePlantNorseBush, 1);
   rmObjectDefAddConstraint(bushID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(bushID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefPlaceAnywhere(bushID, 0, 20 * cNumberPlayers * getMapAreaSizeFactor());

   // Shrub.
   int shrubID = rmObjectDefCreate("shrub");
   rmObjectDefAddItem(shrubID, cUnitTypePlantNorseShrub, 1);
   rmObjectDefAddConstraint(shrubID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(shrubID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefPlaceAnywhere(shrubID, 0, 20 * cNumberPlayers * getMapAreaSizeFactor());

   // Weeds.
   int weedsID = rmObjectDefCreate("weeds");
   rmObjectDefAddItem(weedsID, cUnitTypePlantNorseWeeds, xsRandInt(1, 4));
   rmObjectDefAddConstraint(weedsID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(weedsID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefPlaceAnywhere(weedsID, 0, 20 * cNumberPlayers * getMapAreaSizeFactor());

   // Logs.
   int logID = rmObjectDefCreate("log");
   rmObjectDefAddItem(logID, cUnitTypeRottingLog, 1);
   rmObjectDefAddConstraint(logID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(logID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(logID, vDefaultAvoidSettlementRange);
   rmObjectDefPlaceAnywhere(logID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   int logGroupID = rmObjectDefCreate("log group");
   rmObjectDefAddItem(logGroupID, cUnitTypeRottingLog, 2, 2.0);
   rmObjectDefAddConstraint(logGroupID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(logGroupID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(logGroupID, vDefaultAvoidSettlementRange);
   rmObjectDefPlaceAnywhere(logGroupID, 0, 5 * cNumberPlayers * getMapAreaSizeFactor());

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeHawk, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   rmSetProgress(1.0);
}
