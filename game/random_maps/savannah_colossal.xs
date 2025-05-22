include "lib2/rm_core.xs";

void generate()
{ 
   rmSetProgress(0.0);

   // Define mixes.
   int baseMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.2, 1);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptSavannah2, 3.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptSavannah1, 1.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptDirt2, 1.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptDirt3, 1.0);
   // rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.1, 2, 0.5);
   // rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptSavannah2, 4.0);
   // rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptSavannah1, 1.0);
   // rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptDirt2, 2.0);

   // Water overrides.
   rmWaterTypeAddBeachLayer(cWaterEgyptWateringHole, cTerrainEgyptBeach1, 3.0, 1.0);
   rmWaterTypeAddBeachLayer(cWaterEgyptWateringHole, cTerrainEgyptSavannah2, 5.0, 2.0);

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
   rmPlacePlayersOnCircle(xsRandFloat(0.325, 0.375));

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCivFromCulture(cCultureEgyptian);

   // Lighting.
   rmSetLighting(cLightingSetRmSavannah01);

   rmSetProgress(0.1);

   // Global elevation.
   rmAddGlobalHeightNoise(cNoiseFractalSum, 5.0, 0.05, 2, 0.5);

   // KotH.
   placeKotHObjects();

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
      addSimObjectLocsPerPlayerPair(firstSettlementID, false, 1, 60.0, 80.0, cSettlementDist1v1, cBiasBackward);
      addSimObjectLocsPerPlayerPair(secondSettlementID, false, 1, 80.0, 120.0, cSettlementDist1v1, cBiasAggressive);
   }
   else
   {
      addObjectLocsPerPlayer(firstSettlementID, false, 1, 60.0, 80.0, cCloseSettlementDist, cBiasBackward | cBiasAllyInside);
      addObjectLocsPerPlayer(secondSettlementID, false, 1, 70.0, 90.0, cFarSettlementDist, cBiasAggressive | getRandomAllyBias());
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
      addObjectLocsPerPlayer(bonusSettlementID, false, 1 * getMapAreaSizeFactor(), 90.0, -1.0, 80.0);
   }

   generateLocs("settlement locs");

   rmSetProgress(0.2);

   // Ponds.
   float pondSize = rmTilesToAreaFraction(250 * getMapAreaSizeFactor());
   int pondClassID = rmClassCreate();
   int pondAvoidPond = rmCreateClassDistanceConstraint(pondClassID, 50.0);
   int pondAvoidEdge = createSymmetricBoxConstraint(rmXMetersToFraction(16.0), rmZMetersToFraction(16.0));
   int pondAvoidSettlement = rmCreateTypeDistanceConstraint(cUnitTypeSettlement, 30.0);
   int pondAvoidStartingLoc = createPlayerLocDistanceConstraint(60.0);

   int pondID = rmAreaDefCreate("pond");
   rmAreaDefSetSize(pondID, pondSize);
   rmAreaDefSetWaterType(pondID, cWaterEgyptWateringHole);
   rmAreaDefSetWaterHeight(pondID, -3.0, cWaterHeightTypeMax);
   rmAreaDefSetWaterHeightBlend(pondID, cFilter5x5Gaussian, 16.0, 10);

   rmAreaDefSetBlobs(pondID, 3, 4);
   rmAreaDefSetBlobDistance(pondID, 10.0, 10.0);

   rmAreaDefAddConstraint(pondID, pondAvoidPond);
   rmAreaDefAddConstraint(pondID, pondAvoidEdge);
   rmAreaDefAddConstraint(pondID, pondAvoidSettlement);
   rmAreaDefAddConstraint(pondID, pondAvoidStartingLoc);
   rmAreaDefAddConstraint(pondID, vDefaultAvoidKotH);
   rmAreaDefAddToClass(pondID, pondClassID);

   buildAreaDefInTeamAreas(pondID, 1);

   rmSetProgress(0.3);

   // Starting objects.
   // Starting gold.
   int startingGoldID = rmObjectDefCreate("starting gold");
   rmObjectDefAddItem(startingGoldID, cUnitTypeMineGoldMedium, 1);
   rmObjectDefAddConstraint(startingGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(startingGoldID, vDefaultGoldAvoidWater);
   rmObjectDefAddConstraint(startingGoldID, vDefaultStartingGoldAvoidTower);
   rmObjectDefAddConstraint(startingGoldID, vDefaultForceStartingGoldNearTower);
   addObjectLocsPerPlayer(startingGoldID, false, 1, cStartingGoldMinDist, cStartingGoldMaxDist, cStartingObjectAvoidanceMeters, cBiasNotAggressive);

   generateLocs("starting gold locs");

   // Starting hunt.
   float startingHuntFloat = xsRandFloat(0.0, 1.0);
   int startingHuntID = rmObjectDefCreate("starting hunt");
   if(startingHuntFloat < 0.3)
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeZebra, 3);
      rmObjectDefAddItem(startingHuntID, cUnitTypeGazelle, 4);
   }
   else if(startingHuntFloat < 0.8)
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeZebra, 6);
   }
   else if(startingHuntFloat < 0.9)
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeRhinoceros, 1);
      rmObjectDefAddItem(startingHuntID, cUnitTypeGazelle, 5);
   }
   else
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeRhinoceros, 3);
   }
   rmObjectDefAddConstraint(startingHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(startingHuntID, vDefaultForceInTowerLOS);
   addObjectLocsPerPlayer(startingHuntID, false, 1, cStartingHuntMinDist, cStartingHuntMaxDist, cStartingObjectAvoidanceMeters);

   // Berries.
   int startingBerriesID = rmObjectDefCreate("starting berries");
   rmObjectDefAddItem(startingBerriesID, cUnitTypeBerryBush, xsRandInt(6, 9), cBerryClusterRadius);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidWater);
   addObjectLocsPerPlayer(startingBerriesID, false, 1, cStartingBerriesMinDist, cStartingBerriesMaxDist, cStartingObjectAvoidanceMeters);

   // Chicken.
   int startingChickenID = rmObjectDefCreate("starting chicken");
   rmObjectDefAddItem(startingChickenID, cUnitTypeChicken, xsRandInt(5, 7));
   rmObjectDefAddConstraint(startingChickenID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidWater);
   addObjectLocsPerPlayer(startingChickenID, false, 1, cStartingChickenMinDist, cStartingChickenMaxDist, cStartingObjectAvoidanceMeters);

   // Herdables.
   int startingHerdID = rmObjectDefCreate("starting herd");
   rmObjectDefAddItem(startingHerdID, cUnitTypeGoat, xsRandInt(3, 4));
   rmObjectDefAddConstraint(startingHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidWater);
   addObjectLocsPerPlayer(startingHerdID, true, 1, cStartingHerdMinDist, cStartingHerdMaxDist);

   generateLocs("starting food locs");

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
      addObjectLocsPerPlayer(closeGoldID, false, 1, 70.0, 80.0, avoidGoldMeters, cBiasForward);
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
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(bonusGoldID, 80.0);

   if(gameIs1v1() == true)
   {
      addObjectLocsPerPlayer(bonusGoldID, false, xsRandInt(2, 3) * getMapAreaSizeFactor(), 80.0, -1.0, avoidGoldMeters);
   }
   else
   {
      addObjectLocsPerPlayer(bonusGoldID, false, xsRandInt(3, 4) * getMapAreaSizeFactor(), 80.0, -1.0, avoidGoldMeters);
   }

   generateLocs("gold locs");

   rmSetProgress(0.5);

   // Hunt.
   float avoidHuntMeters = 50.0;

   // Close hunt.
   int closeHuntID = rmObjectDefCreate("close hunt");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeGiraffe, xsRandInt(4, 9));
   }
   else
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeGazelle, xsRandInt(6, 9));
   }
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeHuntID, 70.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeHuntID, false, 1, 70.0, 80.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(closeHuntID, false, 1, 70.0, 80.0, avoidHuntMeters);
   }

   // Bonus hunt 1.
   float bonusHunt1Float = xsRandFloat(0.0, 1.0);
   int bonusHunt1ID = rmObjectDefCreate("bonus hunt 1");
   if(bonusHunt1Float < 0.25)
   {
      rmObjectDefAddItem(bonusHunt1ID, cUnitTypeZebra, xsRandInt(3, 4));
      rmObjectDefAddItem(bonusHunt1ID, cUnitTypeGiraffe, xsRandInt(1, 2));
   }
   else if(bonusHunt1Float < 0.5)
   {
      rmObjectDefAddItem(bonusHunt1ID, cUnitTypeZebra, xsRandInt(6, 9));
   }
   else if(bonusHunt1Float < 0.75)
   {
      rmObjectDefAddItem(bonusHunt1ID, cUnitTypeGiraffe, xsRandInt(3, 4));
   }
   else
   {
      rmObjectDefAddItem(bonusHunt1ID, cUnitTypeGazelle, xsRandInt(6, 8));
   }
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(bonusHunt1ID, 80.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusHunt1ID, false, 1, 80.0, -1.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(bonusHunt1ID, false, 1, 80.0, -1.0, avoidHuntMeters);
   }

   // Bonus hunt 2.
   float bonusHunt2Float = xsRandFloat(0.0, 1.0);
   int bonusHunt2ID = rmObjectDefCreate("bonus hunt 2");
   if(bonusHunt2Float < 0.1)
   {
      rmObjectDefAddItem(bonusHunt2ID, cUnitTypeElephant, 3);
   }
   else if(bonusHunt2Float < 0.5)
   {
      rmObjectDefAddItem(bonusHunt2ID, cUnitTypeElephant, 2);
   }
   else if(bonusHunt2Float < 0.9)
   {
      rmObjectDefAddItem(bonusHunt2ID, cUnitTypeRhinoceros, 2);
   }
   else
   {
      rmObjectDefAddItem(bonusHunt2ID, cUnitTypeRhinoceros, 4);
   }
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(bonusHunt2ID, 80.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusHunt2ID, false, 1, 80.0, -1.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(bonusHunt2ID, false, 1, 80.0, -1.0, avoidHuntMeters);
   }

   // Bonus hunt 3.
   int bonusHunt3ID = rmObjectDefCreate("bonus hunt 3");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(bonusHunt3ID, cUnitTypeMonkey, xsRandInt(8, 11));
   }
   else
   {
      rmObjectDefAddItem(bonusHunt3ID, cUnitTypeBaboon, xsRandInt(8, 11));
   }
   rmObjectDefAddConstraint(bonusHunt3ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHunt3ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(bonusHunt3ID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(bonusHunt3ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHunt3ID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(bonusHunt3ID, 80.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusHunt3ID, false, 1, 80.0, -1.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(bonusHunt3ID, false, 1, 80.0, -1.0, avoidHuntMeters);
   }

   // Other map sizes hunt.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int numLargeMapHunt = 1 * getMapSizeBonusFactor();
      for(int i = 0; i < numLargeMapHunt; i++)
      {
         float largeMapHuntFloat = xsRandFloat(0.0, 1.0);
         int largeMapHuntID = rmObjectDefCreate("large map hunt" + i);
         if(largeMapHuntFloat < 1.0 / 4.0)
         {
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeGiraffe, xsRandInt(3, 7));
            if (xsRandBool(0.5) == true)
            {
               rmObjectDefAddItem(largeMapHuntID, cUnitTypeZebra, xsRandInt(2, 5));
            }
         }
         else if(largeMapHuntFloat < 2.0 / 4.0)
         {
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeRhinoceros, xsRandInt(1, 3));
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeGazelle, xsRandInt(2, 5));
         }
         else if(largeMapHuntFloat < 3.0 / 4.0)
         {
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeMonkey, xsRandInt(6, 11));
         }
         else
         {
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeGazelle, xsRandInt(3, 7));
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeZebra, xsRandInt(3, 6));
         }
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidEdge);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidAll);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidWater);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidTowerLOS);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidSettlementRange);
         addObjectDefPlayerLocConstraint(largeMapHuntID, 100.0);
         addObjectLocsPerPlayer(largeMapHuntID, false, 1, 100.0, -1.0, avoidHuntMeters);
      }
   }

   generateLocs("hunt locs");

   rmSetProgress(0.6);
   
   // Berries.
   float avoidBerriesMeters = 50.0;

   int berriesID = rmObjectDefCreate("berries");
   rmObjectDefAddItem(berriesID, cUnitTypeBerryBush, xsRandInt(5, 9), cBerryClusterRadius);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(berriesID, vDefaultBerriesAvoidAll);
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
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidWater);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidTowerLOS);
   addObjectDefPlayerLocConstraint(closeHerdID, 50.0);
   addObjectLocsPerPlayer(closeHerdID, false, xsRandInt(1, 2), 50.0, 70.0, avoidHerdMeters);

   int bonusHerdID = rmObjectDefCreate("bonus herd");
   rmObjectDefAddItem(bonusHerdID, cUnitTypeGoat, xsRandInt(1, 3));
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidWater);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidTowerLOS);
   addObjectDefPlayerLocConstraint(bonusHerdID, 70.0);
   addObjectLocsPerPlayer(bonusHerdID, false, 2 * getMapAreaSizeFactor(), 70.0, -1.0, avoidHerdMeters);

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

   // Forests.
   float avoidForestMeters = 30.0;

   int forestDefID = rmAreaDefCreate("forest");
   rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(60), rmTilesToAreaFraction(80));
   rmAreaDefSetForestType(forestDefID, cForestEgyptSavannah);
   rmAreaDefSetAvoidSelfDistance(forestDefID, avoidForestMeters);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidWater6);
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
   buildAreaDefInTeamAreas(forestDefID, 11 * getMapAreaSizeFactor());

   // Stragglers.
   placeStartingStragglers(cUnitTypeTreeSavannah);

   rmSetProgress(0.8);

   // Embellishment.
   // Gold areas.
   buildAreaUnderObjectDef(startingGoldID, cTerrainEgyptDirtRocks2, cTerrainEgyptDirtRocks1, 6.0);
   buildAreaUnderObjectDef(closeGoldID, cTerrainEgyptDirtRocks2, cTerrainEgyptDirtRocks1, 6.0);
   buildAreaUnderObjectDef(bonusGoldID, cTerrainEgyptDirtRocks2, cTerrainEgyptDirtRocks1, 6.0);

   // Berries areas.
   buildAreaUnderObjectDef(startingBerriesID, cTerrainEgyptSavannah2, cInvalidID, 10.0);
   buildAreaUnderObjectDef(berriesID, cTerrainEgyptSavannah2, cInvalidID, 10.0);

   rmSetProgress(0.9);

   // Random trees.
   int randomTreeID = rmObjectDefCreate("random tree");
   rmObjectDefAddItem(randomTreeID, cUnitTypeTreeSavannah, 1);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidWater);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidTree);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefPlaceAnywhere(randomTreeID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   // Rocks.
   int rockTinyID = rmObjectDefCreate("rock tiny");
   rmObjectDefAddItem(rockTinyID, cUnitTypeRockEgyptTiny, 1);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockTinyID, vDefaultAvoidWater4);
   rmObjectDefPlaceAnywhere(rockTinyID, 0, 50 * cNumberPlayers * getMapAreaSizeFactor());

   int rockSmallID = rmObjectDefCreate("rock small");
   rmObjectDefAddItem(rockSmallID, cUnitTypeRockEgyptSmall, 1);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockSmallID, vDefaultAvoidWater4);
   rmObjectDefPlaceAnywhere(rockSmallID, 0, 50 * cNumberPlayers * getMapAreaSizeFactor());

   // Plants.
   int plantForceOnGrass2 = rmCreateTerrainTypeMaxDistanceConstraint(cTerrainEgyptSavannah2, 0.0);
   int plantAvoidDirt2 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptDirt2, 1.0);
   int plantAvoidDirt3 = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptDirt3, 1.0);

   int plantGrassID = rmObjectDefCreate("plant grass");
   rmObjectDefAddItem(plantGrassID, cUnitTypePlantEgyptianGrass, 1);
   rmObjectDefAddConstraint(plantGrassID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantGrassID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefAddConstraint(plantGrassID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(plantGrassID, plantForceOnGrass2);
   rmObjectDefPlaceAnywhere(plantGrassID, 0, 50 * cNumberPlayers * getMapAreaSizeFactor());

   // int plantBushID = rmObjectDefCreate("plant bush");
   // rmObjectDefAddItem(plantBushID, cUnitTypePlantEgyptianBush, 1);
   // rmObjectDefAddConstraint(plantBushID, vDefaultEmbellishmentAvoidAll);
   // rmObjectDefAddConstraint(plantBushID, vDefaultEmbellishmentAvoidWater);
   // rmObjectDefAddConstraint(plantBushID, plantForceOnGrass2);
   // rmObjectDefPlaceAnywhere(plantBushID, 0, 50 * cNumberPlayers * getMapAreaSizeFactor());

   int plantShrubID = rmObjectDefCreate("plant shrub");
   rmObjectDefAddItem(plantShrubID, cUnitTypePlantEgyptianShrub, 1);
   rmObjectDefAddConstraint(plantShrubID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantShrubID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefAddConstraint(plantShrubID, plantForceOnGrass2);
   rmObjectDefPlaceAnywhere(plantShrubID, 0, 50 * cNumberPlayers * getMapAreaSizeFactor());

   int plantFernID = rmObjectDefCreate("plant fern");
   rmObjectDefAddItem(plantFernID, cUnitTypePlantEgyptianFern, 1);
   rmObjectDefAddConstraint(plantFernID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantFernID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefAddConstraint(plantFernID, plantForceOnGrass2);
   rmObjectDefPlaceAnywhere(plantFernID, 0, 50 * cNumberPlayers * getMapAreaSizeFactor());

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeVulture, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   rmSetProgress(1.0);
}
