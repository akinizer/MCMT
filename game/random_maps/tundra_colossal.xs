include "lib2/rm_core.xs";

void generate()
{
   rmSetProgress(0.0);

   // Define mixes.
   int baseMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.1, 5, 0.75);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainTundraGrass2, 2.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainTundraGrass1, 2.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainTundraSnowGrass3, 2.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainTundraSnowGrass2, 2.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainTundraSnowGrass1, 2.0);

   // Water overrides.
   rmWaterTypeAddBeachLayer(cWaterTundraLake, cTerrainTundraShore1, 2.0, 1.0);

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
   rmSetNatureCivFromCulture(cCultureNorse);

   // KotH.
   placeKotHObjects();

   // Lighting.
   rmSetLighting(cLightingSetRmTundra01);

   rmSetProgress(0.1);

   // Global elevation.
   rmAddGlobalHeightNoise(cNoiseFractalSum, 5.0, 0.05, 2, 0.5);

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
   int pondClassID = rmClassCreate();
   float pondSize = rmTilesToAreaFraction(300 * getMapAreaSizeFactor());
   int pondAvoidPond = rmCreateClassDistanceConstraint(pondClassID, 50.0);
   int pondAvoidEdge = createSymmetricBoxConstraint(rmXMetersToFraction(16.0), rmZMetersToFraction(16.0));
   int pondAvoidSettlement = rmCreateTypeDistanceConstraint(cUnitTypeSettlement, 30.0);
   int pondAvoidStartingLoc = createPlayerLocDistanceConstraint(60.0);

   int pondID = rmAreaDefCreate("pond");
   rmAreaDefSetSize(pondID, pondSize);
   rmAreaDefSetWaterType(pondID, cWaterTundraLake);
   rmAreaDefSetWaterHeight(pondID, -3.0, cWaterHeightTypeMax);
   // rmAreaDefSetWaterHeightBlend(pondID, cFilter5x5Gaussian, 16.0, 10);

   // rmAreaDefSetBlobs(pondID, 3, 4);
   // rmAreaDefSetBlobDistance(pondID, 10.0, 10.0);

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
   int startingHunt1ID = rmObjectDefCreate("starting hunt 1");
   rmObjectDefAddItem(startingHunt1ID, cUnitTypeCaribou, 8);
   rmObjectDefAddConstraint(startingHunt1ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHunt1ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHunt1ID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(startingHunt1ID, vDefaultForceInTowerLOS);
   addObjectLocsPerPlayer(startingHunt1ID, false, 1, cStartingHuntMinDist, cStartingHuntMaxDist, cStartingObjectAvoidanceMeters);

   // Second starting hunt (for now always in starting LOS).
   float startingHuntFloat = xsRandFloat(0.0, 1.0);
   int startingHunt2ID = rmObjectDefCreate("starting hunt 2");
   if(startingHuntFloat < 1.0 / 3.0)
   {
      rmObjectDefAddItem(startingHunt2ID, cUnitTypeElk, 4);
      rmObjectDefAddItem(startingHunt2ID, cUnitTypeCaribou, 4);
   }
   else if(startingHuntFloat < 2.0 / 3.0)
   {
      rmObjectDefAddItem(startingHunt2ID, cUnitTypeElk, 8);
   }
   else
   {
      rmObjectDefAddItem(startingHunt2ID, cUnitTypeAurochs, 3);
   }
   rmObjectDefAddConstraint(startingHunt2ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHunt2ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHunt2ID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(startingHunt2ID, vDefaultForceInTowerLOS);
   addObjectLocsPerPlayer(startingHunt2ID, false, 1, cStartingHuntMinDist, cStartingHuntMaxDist, cStartingObjectAvoidanceMeters);

   // Berries.
   int startingBerriesID = rmObjectDefCreate("starting berries");
   rmObjectDefAddItem(startingBerriesID, cUnitTypeBerryBush, xsRandInt(6, 9), cBerryClusterRadius);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidWater);
   addObjectLocsPerPlayer(startingBerriesID, false, 1, cStartingBerriesMinDist, cStartingBerriesMaxDist, cStartingObjectAvoidanceMeters);

   // Herdables.
   int startingHerdID = rmObjectDefCreate("starting herd");
   rmObjectDefAddItem(startingHerdID, cUnitTypeGoat, xsRandInt(4, 8));
   rmObjectDefAddConstraint(startingHerdID, vDefaultAvoidAll);
   rmObjectDefAddConstraint(startingHerdID, vDefaultAvoidEdge);
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
   addObjectDefPlayerLocConstraint(bonusGoldID, 80.0);
   addObjectLocsPerPlayer(bonusGoldID, false, xsRandInt(2, 3) * getMapAreaSizeFactor(), 80.0, -1.0, avoidGoldMeters);

   generateLocs("gold locs");

   rmSetProgress(0.5);

   // Hunt.
   float avoidHuntMeters = 50.0;

   // This map has so much hunt that we don't have to rely on similar locations.
   // Close hunt 1.
   int closeHunt1ID = rmObjectDefCreate("close hunt 1");
   rmObjectDefAddItem(closeHunt1ID, cUnitTypeCaribou, xsRandInt(6, 9));
   rmObjectDefAddConstraint(closeHunt1ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHunt1ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHunt1ID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(closeHunt1ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHunt1ID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeHunt1ID, 60.0);
   addObjectLocsPerPlayer(closeHunt1ID, false, 1, 60.0, 80.0, avoidHuntMeters);

   // Close hunt 2.
   int closeHunt2ID = rmObjectDefCreate("close hunt 2");
   rmObjectDefAddItem(closeHunt2ID, cUnitTypeElk, xsRandInt(6, 10));
   rmObjectDefAddConstraint(closeHunt2ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHunt2ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHunt2ID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(closeHunt2ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHunt2ID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeHunt2ID, 60.0);
   addObjectLocsPerPlayer(closeHunt2ID, false, 1, 60.0, 80.0, avoidHuntMeters);

   // Bonus hunt 1.
   int bonusHunt1ID = rmObjectDefCreate("bonus hunt 1");
   rmObjectDefAddItem(bonusHunt1ID, cUnitTypeAurochs, xsRandInt(3, 4));
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(bonusHunt1ID, 80.0);
   addObjectLocsPerPlayer(bonusHunt1ID, false, 1, 80.0, -1.0, avoidHuntMeters);

   // Bonus hunt 2.
   float bonusHunt2Float = xsRandFloat(0.0, 1.0);
   int bonusHunt2ID = rmObjectDefCreate("bonus hunt 2");
   if(bonusHunt2Float < 0.1)
   {
      if(xsRandBool(0.5) == true)
      {
         rmObjectDefAddItem(bonusHunt2ID, cUnitTypeCaribou, xsRandInt(3, 5));
      }
      else
      {
         rmObjectDefAddItem(bonusHunt2ID, cUnitTypeElk, xsRandInt(3, 5));
      }
      rmObjectDefAddItem(bonusHunt2ID, cUnitTypeAurochs, xsRandInt(1, 2));
   }
   else if(bonusHunt2Float < 0.5)
   {
      rmObjectDefAddItem(bonusHunt2ID, cUnitTypeElk, xsRandInt(6, 9));
   }
   else if(bonusHunt2Float < 0.9)
   {
      rmObjectDefAddItem(bonusHunt2ID, cUnitTypeCaribou, xsRandInt(6, 9));
   }
   else
   {
      rmObjectDefAddItem(bonusHunt2ID, cUnitTypeAurochs, xsRandInt(2, 3));
   }
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(bonusHunt2ID, 80.0);
   addObjectLocsPerPlayer(bonusHunt2ID, false, 1, 80.0, -1.0, avoidHuntMeters);

   // Bonus hunt 3.
   int bonusHunt3ID = rmObjectDefCreate("bonus hunt 3");
   rmObjectDefAddItem(bonusHunt3ID, cUnitTypeAurochs, xsRandInt(2, 4));
   rmObjectDefAddConstraint(bonusHunt3ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHunt3ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(bonusHunt3ID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(bonusHunt3ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHunt3ID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(bonusHunt3ID, 80.0);
   addObjectLocsPerPlayer(bonusHunt3ID, false, 1, 80.0, -1.0, avoidHuntMeters);

   generateLocs("hunt locs");

   // Other map sizes hunt.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int numLargeMapHunt = 3 * getMapSizeBonusFactor();
      for(int i = 0; i < numLargeMapHunt; i++)
      {
         float largeMapHuntFloat = xsRandFloat(0.0, 1.0);
         int largeMapHuntID = rmObjectDefCreate("large map hunt" + i);
         if(largeMapHuntFloat < 1.0 / 3.0)
         {
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeAurochs, xsRandInt(2, 4));
            if (xsRandBool(0.5) == true)
            {
               rmObjectDefAddItem(largeMapHuntID, cUnitTypeCaribou, xsRandInt(1, 4));
            }
         }
         else if(largeMapHuntFloat < 2.0 / 3.0)
         {
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeElk, xsRandInt(3, 8));
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeCaribou, xsRandInt(2, 7));
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
         addObjectDefPlayerLocConstraint(largeMapHuntID, 80.0);
         addObjectLocsPerPlayer(largeMapHuntID, false, 1, 100.0, -1.0, avoidHuntMeters);
      }
   }

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

   // Predators.
   float avoidPredatorMeters = 50.0;

   int predatorID = rmObjectDefCreate("predator");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(predatorID, cUnitTypePolarBear, xsRandInt(1, 2));
   }
   else
   {
      rmObjectDefAddItem(predatorID, cUnitTypeArcticWolf, xsRandInt(1, 3));
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

   // Stragglers.
   placeStartingStragglers(cUnitTypeTreeTundra);

   rmSetProgress(0.7);

   // Forests.
   float avoidForestMeters = 30.0;

   int forestDefID = rmAreaDefCreate("forest");
   rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(50), rmTilesToAreaFraction(70));
   rmAreaDefSetForestType(forestDefID, cForestTundra);
   rmAreaDefSetAvoidSelfDistance(forestDefID, avoidForestMeters);
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
   buildAreaDefInTeamAreas(forestDefID, 8 * getMapAreaSizeFactor());

   // Stragglers.
   placeStartingStragglers(cUnitTypeTreeTundra);

   rmSetProgress(0.8);

   // Embellishment.
   // Gold areas.
   buildAreaUnderObjectDef(startingGoldID, cTerrainTundraSnowGrassRocks2, cTerrainTundraSnowGrassRocks1, 6.0);
   buildAreaUnderObjectDef(closeGoldID, cTerrainTundraSnowGrassRocks2, cTerrainTundraSnowGrassRocks1, 6.0);
   buildAreaUnderObjectDef(bonusGoldID, cTerrainTundraSnowGrassRocks2, cTerrainTundraSnowGrassRocks1, 6.0);

   // Berries areas.
   buildAreaUnderObjectDef(startingBerriesID, cTerrainTundraGrass1, cTerrainTundraSnowGrass3, 12.0);
   buildAreaUnderObjectDef(berriesID, cTerrainTundraGrass1, cTerrainTundraSnowGrass3, 12.0);

   rmSetProgress(0.9);

   // Random trees.
   int randomTreeID = rmObjectDefCreate("random tree");
   rmObjectDefAddItem(randomTreeID, cUnitTypeTreeTundra, 1);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidImpassableLand);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidTree);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefPlaceAnywhere(randomTreeID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   // Rocks.
   int rockTinyID = rmObjectDefCreate("rock tiny");
   rmObjectDefAddItem(rockTinyID, cUnitTypeRockNorseTiny, 1);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockTinyID, vDefaultAvoidWater4);
   rmObjectDefPlaceAnywhere(rockTinyID, 0, 50 * cNumberPlayers * getMapAreaSizeFactor());

   int rockSmallID = rmObjectDefCreate("rock small");
   rmObjectDefAddItem(rockSmallID, cUnitTypeRockNorseSmall, 1);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockSmallID, vDefaultAvoidWater4);
   rmObjectDefPlaceAnywhere(rockSmallID, 0, 50 * cNumberPlayers * getMapAreaSizeFactor());

   // Plants.
   int avoidSnowGrass2 = rmCreateTerrainTypeDistanceConstraint(cTerrainTundraSnowGrass2, 1.0);
   int avoidSnowGrass1 = rmCreateTerrainTypeDistanceConstraint(cTerrainTundraSnowGrass1, 1.0);

   int grassID = rmObjectDefCreate("grass");
   rmObjectDefAddItem(grassID, cUnitTypePlantTundraGrass, 1);
   rmObjectDefAddConstraint(grassID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(grassID, vDefaultAvoidWater8);
   rmObjectDefAddConstraint(grassID, avoidSnowGrass2);
   rmObjectDefAddConstraint(grassID, avoidSnowGrass1);
   rmObjectDefPlaceAnywhere(grassID, 0, 45 * cNumberPlayers * getMapAreaSizeFactor());

   int weedsID = rmObjectDefCreate("weeds");
   rmObjectDefAddItem(weedsID, cUnitTypePlantTundraWeeds, 1);
   rmObjectDefAddConstraint(weedsID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(weedsID, vDefaultAvoidWater8);
   rmObjectDefAddConstraint(weedsID, avoidSnowGrass2);
   rmObjectDefAddConstraint(weedsID, avoidSnowGrass1);
   rmObjectDefPlaceAnywhere(weedsID, 0, 40 * cNumberPlayers * getMapAreaSizeFactor());
   
   int shrubID = rmObjectDefCreate("shrub");
   rmObjectDefAddItem(shrubID, cUnitTypePlantTundraShrub, 1);
   rmObjectDefAddConstraint(shrubID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(shrubID, vDefaultAvoidWater8);
   rmObjectDefAddConstraint(shrubID, avoidSnowGrass2);
   rmObjectDefAddConstraint(shrubID, avoidSnowGrass1);
   rmObjectDefPlaceAnywhere(shrubID, 0, 30 * cNumberPlayers * getMapAreaSizeFactor());
   
   int bushID = rmObjectDefCreate("bush");
   rmObjectDefAddItem(bushID, cUnitTypePlantTundraBush, 1);
   rmObjectDefAddConstraint(bushID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(bushID, vDefaultAvoidWater8);
   rmObjectDefAddConstraint(bushID, avoidSnowGrass2);
   rmObjectDefAddConstraint(bushID, avoidSnowGrass1);
   rmObjectDefPlaceAnywhere(bushID, 0, 30 * cNumberPlayers * getMapAreaSizeFactor());

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeHawk, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   // Light snowfall.
   // TODO Syscall or library function.
   rmTriggerAddScriptLine("rule _snow");
   rmTriggerAddScriptLine("active");
   rmTriggerAddScriptLine("{");
   rmTriggerAddScriptLine("   trRenderSnow(1.0);");
   rmTriggerAddScriptLine("   xsDisableSelf();");
   rmTriggerAddScriptLine("}");

   rmSetProgress(1.0);
}
