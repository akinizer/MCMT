include "lib2/rm_core.xs";

void generate()
{
   rmSetProgress(0.0);

   // Define mixes.
   int baseMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.15, 1);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptGrass2, 1.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptGrass1, 1.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptGrassDirt1, 1.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptGrassDirt2, 1.0);

 // Set size.
   int playerTiles=20000;
   int cNumberNonGaiaPlayers = 10;
   if(cMapSizeCurrent == 1)
   {
      playerTiles = 30000;
   }
   int size=2.0*sqrt(cNumberNonGaiaPlayers*playerTiles/0.9);
   rmSetMapSize(size, size);
   rmInitializeWater(cWaterEgyptRiverNileShallow);

   // Player placement.
   rmSetTeamSpacingModifier(0.85);
   rmPlacePlayersOnCircle(0.35);

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCivFromCulture(cCultureEgyptian);

   // Lighting.
   rmSetLighting(cLightingSetRmNileShallows01);

   rmSetProgress(0.1);

   int islandClassID = rmClassCreate();
   int islandAvoidSelf = rmCreateClassDistanceConstraint(islandClassID, 10.0);

   // Island area def.
   int islandDefID = rmAreaDefCreate("island def");
   rmAreaDefSetMix(islandDefID, baseMixID);
   rmAreaDefSetHeight(islandDefID, 0.25);
   rmAreaDefSetHeightNoise(islandDefID, cNoiseFractalSum, 2.0, 0.075, 1, 0.5);
   rmAreaDefSetHeightNoiseBias(islandDefID, 1.0); // Only grow upwards, so we don't go below water height.
   rmAreaDefSetHeightNoiseEdgeFalloffDist(islandDefID, 5.0);
   rmAreaDefSetCoherence(islandDefID, 0.5);
   rmAreaDefAddHeightBlend(islandDefID, cBlendAll, cFilter5x5Gaussian, 2);

   rmAreaDefAddToClass(islandDefID, islandClassID);
   
   // Create player areas.
   float playerAreaSize = rmRadiusToAreaFraction(40.0);

   for(int i = 1; i <= cNumberPlayers; i++)
   {
      int p = vDefaultTeamPlayerOrder[i];

      int playerIslandID = rmAreaDefCreateArea(islandDefID, "player island " + p);
      rmAreaSetLocPlayer(playerIslandID, p);
      rmAreaSetSize(playerIslandID, playerAreaSize);
      rmAreaSetCoherence(playerIslandID, 0.0);
   }

   rmAreaBuildAll();

   rmSetProgress(0.2);
   
   // KotH.
   if (gameIsKotH() == true)
   {
      int islandKotHID = rmAreaCreate("koth island");
      rmAreaSetSize(islandKotHID, rmRadiusToAreaFraction(20.0));
      rmAreaSetLoc(islandKotHID, cCenterLoc);
      rmAreaSetMix(islandKotHID, baseMixID);
   
      rmAreaSetHeight(islandKotHID, 0.25);
      rmAreaSetHeightNoise(islandKotHID, cNoiseFractalSum, 2.0, 0.075, 1, 0.5);
      rmAreaSetHeightNoiseBias(islandKotHID, 1.0); // Only grow upwards, so we don't go below water height.
      rmAreaSetCoherence(islandKotHID, 0.5);
      rmAreaAddHeightBlend(islandKotHID, cBlendAll, cFilter5x5Gaussian, 2);

      rmAreaAddToClass(islandKotHID, islandClassID);
   
      rmAreaBuild(islandKotHID);
   }

   placeKotHObjects();

   // Settlements and towers.
   placeStartingTownCenters();

   // Starting towers.
   int startingTowerID = rmObjectDefCreate("starting tower");
   rmObjectDefAddItem(startingTowerID, cUnitTypeSentryTower, 1);
   addObjectLocsPerPlayer(startingTowerID, true, 4, cStartingTowerMinDist, cStartingTowerMaxDist, cStartingTowerAvoidanceMeters);
   generateLocs("starting tower locs");

   // Create small areas under most objects, using the radius below for size.
   float objectAreaSize = rmRadiusToAreaFraction(17.5 + (2.5 * getMapSizeBonusFactor())); // Be very careful when tweaking this.

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
      addObjectLocsPerPlayer(secondSettlementID, false, 1, 70.0, 90.0, cFarSettlementDist, cBiasAggressive | cBiasAllyOutside);
   }

   int bonusSettlementID = cInvalidID;

   // Other map sizes settlements.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      bonusSettlementID = rmObjectDefCreate("bonus settlement");
      rmObjectDefAddItem(bonusSettlementID, cUnitTypeSettlement, 1);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidEdge);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidCorner40);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidKotH);
      addObjectLocsPerPlayer(bonusSettlementID, false, 1 * getMapAreaSizeFactor(), 90.0, -1.0, 90.0);
   }

   // Generate the locs, but don't reset them or place settlements yet.
   generateLocs("settlement locs", true, false, false, false);

   // First, build the islands where we'll place the settlements.
   buildAreaDefUnderLocs(islandDefID, objectAreaSize);

   // Then, place and reset.
   applyGeneratedLocs();
   resetLocGen();

   // Build some random non-shallow areas, the rest is built under objects later on.
   int numBonusAreas = 2 * cNumberPlayers * getMapAreaSizeFactor();
   for(int i = 0; i < numBonusAreas; i++)
   {
      int bonusAreaID = rmAreaDefCreateArea(islandDefID, "bonus area " + i);
      rmAreaSetSize(bonusAreaID, objectAreaSize); 
      rmAreaAddConstraint(bonusAreaID, rmCreateTypeDistanceConstraint(cUnitTypeSettlement), 20.0);
      rmAreaAddOriginConstraint(bonusAreaID, islandAvoidSelf, 10.0);
      // rmAreaAddConstraint(bonusAreaID, islandAvoidSelf, 5.0);
   }

   rmAreaBuildAll();

   rmSetProgress(0.3);

   // Objects.
   // Starting objects.
   // Starting gold.
   int startingGoldID = rmObjectDefCreate("starting gold");
   rmObjectDefAddItem(startingGoldID, cUnitTypeMineGoldMedium, 1);
   rmObjectDefAddConstraint(startingGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingGoldID, vDefaultStartingGoldAvoidTower);
   rmObjectDefAddConstraint(startingGoldID, vDefaultForceStartingGoldNearTower);
   addObjectLocsPerPlayer(startingGoldID, false, 1, cStartingGoldMinDist, cStartingGoldMaxDist, cStartingObjectAvoidanceMeters);

   generateLocs("starting gold locs");

   // Starting hunt.
   int startingHuntID = rmObjectDefCreate("starting hunt");
   rmObjectDefAddItem(startingHuntID, cUnitTypeHippopotamus, xsRandInt(3, 4));
   rmObjectDefAddConstraint(startingHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHuntID, vDefaultForceInTowerLOS);
   addObjectLocsPerPlayer(startingHuntID, false, 1, cStartingHuntMinDist, cStartingHuntMaxDist, cStartingObjectAvoidanceMeters);

   // Berries.
   int startingBerriesID = rmObjectDefCreate("starting berries");
   rmObjectDefAddItem(startingBerriesID, cUnitTypeBerryBush, xsRandInt(7, 9), cBerryClusterRadius);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidAll);
   addObjectLocsPerPlayer(startingBerriesID, false, 1, cStartingBerriesMinDist, cStartingBerriesMaxDist, cStartingObjectAvoidanceMeters);
   
   // Chicken.
   int startingChickenID = rmObjectDefCreate("starting chicken");
   rmObjectDefAddItem(startingChickenID, cUnitTypeChicken, xsRandInt(7, 9));
   rmObjectDefAddConstraint(startingChickenID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidAll);
   addObjectLocsPerPlayer(startingChickenID, false, 1, cStartingChickenMinDist, cStartingChickenMaxDist, cStartingObjectAvoidanceMeters);

   // Herdables.
   int startingHerdID = rmObjectDefCreate("starting herd");
   rmObjectDefAddItem(startingHerdID, cUnitTypeGoat, xsRandInt(2, 3));
   rmObjectDefAddConstraint(startingHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidAll);
   addObjectLocsPerPlayer(startingHerdID, true, 1, cStartingHerdMinDist, cStartingHerdMaxDist);

   generateLocs("starting food locs");

   rmSetProgress(0.4);

   // Gold.
   float avoidGoldMeters = 50.0;

   // Medium gold.
   int closeGoldID = rmObjectDefCreate("close gold");
   rmObjectDefAddItem(closeGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeGoldID, 55.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeGoldID, false, 2, 50.0, 70.0, avoidGoldMeters, cBiasForward);
   }
   else
   {
      addObjectLocsPerPlayer(closeGoldID, false, 2, 50.0, 70.0, avoidGoldMeters);
   }

   // Bonus gold.
   int bonusGoldID = rmObjectDefCreate("bonus gold");
   rmObjectDefAddItem(bonusGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(bonusGoldID, 70.0);

   if(gameIs1v1() == true)
   {
      addObjectLocsPerPlayer(bonusGoldID, false, xsRandInt(2, 3) * getMapAreaSizeFactor(), 70.0, -1.0, avoidGoldMeters);
   }
   else
   {
      addObjectLocsPerPlayer(bonusGoldID, false, xsRandInt(2, 3) * getMapAreaSizeFactor(), 70.0, -1.0, avoidGoldMeters);
   }

   generateLocs("gold locs");

   // Areas.
   buildAreaDefUnderObjectDef(closeGoldID, islandDefID, objectAreaSize);
   buildAreaDefUnderObjectDef(bonusGoldID, islandDefID, objectAreaSize);

   rmSetProgress(0.5);

   // Hunt.
   float avoidHuntMeters = 50.0;

   // Close hunt 1.
   int closeHunt1ID = rmObjectDefCreate("close hunt 1");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(closeHunt1ID, cUnitTypeCrownedCrane, xsRandInt(8, 10));
   }
   else
   {
      rmObjectDefAddItem(closeHunt1ID, cUnitTypeGazelle, xsRandInt(8, 10));
   }
   rmObjectDefAddConstraint(closeHunt1ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHunt1ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHunt1ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHunt1ID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeHunt1ID, 60.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeHunt1ID, false, 1, 60.0, 80.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(closeHunt1ID, false, 1, 60.0, 80.0, avoidHuntMeters);
   }

   // Close hunt 2.
   int closeHunt2ID = rmObjectDefCreate("close hunt 2");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(closeHunt2ID, cUnitTypeHippopotamus, xsRandInt(4, 6));
   }
   else
   {
      rmObjectDefAddItem(closeHunt2ID, cUnitTypeAurochs, xsRandInt(4, 6));
   }
   rmObjectDefAddConstraint(closeHunt2ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHunt2ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHunt2ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHunt2ID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeHunt2ID, 60.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeHunt2ID, false, 1, 60.0, 80.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(closeHunt2ID, false, 1, 60.0, 80.0, avoidHuntMeters);
   }

   // Bonus hunt 1.
   int bonusHunt1ID = rmObjectDefCreate("bonus hunt 1");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(bonusHunt1ID, cUnitTypeGazelle, xsRandInt(8, 10));
   }
   else
   {
      rmObjectDefAddItem(bonusHunt1ID, cUnitTypeCrownedCrane, xsRandInt(8, 10));
   }
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultFoodAvoidAll);
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
   int bonusHunt2ID = rmObjectDefCreate("bonus hunt 2");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(bonusHunt2ID, cUnitTypeHippopotamus, xsRandInt(4, 6));
   }
   else
   {
      rmObjectDefAddItem(bonusHunt2ID, cUnitTypeAurochs, xsRandInt(4, 6));
   }
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(bonusHunt1ID, 80.0);
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
      rmObjectDefAddItem(bonusHunt3ID, cUnitTypeCrownedCrane, xsRandInt(8, 10));
   }
   else
   {
      rmObjectDefAddItem(bonusHunt3ID, cUnitTypeHippopotamus, xsRandInt(4, 6));
   }
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(bonusHunt1ID, 80.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusHunt3ID, false, 1, 80.0, -1.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(bonusHunt3ID, false, 1, 80.0, -1.0, avoidHuntMeters);
   }

   generateLocs("hunt locs");

   // Areas.
   buildAreaDefUnderObjectDef(closeHunt1ID, islandDefID, objectAreaSize);
   buildAreaDefUnderObjectDef(closeHunt2ID, islandDefID, objectAreaSize);
   buildAreaDefUnderObjectDef(bonusHunt3ID, islandDefID, objectAreaSize);
   buildAreaDefUnderObjectDef(bonusHunt1ID, islandDefID, objectAreaSize);
   buildAreaDefUnderObjectDef(bonusHunt2ID, islandDefID, objectAreaSize);

   // Other map sizes hunt.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int largeMapHuntID = rmObjectDefCreate("large map hunt");
      if(xsRandBool(0.5) == true)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeZebra, xsRandInt(6, 11));
      }
      else
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeElephant, xsRandInt(1, 3));
      }

      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidSettlementRange);
      addObjectDefPlayerLocConstraint(largeMapHuntID, 100.0);
      addObjectLocsPerPlayer(largeMapHuntID, false, 2 * getMapAreaSizeFactor(), 100.0, -1.0, avoidHuntMeters);
   
      generateLocs("large map hunt locs");
      
      buildAreaDefUnderObjectDef(largeMapHuntID, islandDefID, objectAreaSize);
   }

   rmSetProgress(0.5);

   // Berries.
   float avoidBerriesMeters = 50.0;

   int farBerriesID = rmObjectDefCreate("far berries");
   rmObjectDefAddItem(farBerriesID, cUnitTypeBerryBush, xsRandInt(7, 10), cBerryClusterRadius);
   rmObjectDefAddConstraint(farBerriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(farBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(farBerriesID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(farBerriesID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(farBerriesID, 70.0);
   addObjectLocsPerPlayer(farBerriesID, false, 1, 70.0, 100.0, avoidBerriesMeters);

   int bonusBerriesID = rmObjectDefCreate("bonus berries");
   rmObjectDefAddItem(bonusBerriesID, cUnitTypeBerryBush, xsRandInt(7, 10), cBerryClusterRadius);
   rmObjectDefAddConstraint(bonusBerriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(bonusBerriesID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusBerriesID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(bonusBerriesID, 80.0);
   addObjectLocsPerPlayer(bonusBerriesID, false, 1 * getMapSizeBonusFactor(), 80.0, -1.0, avoidBerriesMeters);

   generateLocs("berries locs");

   // Areas.
   buildAreaDefUnderObjectDef(farBerriesID, islandDefID, objectAreaSize);
   buildAreaDefUnderObjectDef(bonusBerriesID, islandDefID, objectAreaSize);

   // Herdables.
   float avoidHerdMeters = 50.0;

   int closeHerdID = rmObjectDefCreate("close herd");
   rmObjectDefAddItem(closeHerdID, cUnitTypeGoat, 2);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidTowerLOS);
   addObjectLocsPerPlayer(closeHerdID, false, 1, 50.0, 70.0, avoidHerdMeters);

   int bonusHerdID = rmObjectDefCreate("bonus herd");
   rmObjectDefAddItem(bonusHerdID, cUnitTypeGoat, 2);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidTowerLOS);
   addObjectLocsPerPlayer(bonusHerdID, false, 2 * getMapAreaSizeFactor(), 70.0, -1.0, avoidHerdMeters);

   generateLocs("herd locs");

   // Predators.
   float avoidPredatorMeters = 50.0;

   int predatorID = rmObjectDefCreate("predator");
   rmObjectDefAddItem(predatorID, cUnitTypeCrocodile, 2);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidLand);
   addObjectDefPlayerLocConstraint(predatorID, 80.0);
   addObjectLocsPerPlayer(predatorID, false, 2 * getMapAreaSizeFactor(), 80.0, -1.0, avoidPredatorMeters);

   generateLocs("predator locs");

   // Relics.
   float avoidRelicMeters = 80.0;
  
   int relicID = rmObjectDefCreate("relic");
   rmObjectDefAddItem(relicID, cUnitTypeRelic, 1);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidAll);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(relicID, 80.0);
   addObjectLocsPerPlayer(relicID, false, 2 * getMapAreaSizeFactor(), 80.0, -1.0, avoidRelicMeters);

   generateLocs("relic locs");

   rmSetProgress(0.6);

   // Resource beautification.
   // Gold areas.
   buildAreaUnderObjectDef(startingGoldID, cTerrainEgyptGrassRocks2, cTerrainEgyptGrassRocks1, 6.0);
   buildAreaUnderObjectDef(closeGoldID, cTerrainEgyptGrassRocks2, cTerrainEgyptGrassRocks1, 6.0);
   buildAreaUnderObjectDef(bonusGoldID, cTerrainEgyptGrassRocks2, cTerrainEgyptGrassRocks1, 6.0);

   // Berries areas.
   buildAreaUnderObjectDef(startingBerriesID, cTerrainEgyptGrass1, cTerrainEgyptGrassDirt1, 10.0);
   buildAreaUnderObjectDef(farBerriesID, cTerrainEgyptGrass1, cTerrainEgyptGrassDirt1, 10.0);
   buildAreaUnderObjectDef(bonusBerriesID, cTerrainEgyptGrass1, cTerrainEgyptGrassDirt1, 10.0);

   rmSetProgress(0.7);

   // Forests.
   float avoidForestMeters = 20.0;

   int forestDefID = rmAreaDefCreate("forest");
   rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(60), rmTilesToAreaFraction(80));
   rmAreaDefSetForestType(forestDefID, cForestEgyptNile);
   rmAreaDefSetAvoidSelfDistance(forestDefID, avoidForestMeters, 10.0);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidWater4);
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
   buildAreaDefInTeamAreas(forestDefID, 20 * getMapAreaSizeFactor());

   // Stragglers.
   placeStartingStragglers(cUnitTypeTreePalm);

   rmSetProgress(0.8);

   // Beautification.
   // Random trees.
   int randomTreeID = rmObjectDefCreate("random tree");
   rmObjectDefAddItem(randomTreeID, cUnitTypeTreePalm, 1);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidWater);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidTree);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefPlaceAnywhere(randomTreeID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   // Plants.
   int plantBushID = rmObjectDefCreate("plant bush");
   rmObjectDefAddItem(plantBushID, cUnitTypePlantEgyptianBush, 1);
   rmObjectDefAddConstraint(plantBushID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantBushID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefPlaceAnywhere(plantBushID, 0, 40 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantShrubID = rmObjectDefCreate("plant shrub");
   rmObjectDefAddItem(plantShrubID, cUnitTypePlantEgyptianShrub, 1);
   rmObjectDefAddConstraint(plantShrubID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantShrubID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefPlaceAnywhere(plantShrubID, 0, 40 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantFernID = rmObjectDefCreate("plant fern");
   rmObjectDefAddItemRange(plantFernID, cUnitTypePlantEgyptianFern, 1, 3, 0.0, 4.0);
   rmObjectDefAddConstraint(plantFernID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantFernID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefPlaceAnywhere(plantFernID, 0, 20 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantWeedsID = rmObjectDefCreate("plant weeds");
   rmObjectDefAddItemRange(plantWeedsID, cUnitTypePlantEgyptianWeeds, 1, 3, 0.0, 4.0);
   rmObjectDefAddConstraint(plantWeedsID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantWeedsID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefPlaceAnywhere(plantWeedsID, 0, 20 * cNumberPlayers * getMapAreaSizeFactor());

   // Rocks.
   int rockTinyID = rmObjectDefCreate("rock tiny");
   rmObjectDefAddItemRange(rockTinyID, cUnitTypeRockEgyptTiny, 1, 3, 0.0, 4.0);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefPlaceAnywhere(rockTinyID, 0, 30 * cNumberPlayers * getMapAreaSizeFactor());

   int rockSmallID = rmObjectDefCreate("rock small");
   rmObjectDefAddItemRange(rockSmallID, cUnitTypeRockEgyptSmall, 1, 2, 0.0, 4.0);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefPlaceAnywhere(rockSmallID, 0, 30 * cNumberPlayers * getMapAreaSizeFactor());

   rmSetProgress(0.9);

   // Water stuff.
   int forceEmbellishmentNearLand = rmCreateWaterMaxDistanceConstraint(false, 6.0);

   int waterReedsNearLandID = rmObjectDefCreate("water reeds near land");
   rmObjectDefAddItemRange(waterReedsNearLandID, cUnitTypeWaterReeds, 1, 4);
   rmObjectDefAddConstraint(waterReedsNearLandID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(waterReedsNearLandID, vDefaultAvoidLand4, cObjectConstraintBufferNone);
   rmObjectDefAddConstraint(waterReedsNearLandID, forceEmbellishmentNearLand, cObjectConstraintBufferNone);
   rmObjectDefPlaceAnywhere(waterReedsNearLandID, 0, 40 * cNumberPlayers * getMapAreaSizeFactor());

   int papyrusNearLandID = rmObjectDefCreate("papyrus near land");
   rmObjectDefAddItemRange(papyrusNearLandID, cUnitTypePapyrus, 3, 5);
   rmObjectDefAddConstraint(papyrusNearLandID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(papyrusNearLandID, vDefaultAvoidLand4, cObjectConstraintBufferNone);
   rmObjectDefAddConstraint(papyrusNearLandID, forceEmbellishmentNearLand, cObjectConstraintBufferNone);
   rmObjectDefPlaceAnywhere(papyrusNearLandID, 0, 40 * cNumberPlayers);

   int waterPlantNearLandID = rmObjectDefCreate("water plant near land");
   rmObjectDefAddItemRange(waterPlantNearLandID, cUnitTypeWaterPlant, 1, 2);
   rmObjectDefAddConstraint(waterPlantNearLandID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(waterPlantNearLandID, vDefaultAvoidLand4, cObjectConstraintBufferNone);
   rmObjectDefAddConstraint(waterPlantNearLandID, forceEmbellishmentNearLand, cObjectConstraintBufferNone);
   rmObjectDefPlaceAnywhere(waterPlantNearLandID, 0, 20 * cNumberPlayers * getMapAreaSizeFactor());

   int waterReedsID = rmObjectDefCreate("water reeds");
   rmObjectDefAddItemRange(waterReedsID, cUnitTypeWaterReeds, 1, 4, 0.0, 5.0);
   rmObjectDefAddConstraint(waterReedsID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(waterReedsID, vDefaultAvoidLand4);
   rmObjectDefPlaceAnywhere(waterReedsID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   int papyrusID = rmObjectDefCreate("papyrus");
   rmObjectDefAddItemRange(papyrusID, cUnitTypePapyrus, 1, 4, 0.0, 5.0);
   rmObjectDefAddConstraint(papyrusID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(papyrusID, vDefaultAvoidLand4);
   rmObjectDefPlaceAnywhere(papyrusID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   int waterPlantID = rmObjectDefCreate("water plant");
   rmObjectDefAddItemRange(waterPlantID, cUnitTypeWaterPlant, 1, 4, 0.0, 5.0);
   rmObjectDefAddConstraint(waterPlantID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(waterPlantID, vDefaultAvoidLand4);
   rmObjectDefPlaceAnywhere(waterPlantID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeVulture, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   rmSetProgress(1.0);
}
