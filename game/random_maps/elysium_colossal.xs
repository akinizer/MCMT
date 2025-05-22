include "lib2/rm_core.xs";

void generate()
{
   rmSetProgress(0.0);

   // Define mixes.
   int baseMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.15, 3, 0.5);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainAtlanteanGrass2, 2.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainAtlanteanGrass1, 1.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainAtlanteanGrassDirt1, 1.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainAtlanteanGrassDirt2, 2.0);

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

   rmSetTeamSpacingModifier(0.875);
   rmPlacePlayersOnCircle(0.375);

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCivFromCulture(cCultureGreek);

   // KotH.
   placeKotHObjects();

   // Lighting.
   rmSetLighting(cLightingSetRmElysium01);

   // Global elevation.
   rmAddGlobalHeightNoise(cNoiseFractalSum, 3.0, 0.075, 1, 0.5);

   rmSetProgress(0.1);

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
      addObjectLocsPerPlayer(bonusSettlementID, false, 1 * getMapAreaSizeFactor(), 90.0, -1.0, 100.0);
   }

   generateLocs("settlement locs");

   rmSetProgress(0.2);

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
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeGazelle, xsRandInt(8, 9));
   }
   else
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeDeer, xsRandInt(8, 9));
   }
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
   rmObjectDefAddItem(startingHerdID, cUnitTypePig, xsRandInt(2, 4));
   rmObjectDefAddConstraint(startingHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidAll);
   addObjectLocsPerPlayer(startingHerdID, true, 1, cStartingHerdMinDist, cStartingHerdMaxDist);

   generateLocs("starting food locs");

   rmSetProgress(0.3);

   // Gold.
   // These will be surrounded by forest groups afterwards, so more avoidance than usual.
   int goldAvoidSettlement = rmCreateTypeDistanceConstraint(cUnitTypeAbstractSettlement, 30.0);

   float avoidGoldMeters = 60.0;

   // Medium gold.
   int closeGoldID = rmObjectDefCreate("close gold");
   rmObjectDefAddItem(closeGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeGoldID, goldAvoidSettlement);
   addObjectDefPlayerLocConstraint(closeGoldID, 55.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeGoldID, false, 1, 55.0, 65.0, avoidGoldMeters, cBiasForward);
   }
   else
   {
      addObjectLocsPerPlayer(closeGoldID, false, 1, 55.0, 65.0, avoidGoldMeters);
   }

   // Bonus gold.
   int bonusGoldID = rmObjectDefCreate("bonus gold");
   rmObjectDefAddItem(bonusGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusGoldID, goldAvoidSettlement);
   addObjectDefPlayerLocConstraint(bonusGoldID, 75.0);

   // For now, these are the same.
   if(gameIs1v1() == true)
   {
      addObjectLocsPerPlayer(bonusGoldID, false, 3 * getMapSizeBonusFactor(), 75.0, -1.0, avoidGoldMeters);
   }
   else
   {
      int numGold = (cNumberPlayers < 9) ? 3 : 2;
      addObjectLocsPerPlayer(bonusGoldID, false, numGold * getMapSizeBonusFactor(), 75.0, -1.0, avoidGoldMeters);
   }

   // Don't place and reset yet.
   generateLocs("gold locs", true, false, false, false);

   rmSetProgress(0.4);

   // Create ponds under the gold mines.
   float pondAreaSize = rmRadiusToAreaFraction(20.0);
   int pondClassID = rmClassCreate();

   // Forest constraints.
   int pondForestClassID = rmClassCreate();
   int forceForestNearPond = rmCreateClassMaxDistanceConstraint(pondClassID, 5.0);
   int forestAvoidSelf = rmCreateClassDistanceConstraint(pondForestClassID, 15.0);
   int forestAvoidWater = rmCreateWaterDistanceConstraint(true, 3.0);

   for(int i = 0; i < rmLocGenGetNumberLocs(); i++)
   {
      vector loc = rmLocGenGetLoc(i);
   
      int pondID = rmAreaCreate("pond " + i);
      rmAreaSetSize(pondID, pondAreaSize);
      rmAreaSetLoc(pondID, loc);

      rmAreaSetWaterType(pondID, cWaterAtlanteanShallow);
      
      rmAreaSetBlobs(pondID, 3, 4);
      rmAreaSetBlobDistance(pondID, 1.0, 5.0);
      rmAreaSetCoherence(pondID, 0.75);
      
      rmAreaAddConstraint(pondID, vDefaultAvoidAll8);
      rmAreaAddConstraint(pondID, vDefaultAvoidSettlementWithFarm);

      rmAreaAddToClass(pondID, pondClassID);
   
      rmAreaBuild(pondID);

      // Tiny elevation for the gold.
      int pondElevID = rmAreaCreate("pond elev " + i);
      rmAreaSetSize(pondElevID, 0.05 * pondAreaSize);
      rmAreaSetLoc(pondElevID, loc);
      
      rmAreaSetTerrainType(pondElevID, cTerrainAtlanteanDirtRocks1);

      rmAreaSetHeightRelative(pondElevID, 0.5);
      rmAreaAddHeightBlend(pondElevID, cBlendAll, cFilter3x3Gaussian, 1);
   
      rmAreaBuild(pondElevID);

      // Build a larger fake area where the forest origins can be.
      int forestFakeAreaID = rmAreaCreate("forest fake area " + i);
      rmAreaSetLoc(forestFakeAreaID, loc);
      rmAreaSetSize(forestFakeAreaID, 1.0);

      rmAreaAddConstraint(forestFakeAreaID, rmCreateAreaMaxDistanceConstraint(pondID, 20.0));

      rmAreaBuild(forestFakeAreaID);

      // Build some forests around it.
      int numForests = 4;

      for(int j = 0; j < numForests; j++)
      {
         int forestID = rmAreaCreate("pond forest " + i + " " + j);
         rmAreaSetParent(forestID, forestFakeAreaID);

         rmAreaSetForestType(forestID, cForestAtlanteanLush);
         rmAreaSetSize(forestID, rmTilesToAreaFraction(xsRandInt(40, 50)));

         // Still force the origin near the pond.
         rmAreaAddConstraint(forestID, forestAvoidSelf);
         rmAreaAddConstraint(forestID, forestAvoidWater);
         rmAreaAddConstraint(forestID, vDefaultAvoidAll8);
         rmAreaAddConstraint(forestID, vDefaultAvoidSettlementWithFarm);
         rmAreaAddOriginConstraint(forestID, forceForestNearPond);
         rmAreaAddToClass(forestID, pondForestClassID);

         rmAreaBuild(forestID);
      }
   }
   
   applyGeneratedLocs();
   resetLocGen();

   rmSetProgress(0.5);

   // Hunt.
   float avoidHuntMeters = 50.0;

   // Close hunt.
   int closeHuntID = rmObjectDefCreate("close hunt");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeGazelle, xsRandInt(7, 10));
   }
   else
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeDeer, xsRandInt(7, 10));
   }
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeHuntID, 60.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeHuntID, false, 2, 60.0, 0.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(closeHuntID, false, 2, 60.0, 80.0, avoidHuntMeters);
   }

   // Bonus hunt 1.
   int bonusHunt1ID = rmObjectDefCreate("bonus hunt 1");
   rmObjectDefAddItem(bonusHunt1ID, cUnitTypeGazelle, xsRandInt(7, 10));
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
   rmObjectDefAddItem(bonusHunt2ID, cUnitTypeDeer, xsRandInt(7, 10));
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultFoodAvoidAll);
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
   rmObjectDefAddItem(bonusHunt3ID, cUnitTypeCrownedCrane, xsRandInt(7, 10));
   rmObjectDefAddConstraint(bonusHunt3ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHunt3ID, vDefaultFoodAvoidAll);
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
      float largeMapHuntFloat = xsRandFloat(0.0, 1.0);
      int largeMapHuntID = rmObjectDefCreate("large map hunt");
      if(largeMapHuntFloat < 1.0 / 3.0)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeDeer, xsRandInt(6, 12));
      }
      else if(largeMapHuntFloat < 2.0 / 3.0)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeGazelle, xsRandInt(5, 11));
      }
      else
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeGazelle, xsRandInt(2, 5));
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeDeer, xsRandInt(4, 8));
      }
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidSettlementRange);
      addObjectDefPlayerLocConstraint(largeMapHuntID, 100.0);
      addObjectLocsPerPlayer(largeMapHuntID, false, 2 * getMapAreaSizeFactor(), 100.0, -1.0, avoidHuntMeters);
   }

   generateLocs("hunt locs");

   rmSetProgress(0.6);

   // Berries.
   float avoidBerriesMeters = 50.0;

   int berriesID = rmObjectDefCreate("berries");
   rmObjectDefAddItem(berriesID, cUnitTypeBerryBush, xsRandInt(7, 10), cBerryClusterRadius);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(berriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(berriesID, vDefaultBerriesAvoidWater);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(berriesID, 70.0);
   if(gameIs1v1() == true)
   {
      addObjectLocsPerPlayer(berriesID, false, 1, 70.0, 100.0, avoidBerriesMeters);
      addObjectLocsPerPlayer(berriesID, false, 1, 70.0, -1.0, avoidBerriesMeters);
   }
   else
   {
      addObjectLocsPerPlayer(berriesID, false, 2, 70.0, -1.0, avoidBerriesMeters);
   }

   generateLocs("berries locs");

   // This map doesn't have predators (yes this is intentional in case you came here to check).

   // Herdables.
   float avoidHerdMeters = 50.0;

   int closeHerdID = rmObjectDefCreate("close herd");
   rmObjectDefAddItem(closeHerdID, cUnitTypePig, xsRandInt(1, 2));
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidTowerLOS);
   addObjectLocsPerPlayer(closeHerdID, false, 2, 50.0, 70.0, avoidHerdMeters);

   int bonusHerdID = rmObjectDefCreate("bonus herd");
   rmObjectDefAddItem(bonusHerdID, cUnitTypePig, xsRandInt(1, 2));
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidTowerLOS);
   addObjectLocsPerPlayer(bonusHerdID, false, 3 * getMapAreaSizeFactor(), 70.0, -1.0, avoidHerdMeters);

   generateLocs("herd locs");

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

   // Embellishment.
   // Gold areas.
   buildAreaUnderObjectDef(startingGoldID, cTerrainAtlanteanGrassRocks1, cTerrainAtlanteanGrass1, 8.0);
   // Berries areas.
   buildAreaUnderObjectDef(startingBerriesID, cTerrainAtlanteanGrass2, cTerrainAtlanteanGrass1, 10.0);
   buildAreaUnderObjectDef(berriesID, cTerrainAtlanteanGrass2, cTerrainAtlanteanGrass1, 10.0);

   rmSetProgress(0.8);

   // Forests.
   float avoidForestMeters = 30.0;

   int forestDefID = rmAreaDefCreate("forest");
   rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(50), rmTilesToAreaFraction(75));
   rmAreaDefSetForestType(forestDefID, cForestAtlanteanLush);
   rmAreaDefSetAvoidSelfDistance(forestDefID, avoidForestMeters);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddConstraint(forestDefID, rmCreateClassDistanceConstraint(pondForestClassID, avoidForestMeters));

   // Starting forests.
   // Slightly extend the max distance because it can get very cramped with starting res and nearby ponds/forests.
   if(gameIs1v1() == true)
   {
      addSimAreaLocsPerPlayerPair(forestDefID, 3, cStartingForestMinDist, cStartingForestMaxDist + 10.0, avoidForestMeters);
   }
   else
   {
      buildAreaDefAtPlayerLocs(forestDefID, 3, cStartingForestMinDist, cStartingForestMaxDist + 10.0);
   }

   generateLocs("starting forest locs");

   // Stragglers.
   placeStartingStragglers(cUnitTypeTreeOlive);

   rmSetProgress(0.9);

   // Random trees.
   int randomTreeID = rmObjectDefCreate("random tree");
   rmObjectDefAddItem(randomTreeID, cUnitTypeTreeOlive, 1);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidWater);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidTree);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefPlaceAnywhere(randomTreeID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   // Flowers.
   int flowersID = rmObjectDefCreate("flowers");
   rmObjectDefAddItem(flowersID, cUnitTypeFlowers, 1);
   rmObjectDefAddConstraint(flowersID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(flowersID, vDefaultAvoidWater8);
   rmObjectDefPlaceAnywhere(flowersID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   // Plants.
   int plantBushID = rmObjectDefCreate("plant bush");
   rmObjectDefAddItem(plantBushID, cUnitTypePlantAtlanteanBush, 1);
   rmObjectDefAddConstraint(plantBushID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantBushID, vDefaultAvoidWater);
   rmObjectDefPlaceAnywhere(plantBushID, 0, 30 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantShrubID = rmObjectDefCreate("plant shrub");
   rmObjectDefAddItem(plantShrubID, cUnitTypePlantAtlanteanShrub, 1);
   rmObjectDefAddConstraint(plantShrubID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantShrubID, vDefaultAvoidWater);
   rmObjectDefPlaceAnywhere(plantShrubID, 0, 30 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantFernID = rmObjectDefCreate("plant fern");
   rmObjectDefAddItemRange(plantFernID, cUnitTypePlantAtlanteanFern, 1);
   rmObjectDefAddConstraint(plantFernID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantFernID, vDefaultAvoidWater);
   rmObjectDefPlaceAnywhere(plantFernID, 0, 40 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantWeedsID = rmObjectDefCreate("plant weeds");
   rmObjectDefAddItemRange(plantWeedsID, cUnitTypePlantAtlanteanWeeds, 1);
   rmObjectDefAddConstraint(plantWeedsID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantWeedsID, vDefaultAvoidWater);
   rmObjectDefPlaceAnywhere(plantWeedsID, 0, 40 * cNumberPlayers * getMapAreaSizeFactor());

   // Rocks.
   int rockTinyID = rmObjectDefCreate("rock tiny");
   rmObjectDefAddItemRange(rockTinyID, cUnitTypeRockAtlanteanTiny, 1);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidAll);
   // rmObjectDefAddConstraint(rockTinyID, vDefaultAvoidWater);
   rmObjectDefPlaceAnywhere(rockTinyID, 0, 50 * cNumberPlayers * getMapAreaSizeFactor());

   int rockSmallID = rmObjectDefCreate("rock small");
   rmObjectDefAddItemRange(rockSmallID, cUnitTypeRockAtlanteanSmall, 1);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidAll);
   // rmObjectDefAddConstraint(rockSmallID, vDefaultAvoidWater);
   rmObjectDefPlaceAnywhere(rockSmallID, 0, 50 * cNumberPlayers * getMapAreaSizeFactor());

   // Water stuff.
   int waterEmbellishmentAvoidLand = rmCreateWaterDistanceConstraint(false, 4.0);

   int waterReedsID = rmObjectDefCreate("water reeds");
   rmObjectDefAddItemRange(waterReedsID, cUnitTypeWaterReeds, 1);
   rmObjectDefAddConstraint(waterReedsID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(waterReedsID, waterEmbellishmentAvoidLand);
   rmObjectDefPlaceAnywhere(waterReedsID, 0, 20 * cNumberPlayers * getMapAreaSizeFactor());

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeHawk, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   rmSetProgress(1.0);
}
