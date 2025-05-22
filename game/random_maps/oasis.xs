include "lib2/rm_core.xs";

void generate()
{
   rmSetProgress(0.0);

   // Define mixes.
   int baseMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.15, 1);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptDirt1, 3.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptSand1, 2.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptSand2, 2.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptSand3, 2.0);

   // Override water layer; we only want very short beaches here.
   rmWaterTypeAddBeachLayer(cWaterEgyptLake, cTerrainEgyptBeach1, 4.0);

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
   rmSetTeamSpacingModifier(0.9);
   rmPlacePlayersOnSquare(0.375);

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCivFromCulture(cCultureEgyptian);

   // Lighting.
   rmSetLighting(cLightingSetRmOasis01);

   rmSetProgress(0.1);

   // Global elevation.
   rmAddGlobalHeightNoise(cNoiseFractalSum, 6.0, 0.05, 2, 0.5);

   // Settlements and towers.
   placeStartingTownCenters();

   // Oases.
   int oasisClassID = rmClassCreate();
   int oasisGrassClassID = rmClassCreate();
   int avoidOasis = rmCreateClassDistanceConstraint(oasisClassID, 1.0);
   int avoidOasisGrass = rmCreateClassDistanceConstraint(oasisGrassClassID, 1.0);
   int oasisAvoidSelf = rmCreateClassDistanceConstraint(oasisClassID, 10.0);
   int oasisAvoidBuilding = rmCreateTypeDistanceConstraint(cUnitTypeBuilding, 20.0);
   int oasisPondAvoidOasisEdge = rmCreateClassDistanceConstraint(oasisClassID, 6.0, cClassAreaEdgeDistance);

   // There are many different ways on how this can be done, this is one of them.
   // Since the grass is only embellishment, the forest is prioritized.
   // This is the area we care about (the forest).
   int oasisForestDefID = rmAreaDefCreate("oasis forest");
   rmAreaDefSetForestType(oasisForestDefID, cForestEgyptPalmGrass);
   rmAreaDefSetCoherence(oasisForestDefID, 0.25);
   rmAreaDefSetEdgeSmoothDistance(oasisForestDefID, 5);
   rmAreaDefAddConstraint(oasisForestDefID, oasisAvoidBuilding);
   rmAreaDefAddConstraint(oasisForestDefID, oasisAvoidSelf, 0.0, 10.0);
   rmAreaDefAddToClass(oasisForestDefID, oasisClassID);

   // Embellishment (grass) outside of the forest.
   int oasisGrassDefID = rmAreaDefCreate("oasis grass");
   rmAreaDefSetTerrainType(oasisGrassDefID, cTerrainEgyptGrass2);
   rmAreaDefAddTerrainLayer(oasisGrassDefID, cTerrainEgyptGrass1, 2);
   rmAreaDefAddTerrainLayer(oasisGrassDefID, cTerrainEgyptGrassDirt1, 1);
   rmAreaDefAddTerrainLayer(oasisGrassDefID, cTerrainEgyptGrassDirt2, 0);
   rmAreaDefAddTerrainConstraint(oasisGrassDefID, avoidOasis); // Do not paint over the trees.
   rmAreaDefSetSize(oasisGrassDefID, 1.0); // Constrained later on.
   rmAreaDefAddToClass(oasisGrassDefID, oasisGrassClassID);

   // Embellishment (ponds) inside the forests.
   int oasisPondDefID = rmAreaDefCreate("oasis pond");
   rmAreaDefSetWaterType(oasisPondDefID, cWaterEgyptLake);
   rmAreaDefSetCoherence(oasisPondDefID, 0.25);
   rmAreaDefSetEdgeSmoothDistance(oasisPondDefID, 5);
   rmAreaDefSetWaterHeight(oasisPondDefID, 2.0);
   rmAreaDefAddConstraint(oasisPondDefID, oasisPondAvoidOasisEdge);

   int numOases = 0;
   float oasesAngle = 0.0;
   float oasesRadiusFrac = 0.0;

   int oasisStyleChance = (gameIsKotH() == true) ? xsRandInt(1, 2) : xsRandInt(0, 2);

   if(oasisStyleChance == 0)
   {
      // Single Oasis.
      numOases = 1;

      rmAreaDefSetSize(oasisForestDefID, 0.11);
      rmAreaDefSetSize(oasisPondDefID, 0.015);
      rmAreaDefAddConstraint(oasisForestDefID, rmCreateTypeDistanceConstraint(cUnitTypeBuilding, 40.0));

      oasesAngle = 0.0;
      oasesRadiusFrac = 0.0;
   }
   else if(oasisStyleChance == 1)
   {
      // Duo oases.
      numOases = 2;

      rmAreaDefSetSize(oasisForestDefID, 0.055);
      rmAreaDefSetSize(oasisPondDefID, 0.0075);

      if(xsRandBool(0.5) == true)
      {
         // Vertical.
         oasesAngle = 0.25 * cPi;
      }
      else
      {
         // Horizontal.
         oasesAngle = 0.75 * cPi;
      }
      oasesRadiusFrac = 0.2;
   }
   else
   {
      // Quad oases.
      numOases = 4;

      rmAreaDefSetSize(oasisForestDefID, 0.035);
      rmAreaDefSetSize(oasisPondDefID, 0.01);

      oasesAngle = 0.25 * cPi;
      oasesRadiusFrac = 0.225;
   }

   // Disable conversion to terrain objects since we're changing the elev when painting over the forest.
   rmSetTOBConversion(false);

   // First the oases.
   for(int i = 0; i < numOases; i++)
   {
      vector oasisLoc = cCenterLoc.translateXZ(oasesRadiusFrac, oasesAngle);

      int oasisID = rmAreaDefCreateArea(oasisForestDefID);
      rmAreaSetLoc(oasisID, oasisLoc);

      // Advance angle.
      oasesAngle += cTwoPi / numOases;
   }

   rmAreaBuildAll();

   rmSetProgress(0.2);

   // Then the grass areas.
   for(int i = 0; i < numOases; i++)
   {
      vector oasisLoc = cCenterLoc.translateXZ(oasesRadiusFrac, oasesAngle);

      int oasisAreaID = rmAreaDefGetCreatedArea(oasisForestDefID, i);

      int oasisGrassID = rmAreaDefCreateArea(oasisGrassDefID);
      rmAreaSetLoc(oasisGrassID, oasisLoc);
      rmAreaAddConstraint(oasisGrassID, rmCreateAreaMaxDistanceConstraint(oasisAreaID, 12.0));

      // Advance angle.
      oasesAngle += cTwoPi / numOases;
   }

   rmAreaBuildAll();

   // Then the ponds.
   for(int i = 0; i < numOases; i++)
   {
      vector oasisLoc = cCenterLoc.translateXZ(oasesRadiusFrac, oasesAngle);

      int oasisPondID = rmAreaDefCreateArea(oasisPondDefID);
      rmAreaSetLoc(oasisPondID, oasisLoc);

      // Advance angle.
      oasesAngle += cTwoPi / numOases;
   }

   rmAreaBuildAll();

   // Re-enable TOB conversion.
   rmSetTOBConversion(true);

   rmSetProgress(0.3);

   // KotH.
   placeKotHObjects(); 

   // Starting towers.
   int startingTowerID = rmObjectDefCreate("starting tower");
   rmObjectDefAddItem(startingTowerID, cUnitTypeSentryTower, 1);
   rmObjectDefAddConstraint(startingTowerID, vDefaultAvoidAll8);
   addObjectLocsPerPlayer(startingTowerID, true, 4, cStartingTowerMinDist, cStartingTowerMaxDist, cStartingTowerAvoidanceMeters);
   generateLocs("starting tower locs");

   // Settlements.
   int firstSettlementID = rmObjectDefCreate("first settlement");
   rmObjectDefAddItem(firstSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidAllWithFarm);
   rmObjectDefAddConstraint(firstSettlementID, avoidOasis);

   int secondSettlementID = rmObjectDefCreate("second settlement");
   rmObjectDefAddItem(secondSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidAllWithFarm);
   rmObjectDefAddConstraint(secondSettlementID, avoidOasis);
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
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidAllWithFarm);
      rmObjectDefAddConstraint(bonusSettlementID, avoidOasis);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidKotH);
      rmObjectDefAddConstraint(bonusSettlementID, rmCreateLocDistanceConstraint(cCenterLoc, 35.0));
      addObjectLocsPerPlayer(bonusSettlementID, false, 1 * getMapAreaSizeFactor(), 90.0, -1.0, 90.0);
   }

   generateLocs("settlement locs");

   rmSetProgress(0.4);

   // Starting objects.
   // Starting gold.
   int startingGoldID = rmObjectDefCreate("starting gold");
   rmObjectDefAddItem(startingGoldID, cUnitTypeMineGoldMedium, 1);
   rmObjectDefAddConstraint(startingGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(startingGoldID, vDefaultStartingGoldAvoidTower);
   rmObjectDefAddConstraint(startingGoldID, vDefaultForceStartingGoldNearTower);
   rmObjectDefAddConstraint(startingGoldID, avoidOasis);
   addObjectLocsPerPlayer(startingGoldID, false, 1, cStartingGoldMinDist, cStartingGoldMaxDist, cStartingObjectAvoidanceMeters);

   generateLocs("starting gold locs");

   // Starting hunt.
   int startingHuntID = rmObjectDefCreate("starting hunt");
   rmObjectDefAddItem(startingHuntID, cUnitTypeZebra, 6);
   rmObjectDefAddConstraint(startingHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHuntID, vDefaultForceInTowerLOS);
   rmObjectDefAddConstraint(startingHuntID, avoidOasis);
   addObjectLocsPerPlayer(startingHuntID, false, 1, cStartingHuntMinDist, cStartingHuntMaxDist, cStartingObjectAvoidanceMeters);

   // Berries.
   int startingBerriesID = rmObjectDefCreate("starting berries");
   rmObjectDefAddItem(startingBerriesID, cUnitTypeBerryBush, xsRandInt(6, 9), cBerryClusterRadius);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(startingBerriesID, avoidOasis);
   addObjectLocsPerPlayer(startingBerriesID, false, 1, cStartingBerriesMinDist, cStartingBerriesMaxDist, cStartingObjectAvoidanceMeters);

   // Chicken.
   int startingChickenID = rmObjectDefCreate("starting chicken");
   rmObjectDefAddItem(startingChickenID, cUnitTypeChicken, xsRandInt(5, 7));
   rmObjectDefAddConstraint(startingChickenID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingChickenID, avoidOasis);
   addObjectLocsPerPlayer(startingChickenID, false, 1, cStartingChickenMinDist, cStartingChickenMaxDist, cStartingObjectAvoidanceMeters);

   // Herdables.
   int startingHerdID = rmObjectDefCreate("starting herd");
   rmObjectDefAddItem(startingHerdID, cUnitTypeGoat, 2);
   rmObjectDefAddConstraint(startingHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(startingHerdID, avoidOasis);
   addObjectLocsPerPlayer(startingHerdID, true, 1, cStartingHerdMinDist, cStartingHerdMaxDist);

   generateLocs("starting food locs");

   rmSetProgress(0.5);

   // Gold.
   float avoidGoldMeters = 50.0;

   // Medium gold.
   int closeGoldID = rmObjectDefCreate("close gold");
   rmObjectDefAddItem(closeGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(closeGoldID, avoidOasis);
   addObjectDefPlayerLocConstraint(closeGoldID, 50.0);

   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeGoldID, false, 1, 50.0, 70.0, avoidGoldMeters, cBiasForward);
   }
   else
   {
      addObjectLocsPerPlayer(closeGoldID, false, 1, 50.0, 70.0, avoidGoldMeters, cBiasForward);
   }

   // Bonus gold.
   int bonusGoldID = rmObjectDefCreate("bonus gold");
   rmObjectDefAddItem(bonusGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(bonusGoldID, avoidOasis);
   addObjectDefPlayerLocConstraint(bonusGoldID, 70.0);

   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusGoldID, false, 3 * getMapAreaSizeFactor(), 70.0, -1.0, avoidGoldMeters);
   }
   else
   {
      addObjectLocsPerPlayer(bonusGoldID, false, 3 * getMapAreaSizeFactor(), 70.0, -1.0, avoidGoldMeters);
   }

   generateLocs("gold locs");

   // Hunt.
   float avoidHuntMeters = 50.0;

   // Far hunt.
   int farHuntID = rmObjectDefCreate("far hunt");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(farHuntID, cUnitTypeGiraffe, xsRandInt(2, 4));
      rmObjectDefAddItem(farHuntID, cUnitTypeGazelle, xsRandInt(2, 4));
   }
   else
   {
      rmObjectDefAddItem(farHuntID, cUnitTypeGiraffe, xsRandInt(3, 6));
   }
   rmObjectDefAddConstraint(farHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(farHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(farHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(farHuntID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(farHuntID, avoidOasis);
   addObjectDefPlayerLocConstraint(farHuntID, 70.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(farHuntID, false, 1, 70.0, 100.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(farHuntID, false, 1, 70.0, 100.0, avoidHuntMeters);
   }

   // Bonus hunt.
   int bonusHuntID = rmObjectDefCreate("bonus hunt");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(bonusHuntID, cUnitTypeMonkey, xsRandInt(8, 12));
   }
   else
   {
      rmObjectDefAddItem(bonusHuntID, cUnitTypeBaboon, xsRandInt(8, 12));
   }
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(bonusHuntID, avoidOasis);
   addObjectDefPlayerLocConstraint(bonusHuntID, 80.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusHuntID, false, 1, 100.0, -1.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(bonusHuntID, false, 1, 80.0, -1.0, avoidHuntMeters);
   }

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
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeGiraffe, xsRandInt(3, 7));
      }

      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidSettlementRange);
      rmObjectDefAddConstraint(largeMapHuntID, avoidOasis);
      addObjectDefPlayerLocConstraint(largeMapHuntID, 70.0);
      addObjectLocsPerPlayer(largeMapHuntID, false, 1 * getMapAreaSizeFactor(), 100.0, -1.0, avoidHuntMeters);
   }

   generateLocs("hunt locs");

   rmSetProgress(0.6);

   // Berries.
   float avoidBerriesMeters = 50.0;

   int berriesID = rmObjectDefCreate("berries");
   rmObjectDefAddItem(berriesID, cUnitTypeBerryBush, xsRandInt(7, 10), cBerryClusterRadius);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(berriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(berriesID, avoidOasis);
   addObjectDefPlayerLocConstraint(berriesID, 80.0);
   addObjectLocsPerPlayer(berriesID, false, 1 * getMapSizeBonusFactor(), 80.0, -1.0, avoidBerriesMeters);

   generateLocs("berries locs");

   // Herdables.
   float avoidHerdMeters = 50.0;

   int closeHerdID = rmObjectDefCreate("close herd");
   rmObjectDefAddItem(closeHerdID, cUnitTypeGoat, xsRandInt(1, 3));
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHerdID, avoidOasis);
   addObjectLocsPerPlayer(closeHerdID, false, 2, 50.0, 70.0, avoidHerdMeters);

   int bonusHerdID = rmObjectDefCreate("bonus herd");
   rmObjectDefAddItem(bonusHerdID, cUnitTypeGoat, 2);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHerdID, avoidOasis);
   addObjectLocsPerPlayer(bonusHerdID, false, 3 * getMapSizeBonusFactor(), 70.0, -1.0, avoidHerdMeters);

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
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(predatorID, avoidOasis);
   addObjectDefPlayerLocConstraint(predatorID, 80.0);
   addObjectLocsPerPlayer(predatorID, false, xsRandInt(1, 2) * getMapAreaSizeFactor(), 80.0, -1.0, avoidPredatorMeters);

   generateLocs("predator locs");

   // Relics.
   float avoidRelicMeters = 80.0;

   int relicID = rmObjectDefCreate("relic");
   rmObjectDefAddItem(relicID, cUnitTypeRelic, 1);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidAll);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(relicID, avoidOasis);
   addObjectDefPlayerLocConstraint(relicID, 80.0);
   addObjectLocsPerPlayer(relicID, false, 2 * getMapAreaSizeFactor(), 80.0, -1.0, avoidRelicMeters);

   generateLocs("relic locs");

   rmSetProgress(0.7);

   // Forests.
   float avoidForestMeters = 30.0;

   int forestDefID = rmAreaDefCreate("forest");
   rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(30), rmTilesToAreaFraction(40));
   rmAreaDefSetForestType(forestDefID, cForestEgyptPalm);
   rmAreaDefSetAvoidSelfDistance(forestDefID, avoidForestMeters);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddConstraint(forestDefID, rmCreateClassDistanceConstraint(oasisClassID, 30.0));

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
   buildAreaDefInTeamAreas(forestDefID, 6 * getMapAreaSizeFactor());

   // Stragglers.
   placeStartingStragglers(cUnitTypeTreePalm);

   rmSetProgress(0.8);

   // Embellishment.
   // Gold areas.
   buildAreaUnderObjectDef(startingGoldID, cTerrainEgyptDirtRocks2, cTerrainEgyptDirtRocks1, 6.0);
   buildAreaUnderObjectDef(closeGoldID, cTerrainEgyptDirtRocks2, cTerrainEgyptDirtRocks1, 6.0);
   buildAreaUnderObjectDef(bonusGoldID, cTerrainEgyptDirtRocks2, cTerrainEgyptDirtRocks1, 6.0);

   // Berries areas.
   buildAreaUnderObjectDef(startingBerriesID, cTerrainEgyptGrass1, cTerrainEgyptGrassDirt2, 10.0);
   buildAreaUnderObjectDef(berriesID, cTerrainEgyptGrass1, cTerrainEgyptGrassDirt2, 10.0);

   rmSetProgress(0.9);

   // Random trees.
   int randomTreeID = rmObjectDefCreate("random tree");
   rmObjectDefAddItem(randomTreeID, cUnitTypeTreePalm, 1);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidImpassableLand);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidTree);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefAddConstraint(randomTreeID, avoidOasis);
   rmObjectDefAddConstraint(randomTreeID, avoidOasisGrass);
   rmObjectDefPlaceAnywhere(randomTreeID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   // Rocks.
   int rockTinyID = rmObjectDefCreate("rock tiny");
   rmObjectDefAddItem(rockTinyID, cUnitTypeRockEgyptTiny, 1);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefPlaceAnywhere(rockTinyID, 0, 40 * cNumberPlayers * getMapAreaSizeFactor());

   int rockSmallID = rmObjectDefCreate("rock small");
   rmObjectDefAddItem(rockSmallID, cUnitTypeRockEgyptSmall, 1);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefPlaceAnywhere(rockSmallID, 0, 40 * cNumberPlayers * getMapAreaSizeFactor());

   // Plants.
   int plantDeadShrubID = rmObjectDefCreate("dead shrub");
   rmObjectDefAddItem(plantDeadShrubID, cUnitTypePlantDeadShrub, 1);
   rmObjectDefAddConstraint(plantDeadShrubID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantDeadShrubID, avoidOasisGrass);
   rmObjectDefPlaceAnywhere(plantDeadShrubID, 0, 30 * cNumberPlayers * getMapAreaSizeFactor());

   int plantDeadBushID = rmObjectDefCreate("dead bush");
   rmObjectDefAddItem(plantDeadBushID, cUnitTypePlantDeadBush, 1);
   rmObjectDefAddConstraint(plantDeadBushID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantDeadBushID, avoidOasisGrass);
   rmObjectDefPlaceAnywhere(plantDeadBushID, 0, 30 * cNumberPlayers * getMapAreaSizeFactor());

   int plantDeadFernID = rmObjectDefCreate("dead fern");
   rmObjectDefAddItem(plantDeadFernID, cUnitTypePlantDeadFern, 1);
   rmObjectDefAddConstraint(plantDeadFernID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantDeadFernID, avoidOasisGrass);
   rmObjectDefPlaceAnywhere(plantDeadFernID, 0, 30 * cNumberPlayers * getMapAreaSizeFactor());
   
   // Sand VFX.
   int sandDriftPlainID = rmObjectDefCreate("sand drift plain");
   rmObjectDefAddItem(sandDriftPlainID, cUnitTypeVFXSandDriftPlain, 1);
   rmObjectDefAddConstraint(sandDriftPlainID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(sandDriftPlainID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(sandDriftPlainID, avoidOasisGrass);
   rmObjectDefPlaceAnywhere(sandDriftPlainID, 0, 4 * cNumberPlayers * getMapAreaSizeFactor());

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeVulture, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   rmSetProgress(1.0);
}
