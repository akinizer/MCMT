include "lib2/rm_core.xs";

void generate()
{
   rmSetProgress(0.0);

   // Define mixes.
   int baseMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(baseMixID, cNoiseRandom);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptSand1, 3.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptSand2, 1.0);

   // Water overrides.
   rmWaterTypeAddBeachLayer(cWaterEgyptLake, cTerrainEgyptGrassRocks2, 2.0, 2.0);
   rmWaterTypeAddBeachLayer(cWaterEgyptLake, cTerrainEgyptGrassRocks1, 4.0, 2.0);
   rmWaterTypeAddBeachLayer(cWaterEgyptLake, cTerrainEgyptGrass1, 6.0, 2.0);
   rmWaterTypeAddBeachLayer(cWaterEgyptLake, cTerrainEgyptGrassDirt1, 8.0, 2.0);
   rmWaterTypeAddBeachLayer(cWaterEgyptLake, cTerrainEgyptGrassDirt2, 12.0, 0.0);
   // rmWaterTypeAddBeachLayer(cWaterEgyptLake, cTerrainEgyptGrassDirt3, 12.0, 2.0);
   // rmWaterTypeAddShoreLayer(cWaterEgyptLake, cTerrainEgyptBeach1, 0.0, 0.0);
   // rmWaterTypeSetFloorTerrain(cWaterEgyptLake, cTerrainEgyptBeach1);

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
   rmSetTeamSpacingModifier(xsRandFloat(0.85, 0.9));
   rmPlacePlayersOnCircle(0.35);

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCivFromCulture(cCultureEgyptian);

   // KotH.
   placeKotHObjects();

   // Lighting.
   rmSetLighting(cLightingSetRmBlueLagoon01);

   rmSetProgress(0.1);

   // Global elevation.
   rmAddGlobalHeightNoise(cNoiseFractalSum, 4.0, 0.1, 6, 0.3);

   // Stuff to avoid for dead embellishment.
   int grassAreaClassID = rmClassCreate();

   // Base beautification.
   float baseBeautificationSize = rmRadiusToAreaFraction(32.5);

   for(int i = 1; i <= cNumberPlayers; i++)
   {
      int p = vDefaultTeamPlayerOrder[i];

      int baseBeautificationAreaID = rmAreaCreate("base area beautification " + p);
      rmAreaSetLocPlayer(baseBeautificationAreaID, p);
      rmAreaSetSize(baseBeautificationAreaID, baseBeautificationSize);
      rmAreaAddTerrainLayer(baseBeautificationAreaID, cTerrainEgyptGrassDirt2, 0);
      rmAreaAddTerrainLayer(baseBeautificationAreaID, cTerrainEgyptGrassDirt1, 1, 2);
      rmAreaSetTerrainType(baseBeautificationAreaID, cTerrainEgyptGrass1);
      rmAreaAddToClass(baseBeautificationAreaID, grassAreaClassID);
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
      addSimObjectLocsPerPlayerPair(firstSettlementID, false, 1, 65.0, 80.0, cSettlementDist1v1, cBiasBackward);
      addSimObjectLocsPerPlayerPair(secondSettlementID, false, 1, 65.0, 90.0, cSettlementDist1v1, cBiasAggressive);
   }
   else
   {
      // Randomize inside/outside.
      int allyBias = getRandomAllyBias();
      addObjectLocsPerPlayer(firstSettlementID, false, 1, 65.0, 80.0, cCloseSettlementDist, cBiasBackward | cBiasAllyInside);
      addObjectLocsPerPlayer(secondSettlementID, false, 1, 65.0, 90.0, cFarSettlementDist, cBiasAggressive | allyBias);
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
      addObjectLocsPerPlayer(bonusSettlementID, false, 1 * getMapAreaSizeFactor(), 90.0, -1.0, 100.0);
   }

   generateLocs("settlement locs");

   rmSetProgress(0.3);

   // Ponds.
   int pondClassID = rmClassCreate();
   int numPonds = xsRandInt(1, 2) * cNumberPlayers * getMapAreaSizeFactor();
   if(gameIs1v1() == true)
   {
      numPonds = xsRandInt(3, 4) * getMapAreaSizeFactor();
   }

   int pondAvoidPond = rmCreateClassDistanceConstraint(pondClassID, 30.0);
   int pondAvoidEdge = createSymmetricBoxConstraint(rmXMetersToFraction(32.0), rmZMetersToFraction(32.0));
   int pondAvoidSettlement = rmCreateTypeDistanceConstraint(cUnitTypeSettlement, 30.0);
   int pondAvoidStartingLoc = createPlayerLocDistanceConstraint(60.0);

   float pondMinSize = rmTilesToAreaFraction(250);
   float pondMaxSize = rmTilesToAreaFraction(300);

   for(int i = 0; i < numPonds; i++)
   {
      int pondID = rmAreaCreate("pond " + i);

      rmAreaSetSize(pondID, xsRandFloat(pondMinSize, pondMaxSize));
      rmAreaSetWaterType(pondID, cWaterEgyptLake);

      rmAreaSetCoherence(pondID, 0.0);

      rmAreaSetBlobs(pondID, 3, 5);
      rmAreaSetBlobDistance(pondID, 0.0, 10.0);

      rmAreaAddOriginConstraint(pondID, pondAvoidEdge);
      rmAreaAddConstraint(pondID, pondAvoidPond);
      rmAreaAddConstraint(pondID, pondAvoidSettlement);
      rmAreaAddConstraint(pondID, pondAvoidStartingLoc);
      rmAreaAddConstraint(pondID, vDefaultAvoidKotH);
      rmAreaAddToClass(pondID, pondClassID);

      rmAreaBuild(pondID);
   }

   // Cliffs.
   int cliffClassID = rmClassCreate();
   int numCliffs = 6 * cNumberPlayers * getMapAreaSizeFactor();
   float cliffMinSize = rmTilesToAreaFraction(200);
   float cliffMaxSize = rmTilesToAreaFraction(250);

   int cliffAvoidCliff = rmCreateClassDistanceConstraint(cliffClassID, 24.0);
   int cliffAvoidEdge = createSymmetricBoxConstraint(rmXMetersToFraction(16.0), rmZMetersToFraction(16.0));
   int cliffAvoidBuildings = rmCreateTypeDistanceConstraint(cUnitTypeBuilding, 20.0);

   for(int i = 0; i < numCliffs; i++)
   {
      int cliffID = rmAreaCreate("cliff " + i);

      rmAreaSetSize(cliffID, xsRandFloat(cliffMinSize, cliffMaxSize));
      rmAreaSetCliffType(cliffID, cCliffEgyptSand);
      rmAreaSetCliffRamps(cliffID, 2, 0.25, 0.0, 1.0);
      rmAreaSetCliffRampSteepness(cliffID, 1.25);
      rmAreaSetCliffEmbellishmentDensity(cliffID, 0.25);

      rmAreaSetHeightRelative(cliffID, 6.0);
      rmAreaAddHeightBlend(cliffID, cBlendAll, cFilter5x5Gaussian);
      rmAreaSetCoherence(cliffID, 0.5);
      rmAreaSetEdgeSmoothDistance(cliffID, 2);

      rmAreaAddOriginConstraint(cliffID, cliffAvoidEdge);
      rmAreaAddConstraint(cliffID, vDefaultAvoidWater8);
      rmAreaAddConstraint(cliffID, cliffAvoidCliff);
      rmAreaAddConstraint(cliffID, cliffAvoidBuildings);
      rmAreaSetConstraintBuffer(cliffID, 0.0, 10.0); 
      rmAreaAddToClass(cliffID, cliffClassID);

      rmAreaBuild(cliffID);
   }

   rmSetProgress(0.4);

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

   // Berries.
   int startingBerriesID = rmObjectDefCreate("starting berries");
   rmObjectDefAddItem(startingBerriesID, cUnitTypeBerryBush, xsRandInt(6, 9), cBerryClusterRadius);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidImpassableLand);
   addObjectLocsPerPlayer(startingBerriesID, false, 1, cStartingBerriesMinDist, cStartingBerriesMaxDist, cStartingObjectAvoidanceMeters);
   
   // // Starting hunt.
   int startingHuntID = rmObjectDefCreate("starting hunt");
   rmObjectDefAddItem(startingHuntID, cUnitTypeGiraffe, 4);
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
   rmObjectDefAddItem(startingHerdID, cUnitTypeGoat, xsRandInt(1, 3));
   rmObjectDefAddConstraint(startingHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidImpassableLand);
   addObjectLocsPerPlayer(startingHerdID, true, 1, cStartingHerdMinDist, cStartingHerdMaxDist);

   generateLocs("starting food locs");

   // Starting forests.
   float avoidStartingForestMeters = 30.0;

   int forestDefID = rmAreaDefCreate("forest");
   rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(60), rmTilesToAreaFraction(70));
   rmAreaDefSetForestType(forestDefID, cForestEgyptPalmGrassMix);
   rmAreaDefSetBlobs(forestDefID, 4, 5);
   rmAreaDefSetBlobDistance(forestDefID, 10.0);
   rmAreaDefSetAvoidSelfDistance(forestDefID, 30.0);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidImpassableLand10);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidWater6);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidTownCenter);

   if(gameIs1v1() == true)
   {
      addSimAreaLocsPerPlayerPair(forestDefID, 3, cStartingForestMinDist, cStartingForestMaxDist, avoidStartingForestMeters);
   }
   else
   {
      addAreaLocsPerPlayer(forestDefID, 3, cStartingForestMinDist, cStartingForestMaxDist, avoidStartingForestMeters);
   }

   generateLocs("starting forest locs");

   rmSetProgress(0.5);

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
   addObjectDefPlayerLocConstraint(closeGoldID, 65.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeGoldID, false, 1, 65.0, 80.0, avoidGoldMeters, cBiasForward);
   }
   else
   {
      addObjectLocsPerPlayer(closeGoldID, false, 1, 65.0, 80.0, avoidGoldMeters);
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
   addObjectLocsPerPlayer(bonusGoldID, false, 3 * getMapAreaSizeFactor(), 80.0, -1.0, avoidGoldMeters);

   generateLocs("gold locs");

   rmSetProgress(0.6);

   // Hunt.
   float avoidHuntMeters = 50.0;

   // Close hunt 1.
   float closeHunt1Float = xsRandFloat(0.0, 1.0);
   int closeHunt1ID = rmObjectDefCreate("close hunt 1");
   if(closeHunt1Float < 1.0 / 3.0)
   {
      rmObjectDefAddItem(closeHunt1ID, cUnitTypeZebra, xsRandInt(4, 6));
   }
   else if(closeHunt1Float < 2.0 / 3.0)
   {
      rmObjectDefAddItem(closeHunt1ID, cUnitTypeGazelle, xsRandInt(6, 8));
   }
   else
   {
      rmObjectDefAddItem(closeHunt1ID, cUnitTypeGiraffe, xsRandInt(3, 4));
   }
   rmObjectDefAddConstraint(closeHunt1ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHunt1ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHunt1ID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHunt1ID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(closeHunt1ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHunt1ID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeHunt1ID, 55.0);
   addObjectLocsPerPlayer(closeHunt1ID, false, 1, 55.0, 85.0, avoidHuntMeters);

   // Close hunt 2.
   int closeHunt2ID = rmObjectDefCreate("close hunt 2");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(closeHunt2ID, cUnitTypeElephant, 1);
   }
   else
   {
      rmObjectDefAddItem(closeHunt2ID, cUnitTypeRhinoceros, xsRandInt(1, 2), 2.0);
   }
   rmObjectDefAddItem(closeHunt2ID, cUnitTypeGazelle, 2, 2.0);
   rmObjectDefAddConstraint(closeHunt2ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHunt2ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHunt2ID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHunt2ID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(closeHunt2ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHunt2ID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeHunt2ID, 65.0);
   addObjectLocsPerPlayer(closeHunt2ID, false, 1, 65.0, 95.0, avoidHuntMeters);

   // Close hunt 3.
   float closeHunt3Float = xsRandFloat(0.0, 1.0);
   int closeHunt3ID = rmObjectDefCreate("close hunt 3");
   if(closeHunt3Float < 1.0 / 3.0)
   {
      rmObjectDefAddItem(closeHunt3ID, cUnitTypeGazelle, xsRandInt(0, 4));
      rmObjectDefAddItem(closeHunt3ID, cUnitTypeZebra, xsRandInt(4, 6));
   }
   else if(closeHunt3Float < 2.0 / 3.0)
   {
      rmObjectDefAddItem(closeHunt3ID, cUnitTypeGazelle, xsRandInt(0, 4));
      rmObjectDefAddItem(closeHunt3ID, cUnitTypeGiraffe, xsRandInt(3, 4));
   }
   else
   {
      rmObjectDefAddItem(closeHunt3ID, cUnitTypeZebra, xsRandInt(4, 9));
   }
   rmObjectDefAddConstraint(closeHunt3ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHunt3ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHunt3ID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHunt3ID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(closeHunt3ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHunt3ID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeHunt3ID, 75.0);
   addObjectLocsPerPlayer(closeHunt3ID, false, 1, 75.0, 105.0, avoidHuntMeters);

   // Bonus hunt 1.
   int bonusHunt1ID = rmObjectDefCreate("bonus hunt 1");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(bonusHunt1ID, cUnitTypeElephant, xsRandInt(1, 2));
   }
   else
   {
      rmObjectDefAddItem(bonusHunt1ID, cUnitTypeRhinoceros, xsRandInt(1, 3));
   }
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(bonusHunt1ID, 85.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusHunt1ID, false, 1, 85.0, -1.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(bonusHunt1ID, false, 1, 85.0, -1.0, avoidHuntMeters);
   }

   if(gameIs1v1() == false)
   {
      // Bonus hunt 2.
      int bonusHunt2ID = rmObjectDefCreate("bonus hunt 2");
      rmObjectDefAddItem(bonusHunt2ID, cUnitTypeGazelle, xsRandInt(2, 4));
      rmObjectDefAddItem(bonusHunt2ID, cUnitTypeGiraffe, xsRandInt(2, 4));
      rmObjectDefAddConstraint(bonusHunt2ID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(bonusHunt2ID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(bonusHunt2ID, vDefaultFoodAvoidImpassableLand);
      rmObjectDefAddConstraint(bonusHunt2ID, vDefaultFoodAvoidWater);
      rmObjectDefAddConstraint(bonusHunt2ID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(bonusHunt2ID, vDefaultAvoidSettlementRange);
      addObjectDefPlayerLocConstraint(bonusHunt2ID, 100.0);
      addObjectLocsPerPlayer(bonusHunt2ID, false, 1, 100.0, -1.0, avoidHuntMeters);
   }

   // Other map sizes hunt.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      float largeMapHuntFloat = xsRandFloat(0.0, 1.0);
      int largeMapHuntID = rmObjectDefCreate("large map hunt");
      if(largeMapHuntFloat < 1.0 / 4.0)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeGazelle, xsRandInt(3, 7));
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeZebra, xsRandInt(3, 9));
      }
      else if(largeMapHuntFloat < 2.0 / 4.0)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeGazelle, xsRandInt(4, 9));
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeGiraffe, xsRandInt(2, 6));
      }
      else if(largeMapHuntFloat < 3.0 / 4.0)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeRhinoceros, xsRandInt(2, 5));
      }
      else
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeElephant, xsRandInt(1, 3));
      }
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidImpassableLand);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidWater);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidSettlementRange);
      addObjectDefPlayerLocConstraint(largeMapHuntID, 100.0);
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
   rmObjectDefAddConstraint(berriesID, vDefaultBerriesAvoidWater);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(berriesID, 80.0);
   addObjectLocsPerPlayer(berriesID, false, 1 * getMapSizeBonusFactor(), 80.0, -1.0, avoidBerriesMeters);

   generateLocs("berries locs");

   // Herdables.
   float avoidHerdMeters = 50.0;

   int closeHerdID = rmObjectDefCreate("close herd");
   rmObjectDefAddItem(closeHerdID, cUnitTypeGoat, xsRandInt(1, 2));
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidWater);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidTowerLOS);
   addObjectDefPlayerLocConstraint(closeHerdID, 50.0);
   addObjectLocsPerPlayer(closeHerdID, false, 1, 50.0, 70.0, avoidHerdMeters);

   int bonusHerdID = rmObjectDefCreate("bonus herd");
   rmObjectDefAddItem(bonusHerdID, cUnitTypeGoat, xsRandInt(1, 3));
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidWater);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidTowerLOS);
   addObjectDefPlayerLocConstraint(bonusHerdID, 70.0);
   addObjectLocsPerPlayer(bonusHerdID, false, xsRandInt(1, 2) * getMapAreaSizeFactor(), 70.0, -1.0, avoidHerdMeters);

   generateLocs("herd locs");

   // Predators.
   float avoidPredatorMeters = 50.0;

   int predatorID = rmObjectDefCreate("predator");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(predatorID, cUnitTypeLion, xsRandInt(1, 2));
   }
   else
   {
      rmObjectDefAddItem(predatorID, cUnitTypeHyena, xsRandInt(1, 3));
   }
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidImpassableLand);
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
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidImpassableLand);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidWater);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(relicID, 80.0);
   addObjectLocsPerPlayer(relicID, false, 2 * getMapAreaSizeFactor(), 80.0, -1.0, avoidRelicMeters);

   generateLocs("relic locs");

   rmSetProgress(0.8);
   
   // Stragglers.
   placeStartingStragglers(cUnitTypeTreePalm);

   // Global forests.
   rmAreaDefCreateAndBuildAreas(forestDefID, 10 * cNumberPlayers);

   // Areas under forests.
   int forestSurroundAreaDefID = rmAreaDefCreate("forest surround");
   rmAreaDefSetSize(forestSurroundAreaDefID, 1.0);
   rmAreaDefSetTerrainType(forestSurroundAreaDefID, cTerrainEgyptGrass1);
   rmAreaDefAddTerrainLayer(forestSurroundAreaDefID, cTerrainEgyptGrassDirt2, 0);
   rmAreaDefAddConstraint(forestSurroundAreaDefID, vDefaultAvoidImpassableLand6);
   rmAreaDefAddTerrainConstraint(forestSurroundAreaDefID, rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptGrass1, 1.0));
   rmAreaDefAddTerrainConstraint(forestSurroundAreaDefID, rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptGrass2, 1.0));
   rmAreaDefAddToClass(forestSurroundAreaDefID, grassAreaClassID);

   int numForestAreas = rmAreaDefGetNumberCreatedAreas(forestDefID);

   for(int i = 0; i < numForestAreas; i++)
   {
      int forestID = rmAreaDefGetCreatedArea(forestDefID, i);

      vector forestLoc = rmAreaGetLoc(forestID);
      if(forestLoc == cInvalidVector)
      {
         break;
      }

      // Build an area around the forest, but do not overpaint the original forest (or grass that is already there).
      int forestSurroundID = rmAreaDefCreateArea(forestSurroundAreaDefID);
      rmAreaSetLoc(forestSurroundID, forestLoc);
      rmAreaAddConstraint(forestSurroundID, rmCreateAreaMaxDistanceConstraint(forestID, 6.0));
      rmAreaAddTerrainConstraint(forestSurroundID, rmCreateAreaDistanceConstraint(forestID, 1.0));

      rmAreaBuild(forestSurroundID);
   }

   rmSetProgress(0.9);

   // Embellishment.
   // Gold areas.
   buildAreaUnderObjectDef(startingGoldID, cTerrainEgyptGrassRocks2, cTerrainEgyptGrassRocks1, 6.0);
   buildAreaUnderObjectDef(closeGoldID, cTerrainEgyptDirtRocks2, cTerrainEgyptDirtRocks1, 6.0);
   buildAreaUnderObjectDef(bonusGoldID, cTerrainEgyptDirtRocks2, cTerrainEgyptDirtRocks1, 6.0);

   // Berries areas.
   // buildAreaUnderObjectDef(startingBerriesID, cTerrainEgyptGrassDirt1, cTerrainEgyptGrassDirt2, 10.0);
   buildAreaUnderObjectDef(berriesID, cTerrainEgyptGrass1, cTerrainEgyptGrassDirt2, 10.0);

   // Random trees.
   int randomTreeID = rmObjectDefCreate("random tree");
   rmObjectDefAddItem(randomTreeID, cUnitTypeTreePalm, 1);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidImpassableLand);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidTree);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefPlaceAnywhere(randomTreeID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   // Terrain constraints for embellishment.
   int avoidGreenArea = rmCreateClassDistanceConstraint(grassAreaClassID, 1.0);
   int avoidEgyptSand1 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptSand1, 1.0);
   int avoidEgyptSand2 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptSand2, 1.0);
   int avoidEgyptRoad1 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptRoad1, 1.0);
   int avoidEgyptSand3 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptSand3, 1.0);
   int avoidEgyptDirtRocks1 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptDirtRocks1, 1.0);
   int avoidEgyptDirtRocks2 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptDirtRocks2, 1.0);

   // Dead shrubs.
   int shrubDeadID = rmObjectDefCreate("shrub dead");
   rmObjectDefAddItemRange(shrubDeadID, cUnitTypePlantDeadShrub, 1, 2);
   rmObjectDefAddConstraint(shrubDeadID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(shrubDeadID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(shrubDeadID, vDefaultAvoidWater8);
   rmObjectDefAddConstraint(shrubDeadID, avoidGreenArea);
   rmObjectDefPlaceAnywhere(shrubDeadID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());
   
   // Dead bushes.
   int bushDeadID = rmObjectDefCreate("bush dead");
   rmObjectDefAddItemRange(bushDeadID, cUnitTypePlantDeadBush, 1, 2);
   rmObjectDefAddConstraint(bushDeadID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(bushDeadID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(bushDeadID, vDefaultAvoidWater8);
   rmObjectDefAddConstraint(bushDeadID, avoidGreenArea);
   rmObjectDefPlaceAnywhere(bushDeadID, 0, 15 * cNumberPlayers * getMapAreaSizeFactor());
   
   // Dead weeds.
   int weedDeadID = rmObjectDefCreate("weed dead");
   rmObjectDefAddItemRange(weedDeadID, cUnitTypePlantDeadWeeds, 1, 2);
   rmObjectDefAddConstraint(weedDeadID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(weedDeadID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(weedDeadID, vDefaultAvoidWater8);
   rmObjectDefAddConstraint(weedDeadID, avoidGreenArea);
   rmObjectDefPlaceAnywhere(weedDeadID, 0, 15 * cNumberPlayers * getMapAreaSizeFactor());

   // Shrubs.
   int shrubEgyptID = rmObjectDefCreate("shrub egypt");
   rmObjectDefAddItemRange(shrubEgyptID, cUnitTypePlantEgyptianShrub, 1, 2);
   rmObjectDefAddConstraint(shrubEgyptID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(shrubEgyptID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(shrubEgyptID, avoidEgyptSand1);
   rmObjectDefAddConstraint(shrubEgyptID, avoidEgyptSand2);
   rmObjectDefAddConstraint(shrubEgyptID, avoidEgyptSand3);
   rmObjectDefAddConstraint(shrubEgyptID, avoidEgyptRoad1);
   rmObjectDefAddConstraint(shrubEgyptID, avoidEgyptDirtRocks1);
   rmObjectDefAddConstraint(shrubEgyptID, avoidEgyptDirtRocks2);
   rmObjectDefPlaceAnywhere(shrubEgyptID, 0, 20 * cNumberPlayers * getMapAreaSizeFactor());
   
   // Bushes.
   int bushEgyptID = rmObjectDefCreate("bush egypt");
   rmObjectDefAddItemRange(bushEgyptID, cUnitTypePlantEgyptianBush, 1, 2);
   rmObjectDefAddConstraint(bushEgyptID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(bushEgyptID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(bushEgyptID, avoidEgyptSand1);
   rmObjectDefAddConstraint(bushEgyptID, avoidEgyptSand2);
   rmObjectDefAddConstraint(bushEgyptID, avoidEgyptSand3);
   rmObjectDefAddConstraint(bushEgyptID, avoidEgyptRoad1);
   rmObjectDefAddConstraint(bushEgyptID, avoidEgyptDirtRocks1);
   rmObjectDefAddConstraint(bushEgyptID, avoidEgyptDirtRocks2);
   rmObjectDefPlaceAnywhere(bushEgyptID, 0, 20 * cNumberPlayers * getMapAreaSizeFactor());
   
   // Fern.
   int fernEgyptID = rmObjectDefCreate("fern egypt");
   rmObjectDefAddItemRange(fernEgyptID, cUnitTypePlantEgyptianFern, 1, 2);
   rmObjectDefAddConstraint(fernEgyptID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(fernEgyptID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(fernEgyptID, avoidEgyptSand1);
   rmObjectDefAddConstraint(fernEgyptID, avoidEgyptSand2);
   rmObjectDefAddConstraint(fernEgyptID, avoidEgyptSand3);
   rmObjectDefAddConstraint(fernEgyptID, avoidEgyptRoad1);
   rmObjectDefAddConstraint(fernEgyptID, avoidEgyptDirtRocks1);
   rmObjectDefAddConstraint(fernEgyptID, avoidEgyptDirtRocks2);
   rmObjectDefPlaceAnywhere(fernEgyptID, 0, 20 * cNumberPlayers * getMapAreaSizeFactor());

   // Rocks.
   int rockTinyID = rmObjectDefCreate("rock tiny");
   rmObjectDefAddItem(rockTinyID, cUnitTypeRockEgyptTiny, 1);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefPlaceAnywhere(rockTinyID, 0, 50 * cNumberPlayers * getMapAreaSizeFactor());

   int rockSmallID = rmObjectDefCreate("rock small");
   rmObjectDefAddItem(rockSmallID, cUnitTypeRockEgyptSmall, 1);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefPlaceAnywhere(rockSmallID, 0, 50 * cNumberPlayers * getMapAreaSizeFactor());

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeVulture, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   rmSetProgress(1.0);
}
