include "lib2/rm_core.xs";
include "lib2/rm_connections.xs";

void generate()
{
   rmSetProgress(0.0);

   // Define mixes.
   int baseMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.05, 5, 0.5);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptDirt1, 4.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptSand1, 2.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptSand2, 2.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptSand3, 4.0);

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
   float placementRadius = 0.2 + 0.02 * sqrt(cNumberPlayers);
   rmSetTeamSpacingModifier(0.7 + 0.02 * sqrt(cNumberPlayers));
   rmPlacePlayersOnCircle(placementRadius);

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCivFromCulture(cCultureEgyptian);

   // Lighting.
   rmSetLighting(cLightingSetRmAir01);

   rmSetProgress(0.1);

   // Global elevation.
   rmAddGlobalHeightNoise(cNoiseFractalSum, 6.0, 0.075, 5, 0.1);
   
   placeStartingTownCenters();
   
   // Central mountain.
   float mountainSize = rmRadiusToAreaFraction(rmXFractionToMeters(placementRadius - 0.075));
   
   int mountainAreaID = rmAreaCreate("mountain");
   rmAreaSetLoc(mountainAreaID, cCenterLoc);
   rmAreaSetSize(mountainAreaID, mountainSize);
   
   rmAreaSetCliffType(mountainAreaID, cCliffEgyptSand);
   rmAreaSetCliffSideRadius(mountainAreaID, 0, 2);
   rmAreaSetCliffPaintInsideAsSide(mountainAreaID, true);
   rmAreaSetCliffEmbellishmentDensity(mountainAreaID, 0.2);
   
   rmAreaSetHeightNoise(mountainAreaID, cNoiseFractalSum, 15.0, 0.1, 4, 0.5);
   rmAreaSetHeightNoiseBias(mountainAreaID, 1.0); // Only grow upwards.
   
   rmAreaAddHeightBlend(mountainAreaID, cBlendEdge, cFilter5x5Gaussian, 2);
   rmAreaSetCoherence(mountainAreaID, 0.2);
   rmAreaSetEdgeSmoothDistance(mountainAreaID, 2);
   
   rmAreaAddConstraint(mountainAreaID, rmCreateTypeDistanceConstraint(cUnitTypeTownCenter, 30.0), 0.0, 20.0);

   rmAreaBuild(mountainAreaID);
   
   // Core part of mountain is taller.
   int mountainCliffsID = rmAreaCreate("mountain cliffs");
   
   rmAreaSetLoc(mountainCliffsID, cCenterLoc);
   rmAreaSetSize(mountainCliffsID, mountainSize / 3.0);
   
   rmAreaSetCliffType(mountainCliffsID, cCliffEgyptSand);
   rmAreaSetCliffSideRadius(mountainCliffsID, 0, 2);
   rmAreaSetCliffPaintInsideAsSide(mountainCliffsID, true);
   rmAreaSetCliffLayerPaint(mountainCliffsID, cCliffLayerOuterSideClose, false);
   rmAreaSetCliffLayerPaint(mountainCliffsID, cCliffLayerOuterSideFar, false);
   
   rmAreaSetHeightRelative(mountainCliffsID, 5.0);
   rmAreaSetHeightNoise(mountainCliffsID, cNoiseFractalSum, 10.0, 0.02, 5, 1.0);
   rmAreaSetHeightNoiseBias(mountainCliffsID, 1.0); // Only grow upwards.
   
   rmAreaAddHeightBlend(mountainCliffsID, cBlendEdge, cFilter5x5Gaussian, 2);
   
   rmAreaAddConstraint(mountainCliffsID, rmCreateAreaConstraint(mountainAreaID));
   rmAreaAddConstraint(mountainCliffsID, rmCreateAreaEdgeDistanceConstraint(mountainAreaID, 5.0));

   rmAreaBuild(mountainCliffsID);

   // KotH.
   if (gameIsKotH() == true)
   {
      int pathDefID = rmPathDefCreate("koth connection path");
      // No params to set here, we want direct paths.

      // Areas.
      int pathAreaDefID = rmAreaDefCreate("koth connection area");
      rmAreaDefSetMix(pathAreaDefID, baseMixID);

      rmAreaDefAddHeightBlend(pathAreaDefID, cBlendAll, cFilter5x5Box, 5, 10);

      rmAreaDefSetCliffType(pathAreaDefID, cCliffEgyptSand);
      rmAreaDefSetCliffSideRadius(pathAreaDefID, 0, 2);
      rmAreaDefSetCliffLayerPaint(pathAreaDefID, cCliffLayerOuterSideClose, false);
      rmAreaDefSetCliffLayerPaint(pathAreaDefID, cCliffLayerOuterSideFar, false);
      rmAreaDefAddToClass(pathAreaDefID, vKotHClassID);

      // Everything that is NOT impassable land will not be turned into "cliff edge" terrain (i.e., is left untouched).
      // We only want to build a path through the cliff.
      rmAreaDefAddCliffEdgeConstraint(pathAreaDefID, cCliffEdgeIgnored, vDefaultAvoidImpassableLand);

      // Get a random angle to build the path from.
      float kothPathAngle = randRadian();
      float kothLocRadiusFraction = 0.3;
      vector kothLoc1 = cCenterLoc.translateXZ(kothLocRadiusFraction, kothPathAngle);
      vector kothLoc2 = cCenterLoc.translateXZ(kothLocRadiusFraction, kothPathAngle + cPiOver2);
      vector kothLoc3 = cLocCornerNorth - kothLoc1; // Dirty trick to mirror the loc.
      vector kothLoc4 = cLocCornerNorth - kothLoc2;

      if (gameIs1v1() && xsRandBool(0.5) == true)
      {
         createLocConnection("koth connection horizontal", pathDefID, pathAreaDefID, kothLoc1, kothLoc3, 20.0, 5.0);
      }
      else if (gameIs1v1())
      {
         createLocConnection("koth connection vertical", pathDefID, pathAreaDefID, kothLoc2, kothLoc4, 20.0, 5.0);
      }
      else
      {
         createLocConnection("koth connection vertical", pathDefID, pathAreaDefID, kothLoc1, kothLoc3, 20.0, 5.0);
         createLocConnection("koth connection horizontal", pathDefID, pathAreaDefID, kothLoc2, kothLoc4, 20.0, 5.0);
      }
   }

   placeKotHObjects();

   rmSetProgress(0.2);
   
   // Settlements and towers.
   // Starting towers.
   int startingTowerID = rmObjectDefCreate("starting tower");
   rmObjectDefAddItem(startingTowerID, cUnitTypeSentryTower, 1);
   rmObjectDefAddConstraint(startingTowerID, vDefaultAvoidImpassableLand4);
   addObjectLocsPerPlayer(startingTowerID, true, 4, cStartingTowerMinDist, cStartingTowerMaxDist, cStartingTowerAvoidanceMeters);
   generateLocs("starting tower locs");

   // Settlements.
   int firstSettlementID = rmObjectDefCreate("first settlement");
   rmObjectDefAddItem(firstSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidImpassableLand);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidTowerLOS);

   int secondSettlementID = rmObjectDefCreate("second settlement");
   rmObjectDefAddItem(secondSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidImpassableLand);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidTowerLOS);
   
   if(gameIs1v1() == true)
   {
      int settlementSideChance = cLocSideOpposite;
      
      if (xsRandBool(0.5) == true)
      {
         settlementSideChance = cLocSideSame;
      }
      
      addSimObjectLocsPerPlayerPair(firstSettlementID, false, 1, 60.0, 80.0, cSettlementDist1v1, cBiasBackward);
      addSimObjectLocsPerPlayerPair(secondSettlementID, false, 1, 75.0, 90.0, cSettlementDist1v1, cBiasAggressive,
                          cInAreaDefault, settlementSideChance);
   }
   else
   {
      addObjectLocsPerPlayer(firstSettlementID, false, 1, 60.0, 80.0, cCloseSettlementDist, cBiasBackward);
      addObjectLocsPerPlayer(secondSettlementID, false, 1, 100.0, 130.0, cFarSettlementDist, cBiasAggressive);
   }
   
   // Other map sizes settlements.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int bonusSettlementID = rmObjectDefCreate("bonus settlement");
      rmObjectDefAddItem(bonusSettlementID, cUnitTypeSettlement, 1);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidEdge);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidImpassableLand);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidTowerLOS);
      addObjectLocsPerPlayer(bonusSettlementID, false, 1 * getMapAreaSizeFactor(), 90.0, -1.0, 100.0);
   }

   generateLocs("settlement locs");

   rmSetProgress(0.3);
   
   // Cliffs.
   int cliffClassID = rmClassCreate();
   int numCliffsPerPlayer = 3 * getMapAreaSizeFactor();

   float cliffMinSize = rmTilesToAreaFraction(50 * getMapAreaSizeFactor());
   float cliffMaxSize = rmTilesToAreaFraction(125 * getMapAreaSizeFactor());
   int cliffAvoidCliff = rmCreateClassDistanceConstraint(cliffClassID, 60.0);
   int cliffAvoidBuildings = rmCreateTypeDistanceConstraint(cUnitTypeBuilding, 25.0);

   for(int i = 1; i <= cNumberPlayers; i++)
   {
      int p = vDefaultTeamPlayerOrder[i];
      int teamArea = vTeamAreaIDs[rmGetPlayerTeam(p)];

      for(int j = 0; j < numCliffsPerPlayer; j++)
      {
         int cliffID = rmAreaCreate("cliff " + p + " " + j);
         rmAreaSetParent(cliffID, teamArea);

         rmAreaSetSize(cliffID, xsRandFloat(cliffMinSize, cliffMaxSize));
         rmAreaSetCliffType(cliffID, cCliffEgyptSand);
         rmAreaSetCliffSideSheernessThreshold(cliffID, degToRad(40.0));
         rmAreaSetCliffSideRadius(cliffID, 0, 2);
         rmAreaSetCliffPaintInsideAsSide(cliffID, true);
         rmAreaSetCliffEmbellishmentDensity(cliffID, 0.15);

         rmAreaSetHeightRelative(cliffID, 3.0);
         rmAreaSetHeightNoise(cliffID, cNoiseFractalSum, 20.0, 0.15, 3, 0.5);
         rmAreaSetHeightNoiseBias(cliffID, 1.0); // Only grow upwards.

         rmAreaSetCoherence(cliffID, 0.15);
         rmAreaAddHeightBlend(cliffID, cBlendEdge, cFilter5x5Gaussian, 2);

         rmAreaAddConstraint(cliffID, cliffAvoidCliff);
         rmAreaAddConstraint(cliffID, cliffAvoidBuildings);
         rmAreaAddConstraint(cliffID, vDefaultAvoidImpassableLand24); // Center.
         rmAreaAddToClass(cliffID, cliffClassID);
                  
         rmAreaBuild(cliffID);
      }
   }

   // Starting objects.
   // Starting gold.
   int startingGoldID = rmObjectDefCreate("starting gold");
   rmObjectDefAddItem(startingGoldID, cUnitTypeMineGoldMedium, 1);
   rmObjectDefAddConstraint(startingGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(startingGoldID, vDefaultStartingGoldAvoidTower);
   rmObjectDefAddConstraint(startingGoldID, vDefaultForceStartingGoldNearTower);
   addObjectLocsPerPlayer(startingGoldID, false, 1, cStartingGoldMinDist, cStartingGoldMaxDist, cStartingObjectAvoidanceMeters);

   generateLocs("starting gold locs");

   // Berries.
   int startingBerriesID = rmObjectDefCreate("starting berries");
   rmObjectDefAddItem(startingBerriesID, cUnitTypeBerryBush, xsRandInt(6, 9), cBerryClusterRadius);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultFoodAvoidImpassableLand);
   addObjectLocsPerPlayer(startingBerriesID, false, 1, cStartingBerriesMinDist, cStartingBerriesMaxDist, cStartingObjectAvoidanceMeters);

   // Starting hunt.
   int startingHuntID = rmObjectDefCreate("starting hunt");
   rmObjectDefAddItem(startingHuntID, cUnitTypeZebra, xsRandInt(7, 9));
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(startingHuntID, vDefaultForceInTowerLOS);
   addObjectLocsPerPlayer(startingHuntID, false, 1, cStartingHuntMinDist, cStartingHuntMaxDist, cStartingObjectAvoidanceMeters);

   // Chicken.
   int startingChickenID = rmObjectDefCreate("starting chicken");
   rmObjectDefAddItem(startingChickenID, cUnitTypeChicken, xsRandInt(5, 7));
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidImpassableLand);
   addObjectLocsPerPlayer(startingChickenID, false, 1, cStartingChickenMinDist, cStartingChickenMaxDist, cStartingObjectAvoidanceMeters);

   // Herdables.
   int startingHerdID = rmObjectDefCreate("starting herd");
   rmObjectDefAddItem(startingHerdID, cUnitTypeGoat, xsRandInt(2, 4));
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidImpassableLand);
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
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeGoldID, 55.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeGoldID, false, 1, 55.0, 65.0, avoidGoldMeters, cBiasForward);
   }
   else
   {
      addObjectLocsPerPlayer(closeGoldID, false, 1, 55.0, 75.0, avoidGoldMeters);
   }

   // Bonus gold.
   int bonusGoldID = rmObjectDefCreate("bonus gold");
   rmObjectDefAddItem(bonusGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(bonusGoldID, 70.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusGoldID, false, xsRandInt(3, 5) * getMapAreaSizeFactor(), 70.0, -1.0, avoidGoldMeters);
   }
   else
   {
      addObjectLocsPerPlayer(bonusGoldID, false, xsRandInt(3, 5) * getMapAreaSizeFactor(), 70.0, -1.0, avoidGoldMeters);
   }

   generateLocs("gold locs");

   rmSetProgress(0.5);

   // Hunt.
   float avoidHuntMeters = 50.0;

   // Close hunt.
   int closeHuntID = rmObjectDefCreate("close hunt");
   rmObjectDefAddItem(closeHuntID, cUnitTypeGazelle, xsRandInt(6, 9));
   rmObjectDefAddItem(closeHuntID, cUnitTypeZebra, xsRandInt(1, 5));
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidKotH);
   addObjectDefPlayerLocConstraint(closeHuntID, 60.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeHuntID, false, 1, 60.0, 80.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(closeHuntID, false, 1, 60.0, 90.0, avoidHuntMeters);
   }

   // Far hunt.
   float farHuntFloat = xsRandFloat(0.0, 1.0);
   int farHuntID = rmObjectDefCreate("far hunt");
   if(farHuntFloat < 0.7)
   {
      rmObjectDefAddItem(farHuntID, cUnitTypeRhinoceros, xsRandInt(2, 4));
   }
   else 
   {
      rmObjectDefAddItem(farHuntID, cUnitTypeZebra, xsRandInt(7, 9));
   }
   rmObjectDefAddConstraint(farHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(farHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(farHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(farHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(farHuntID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(farHuntID, vDefaultAvoidKotH);
   addObjectDefPlayerLocConstraint(farHuntID, 75.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(farHuntID, false, 1, 75.0, 100.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(farHuntID, false, 1, 75.0, 120.0, avoidHuntMeters);
   }

   // Bonus hunt.
   int bonusHuntID = rmObjectDefCreate("bonus hunt");
   rmObjectDefAddItem(bonusHuntID, cUnitTypeElephant, xsRandInt(1, 2));
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidKotH);
   addObjectDefPlayerLocConstraint(bonusHuntID, 90.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusHuntID, false, 1, 90.0, 120.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(bonusHuntID, false, 1, 90.0, -1.0, avoidHuntMeters);
   }

   // Other map sizes hunt.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int largeMapHuntID = rmObjectDefCreate("large map hunt");
      float largeHuntFloat = xsRandFloat(0.0, 1.0);
      if(largeHuntFloat < 1.0 / 3.0)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeElephant, xsRandInt(1, 3));
      }
      else if(largeHuntFloat < 2.0 / 3.0)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeZebra, xsRandInt(5, 9));
      }
      else
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeRhinoceros, xsRandInt(2, 5));
      }
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidImpassableLand);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidSettlementRange);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidKotH);
      addObjectDefPlayerLocConstraint(largeMapHuntID, 100.0);

      addObjectLocsPerPlayer(largeMapHuntID, false, xsRandInt(1, 2) * getMapAreaSizeFactor(), 100.0, -1.0, avoidHuntMeters);
   }
   
   generateLocs("hunt locs");

   rmSetProgress(0.6);

   // Berries.
   int farBerriesID = rmObjectDefCreate("far berries");
   rmObjectDefAddItem(farBerriesID, cUnitTypeBerryBush, xsRandInt(7, 10), cBerryClusterRadius);
   rmObjectDefAddConstraint(farBerriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(farBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(farBerriesID, vDefaultBerriesAvoidImpassableLand);
   rmObjectDefAddConstraint(farBerriesID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(farBerriesID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(farBerriesID, 70.0);
   addObjectLocsPerPlayer(farBerriesID, false, 1 * getMapAreaSizeFactor(), 70.0, -1.0, 50.0);

   generateLocs("berries locs");

   // Herdables.
   float avoidHerdMeters = 50.0;

   int closeHerdID = rmObjectDefCreate("close herd");
   rmObjectDefAddItem(closeHerdID, cUnitTypeGoat, xsRandInt(2, 4), 4.0);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidTowerLOS);
   addObjectLocsPerPlayer(closeHerdID, false, 1, 50.0, 70.0, avoidHerdMeters);

   int bonusHerdID = rmObjectDefCreate("bonus herd");
   rmObjectDefAddItem(bonusHerdID, cUnitTypeGoat, xsRandInt(1, 2), 4.0, 1);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidTowerLOS);
   addObjectLocsPerPlayer(bonusHerdID, false, xsRandInt(1, 2) * getMapAreaSizeFactor(), 70.0, -1.0, avoidHerdMeters);

   generateLocs("herd locs");

   // Predators.
   float avoidPredatorMeters = 50.0;

   int predatorID = rmObjectDefCreate("predator");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(predatorID, cUnitTypeHyena, xsRandInt(2, 3), 4.0);
   }
   else
   {
      rmObjectDefAddItem(predatorID, cUnitTypeLion, xsRandInt(1, 3), 4.0);
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
   addObjectDefPlayerLocConstraint(relicID, 70.0);
   addObjectLocsPerPlayer(relicID, false, 2 * getMapAreaSizeFactor(), 70.0, -1.0, avoidRelicMeters);

   generateLocs("relic locs");

   rmSetProgress(0.7);

   // Forests.
   float avoidForestMeters = 30.0;

   int forestDefID = rmAreaDefCreate("forest");
   rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(50), rmTilesToAreaFraction(75));
   rmAreaDefSetForestType(forestDefID, cForestEgyptSavannahMix);
   rmAreaDefSetAvoidSelfDistance(forestDefID, avoidForestMeters);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidImpassableLand10);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidKotH);

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
   buildAreaDefInTeamAreas(forestDefID, 7 * getMapAreaSizeFactor());
   
   // Stragglers.
   placeStartingStragglers(cUnitTypeTreeSavannah);

   rmSetProgress(0.8);

   // Embellishment.
   // Mountain forests.
   int mountainForestForceInCenter = rmCreateAreaConstraint(mountainAreaID);
   int mountainForestAvoidCenterEdge = rmCreateAreaEdgeDistanceConstraint(mountainAreaID, 8.0);

   int mountainForestID = rmAreaDefCreate("mountain forest");
   rmAreaDefSetForestType(mountainForestID, cForestEgyptSavannah);
   rmAreaDefSetSizeRange(mountainForestID, rmTilesToAreaFraction(3), rmTilesToAreaFraction(20));
   rmAreaDefAddHeightBlend(mountainForestID, cBlendAll, cFilter5x5Gaussian, 5);

   rmAreaDefAddConstraint(mountainForestID, mountainForestForceInCenter);
   rmAreaDefAddConstraint(mountainForestID, mountainForestAvoidCenterEdge);
   rmAreaDefAddConstraint(mountainForestID, vDefaultAvoidKotH);
   rmAreaDefSetAvoidSelfDistance(mountainForestID, 1.0);

   rmAreaDefCreateAndBuildAreas(mountainForestID, 5 * cNumberPlayers * getMapAreaSizeFactor());

   // Gold areas.
   buildAreaUnderObjectDef(startingGoldID, cTerrainEgyptDirtRocks2, cTerrainEgyptDirtRocks2, 6.0);
   buildAreaUnderObjectDef(closeGoldID, cTerrainEgyptDirtRocks2, cTerrainEgyptDirtRocks2, 6.0);
   buildAreaUnderObjectDef(bonusGoldID, cTerrainEgyptDirtRocks2, cTerrainEgyptDirtRocks2, 6.0);

   // Berries areas.
   buildAreaUnderObjectDef(startingBerriesID, cTerrainEgyptGrass1, cTerrainEgyptGrassDirt2, 10.0);
   buildAreaUnderObjectDef(farBerriesID, cTerrainEgyptGrass1, cTerrainEgyptGrassDirt2, 10.0);

   rmSetProgress(0.9);

   // Random trees.
   int randomTreeID = rmObjectDefCreate("random tree");
   rmObjectDefAddItem(randomTreeID, cUnitTypeTreeSavannah, 1);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidImpassableLand);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidTree);
   rmObjectDefPlaceAnywhere(randomTreeID, 0, 20 * cNumberPlayers * getMapAreaSizeFactor());

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

   // Shrubs.
   int shrubID = rmObjectDefCreate("shrub");
   rmObjectDefAddItem(shrubID, cUnitTypePlantDeadShrub, 1);
   rmObjectDefAddConstraint(shrubID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(shrubID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefPlaceAnywhere(shrubID, 0, 50 * cNumberPlayers * getMapAreaSizeFactor());
   
   // Bush.
   int bushID = rmObjectDefCreate("bush");
   rmObjectDefAddItem(bushID, cUnitTypePlantDeadBush, 1);
   rmObjectDefAddConstraint(bushID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(bushID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefPlaceAnywhere(bushID, 0, 50 * cNumberPlayers * getMapAreaSizeFactor());
   
   // Grass.
   int grassID = rmObjectDefCreate("grass");
   rmObjectDefAddItem(grassID, cUnitTypePlantDeadGrass, 1);
   rmObjectDefAddConstraint(grassID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(grassID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefPlaceAnywhere(grassID, 0, 50 * cNumberPlayers * getMapAreaSizeFactor());
   
   // Sand VFX.
   int sandDriftPatchID = rmObjectDefCreate("sand drift patch");
   rmObjectDefAddItem(sandDriftPatchID, cUnitTypeVFXSandDriftPatch, 1);
   rmObjectDefAddConstraint(sandDriftPatchID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(sandDriftPatchID, vDefaultAvoidImpassableLand8);
   rmObjectDefAddConstraint(sandDriftPatchID, vDefaultAvoidAll);
   rmObjectDefPlaceAnywhere(sandDriftPatchID, 0, 5 * cNumberPlayers * getMapAreaSizeFactor());

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeVulture, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());
   
   rmSetProgress(1.0);
}
