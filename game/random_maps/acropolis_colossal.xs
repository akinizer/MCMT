include "lib2/rm_core.xs";

// Override.
mutable void applySuddenDeath()
{
   // Remove all settlements.
   rmRemoveUnitType(cUnitTypeSettlement);

   // Add some tents (not around towers).
   int tentID = rmObjectDefCreate(cSuddenDeathTentName);
   rmObjectDefAddItem(tentID, cUnitTypeTent, 1);
   rmObjectDefAddConstraint(tentID, vDefaultAvoidCollideable);
   addObjectLocsPerPlayer(tentID, true, cNumberSuddenDeathTents, cStartingTowerMinDist - 10.0,
                          cStartingTowerMaxDist + 10.0, cStartingTowerAvoidanceMeters);

   generateLocs("sudden death tent locs");
}

void generate()
{
   rmSetProgress(0.0);
   
   // Define mixes.
   int baseMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.3, 2);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainGreekGrass2, 3.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainGreekGrass1, 4.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainGreekGrassDirt1, 4.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainGreekGrassDirt2, 2.0);
   
   int cliffMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(cliffMixID, cNoiseFractalSum, 0.3, 5, 0.5);
   rmCustomMixAddPaintEntry(cliffMixID, cTerrainGreekGrass2, 1.0);
   rmCustomMixAddPaintEntry(cliffMixID, cTerrainGreekGrass1, 1.0);
   rmCustomMixAddPaintEntry(cliffMixID, cTerrainGreekGrassDirt1, 1.0);
   rmCustomMixAddPaintEntry(cliffMixID, cTerrainGreekGrassRocks2, 1.0);

   // Map size and terrain init.
   //int axisTiles = getScaledAxisTiles(136);
   //rmSetMapSize(axisTiles);
   //rmInitializeMix(baseMixID);

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
      rmPlacePlayersOnCircle(xsRandFloat(0.40, 0.41));
   }
   else
   {
      rmPlacePlayersOnCircle(xsRandFloat(0.43, 0.44));
   }

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCivFromCulture(cCultureGreek);

   // Global elevation.
   rmAddGlobalHeightNoise(cNoiseFractalSum, 3.0, 0.1, 5, 0.3);

   // KotH.
   placeKotHObjects();

   // Lighting.
   rmSetLighting(cLightingSetRmAcropolis01);

   rmSetProgress(0.1);

   // Generate player plateaus.
   int plateauClassID = rmClassCreate();
   int avoidPlateau = rmCreateClassDistanceConstraint(plateauClassID, 0.1);
   int forceOnPlateau = rmCreateClassMaxDistanceConstraint(plateauClassID, 0.1);

   float plateauAreaSize = rmRadiusToAreaFraction(67.5);
   
   float plateauDist = (gameIs1v1() == true) ? 95.0 : 45.0;
   int plateauAvoidPlateau = rmCreateClassDistanceConstraint(plateauClassID, plateauDist);
   string plateauName = "player plateau";

   for(int i = 1; i <= cNumberPlayers; i++)
   {
      int p = vDefaultTeamPlayerOrder[i];

      int plateauID = rmAreaCreate(plateauName + " " + p); // Could also constrain to player areas here.
      rmAreaSetSize(plateauID, plateauAreaSize);
      rmAreaSetLocPlayer(plateauID, p);
      rmAreaSetMix(plateauID, cliffMixID);

      rmAreaSetCoherence(plateauID, 0.75);
      // Do not smooth near corners or we will get gaps.
      rmAreaSetEdgeSmoothDistance(plateauID, 2, false);

      rmAreaSetBlobs(plateauID, 1, 5);
      rmAreaSetBlobDistance(plateauID, 10.0, 25.0);

      rmAreaSetHeightRelative(plateauID, 7.0);
      rmAreaSetHeightNoise(plateauID, cNoiseFractalSum, 3.0, 0.1, 3, 0.5);
      rmAreaSetHeightNoiseBias(plateauID, 1.0); // Only grow upwards.

      // Apply height blend to the ramps AFTER painting cliffs.
      int blendIdx = rmAreaAddHeightBlend(plateauID, cBlendCliffRamp, cFilter3x3Gaussian, 10, 10, false, true);
      // Make sure we only extend the buffer to tiles that are passable (= non-side tiles).
      rmAreaAddHeightBlendExpansionConstraint(plateauID, blendIdx, vDefaultAvoidImpassableLand);
      // Also apply some normal blending inside of the cliff for additional smoothness.
      rmAreaAddHeightBlend(plateauID, cBlendCliffInside, cFilter3x3Gaussian, 0, 1, false);

      rmAreaSetCliffType(plateauID, cCliffGreekGrass);
      rmAreaSetCliffRampSteepness(plateauID, 3.0);
      rmAreaSetCliffSideRadius(plateauID, 1, 1);
      // Ramp left of the player.
      rmAreaAddCliffRampAtAngle(plateauID, 0.06, vPlayerAngles[p] - degToRad(112.5));
      // Ramp in front of the player.
      rmAreaAddCliffRampAtAngle(plateauID, 0.06, vPlayerAngles[p] + degToRad(180.0));  // Following the player angle.
      // Ramp right of the player.
      rmAreaAddCliffRampAtAngle(plateauID, 0.06, vPlayerAngles[p] + degToRad(112.5));
      rmAreaSetCliffEmbellishmentDensity(plateauID, 0.5);

      rmAreaAddConstraint(plateauID, plateauAvoidPlateau);
      rmAreaSetConstraintBuffer(plateauID, 0.0, 20.0); // 0-10 tiles.
      rmAreaAddToClass(plateauID, plateauClassID);
   }

   rmAreaBuildAll();

   rmSetProgress(0.2);

   // Settlements and towers.
   placeStartingTownCenters();

   // Starting towers.
   int towerAvoidTower = rmCreateTypeDistanceConstraint(cUnitTypeSentryTower, 10.0);
   int towerForceNearImpassableLand = rmCreatePassabilityMaxDistanceConstraint(cPassabilityLand, false, 3.0);

   // Hacky way to place them on the plateaus near the edge and ramps.
   for(int i = 1; i <= cNumberPlayers; i++)
   {
      int p = vDefaultTeamPlayerOrder[i];

      int plateauID = rmAreaGetID(plateauName + " " + p);
      int towerAvoidRamp = rmCreateCliffRampDistanceConstraint(plateauID, 1.0);
      int towerForceNearRamp = rmCreateCliffRampMaxDistanceConstraint(plateauID, 3.0);

      int startingTowerID = rmObjectDefCreate("starting tower " + p);
      rmObjectDefAddItem(startingTowerID, cUnitTypeSentryTower, 1);
      rmObjectDefAddConstraint(startingTowerID, vDefaultAvoidImpassableLand);
      rmObjectDefAddConstraint(startingTowerID, forceOnPlateau);
      rmObjectDefAddConstraint(startingTowerID, towerAvoidRamp);
      rmObjectDefAddConstraint(startingTowerID, towerForceNearRamp);
      rmObjectDefAddConstraint(startingTowerID, towerForceNearImpassableLand);
      rmObjectDefAddConstraint(startingTowerID, towerAvoidTower);

      rmObjectDefPlaceInArea(startingTowerID, p, plateauID, 6);
   }

   rmSetProgress(0.3);

   // Settlements.
   int firstSettlementID = rmObjectDefCreate("first settlement");
   rmObjectDefAddItem(firstSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidImpassableLand);
   rmObjectDefAddConstraint(firstSettlementID, createTownCenterConstraint(35.0));
   
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(firstSettlementID, false, 1, 30.0, 60.0, cCloseSettlementDist);
   }
   else
   {
      addObjectLocsPerPlayer(firstSettlementID, false, 1, 30.0, 60.0, cCloseSettlementDist);
   }
   
   int secondSettlementID = rmObjectDefCreate("second settlement");
   rmObjectDefAddItem(secondSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidImpassableLand);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidKotH);
   rmObjectDefAddConstraint(secondSettlementID, avoidPlateau);
   
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(secondSettlementID, false, 1, 60.0, 120.0, cSettlementDist1v1, cBiasAggressive);
   }
   else
   {
      addObjectLocsPerPlayer(secondSettlementID, false, 1, 80.0, 140.0, 60.0, cBiasForward | cBiasAggressive);
   }
   
   // Other map sizes settlements.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int bonusSettlementID = rmObjectDefCreate("bonus settlement");
      rmObjectDefAddItem(bonusSettlementID, cUnitTypeSettlement, 1);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidEdge);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidImpassableLand);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidKotH);
      rmObjectDefAddConstraint(bonusSettlementID, avoidPlateau);
      addObjectLocsPerPlayer(bonusSettlementID, false, 1 * getMapAreaSizeFactor(), 90.0, -1.0, 100.0);
   }
   
   generateLocs("settlement locs");
   
   rmSetProgress(0.4);

   // Starting objects.
   // Starting gold.
   int startingGoldID = rmObjectDefCreate("starting gold");
   rmObjectDefAddItem(startingGoldID, cUnitTypeMineGoldMedium, 1);
   rmObjectDefAddConstraint(startingGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(startingGoldID, forceOnPlateau);
   addObjectLocsPerPlayer(startingGoldID, false, 1, 20.0, 20.0, cStartingObjectAvoidanceMeters);

   generateLocs("starting gold locs");
   
   // Berries.
   int startingBerriesID = rmObjectDefCreate("starting berries");
   rmObjectDefAddItem(startingBerriesID, cUnitTypeBerryBush, xsRandInt(6, 10), cBerryClusterRadius);
   rmObjectDefAddItem(startingBerriesID, cUnitTypePlantGreekGrass, xsRandInt(2, 3), 4.0);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidImpassableLand);
   rmObjectDefAddConstraint(startingBerriesID, forceOnPlateau);
   rmObjectDefAddConstraint(startingBerriesID, rmCreateTerrainTypeDistanceConstraint(cTerrainGreekRoad1, 10.0));
   addObjectLocsPerPlayer(startingBerriesID, false, 1, 25.0, 25.0, cStartingObjectAvoidanceMeters);

   // Starting hunt, reduced range to account for not having typical starting towers.
   int startingHuntID = rmObjectDefCreate("starting hunt");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeDeer, xsRandInt(8, 10));
   }
   else
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeBoar, xsRandInt(4, 5));
   }
   rmObjectDefAddConstraint(startingHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidImpassableLand);
   addObjectLocsPerPlayer(startingHuntID, false, 1, 22.0, 22.0, cStartingObjectAvoidanceMeters);

   // Chicken.
   int startingChickenID = rmObjectDefCreate("starting chicken");
   rmObjectDefAddItem(startingChickenID, cUnitTypeChicken, xsRandInt(6, 10));
   rmObjectDefAddConstraint(startingChickenID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(startingChickenID, forceOnPlateau);
   addObjectLocsPerPlayer(startingChickenID, false, 1, 25.0, 25.0, cStartingObjectAvoidanceMeters);

   // Herdables.
   int startingHerdID = rmObjectDefCreate("starting herd");
   rmObjectDefAddItem(startingHerdID, cUnitTypeCow, xsRandInt(2, 4));
   rmObjectDefAddConstraint(startingHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(startingHerdID, forceOnPlateau);
   // More limited due to forest and cliffs, so increase the range.
   addObjectLocsPerPlayer(startingHerdID, true, 1, 20.0, 30.0, cStartingObjectAvoidanceMeters);

   generateLocs("starting food locs");

   rmSetProgress(0.5);

   // Gold.
   // Medium gold.
   int closeGoldID = rmObjectDefCreate("close gold");
   rmObjectDefAddItem(closeGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(closeGoldID, rmCreateTypeDistanceConstraint(cUnitTypeSentryTower, 16.0));
   rmObjectDefAddConstraint(closeGoldID, forceOnPlateau);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeGoldID, false, 1, 45.0, 90.0, 0.0, cBiasForward);
   }
   else
   {
      addObjectLocsPerPlayer(closeGoldID, false, 1, 45.0, 90.0, 0.0);
   }

   generateLocs("medium gold locs");

   // Bonus gold.
   float avoidGoldMeters = 50.0;

   int bonusGoldID = rmObjectDefCreate("bonus gold");
   rmObjectDefAddItem(bonusGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(bonusGoldID, avoidPlateau);
   rmObjectDefAddConstraint(bonusGoldID, rmCreateTypeDistanceConstraint(cUnitTypeSentryTower, 16.0));
   addObjectDefPlayerLocConstraint(bonusGoldID, 65.0);

   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusGoldID, false, xsRandInt(3, 4) * getMapAreaSizeFactor(), 65.0, -1.0, avoidGoldMeters);
   }
   else
   {
      addObjectLocsPerPlayer(bonusGoldID, false, xsRandInt(2, 3) * getMapAreaSizeFactor(), 65.0, -1.0, avoidGoldMeters);
   }

   generateLocs("far gold locs");

   rmSetProgress(0.6);

   // Hunt.
   float avoidHuntMeters = 40.0;

   // Far hunt.
   int numFarHunt = xsRandInt(2, 3);

   for(int i = 0; i < numFarHunt; i++)
   {
      float farHuntFloat = xsRandFloat(0.0, 1.0);
      int farHuntID = rmObjectDefCreate("far hunt " + i);
      if(farHuntFloat < 1.0 / 3.0)
      {
         rmObjectDefAddItem(farHuntID, cUnitTypeDeer, xsRandInt(7, 9));
      }
      else if(farHuntFloat < 2.0 / 3.0)
      {
         rmObjectDefAddItem(farHuntID, cUnitTypeBoar, xsRandInt(3, 5));
      }
      else
      {
         rmObjectDefAddItem(farHuntID, cUnitTypeAurochs, xsRandInt(3, 4));
      }
      rmObjectDefAddConstraint(farHuntID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(farHuntID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(farHuntID, vDefaultFoodAvoidImpassableLand);
      rmObjectDefAddConstraint(farHuntID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(farHuntID, vDefaultAvoidSettlementRange);
      rmObjectDefAddConstraint(farHuntID, avoidPlateau);
      addObjectDefPlayerLocConstraint(farHuntID, 70.0);
      addObjectLocsPerPlayer(farHuntID, false, 1, 70.0, -1.0, avoidHuntMeters);
   }

   // Other map sizes hunt.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int largeMapHuntID = rmObjectDefCreate("large map hunt");
      float largeHuntFloat = xsRandFloat(0.0, 1.0);
      if(largeHuntFloat < 1.0 / 3.0)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeDeer, xsRandInt(7, 12));
      }
      else if(largeHuntFloat < 2.0 / 3.0)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeBoar, xsRandInt(3, 6));
      }
      else
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeAurochs, xsRandInt(3, 6));
      }

      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidImpassableLand);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidSettlementRange);
      rmObjectDefAddConstraint(largeMapHuntID, avoidPlateau);
      addObjectDefPlayerLocConstraint(largeMapHuntID, 100.0);
      addObjectLocsPerPlayer(largeMapHuntID, false, xsRandInt(1, 2) * getMapSizeBonusFactor(), 100.0, -1.0, avoidHuntMeters);
   }

   generateLocs("hunt locs");

   rmSetProgress(0.7);

   // Berries.
   float avoidBerriesMeters = 50.0;
  
   int berriesID = rmObjectDefCreate("berries");
   rmObjectDefAddItem(berriesID, cUnitTypeBerryBush, xsRandInt(7, 10), cBerryClusterRadius);
   rmObjectDefAddItem(berriesID, cUnitTypePlantGreekGrass, xsRandInt(2, 3), 4.0);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(berriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(berriesID, vDefaultBerriesAvoidImpassableLand);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(berriesID, avoidPlateau);
   addObjectDefPlayerLocConstraint(berriesID, 80.0);
   addObjectLocsPerPlayer(berriesID, false, 1 * getMapSizeBonusFactor(), 80.0, -1.0, avoidBerriesMeters);

   generateLocs("berries locs");

   // Herdables.
   float avoidHerdMeters = 25.0;
  
   int closeHerdID = rmObjectDefCreate("close herd");
   rmObjectDefAddItem(closeHerdID, cUnitTypeCow, xsRandInt(2, 3));
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidTowerLOS);
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddConstraint(closeHerdID, forceOnPlateau);
      addObjectLocsPerPlayer(closeHerdID, false, 1, 35.0, 65.0, avoidHerdMeters);
   }
   else
   {
      rmObjectDefAddConstraint(closeHerdID, avoidPlateau);
      addObjectLocsPerPlayer(closeHerdID, false, 1, 60.0, 100.0, avoidHerdMeters);
   }

   int bonusHerdID = rmObjectDefCreate("bonus herd");
   rmObjectDefAddItem(bonusHerdID, cUnitTypeCow, xsRandInt(1, 2));
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHerdID, avoidPlateau);
   addObjectDefPlayerLocConstraint(bonusHerdID, 70.0);
   addObjectLocsPerPlayer(bonusHerdID, false, xsRandInt(2, 3) * getMapSizeBonusFactor(), 70.0, -1.0, avoidHerdMeters);

   generateLocs("herd locs");

   // Predators.
   float avoidPredatorMeters = 50.0;
  
   int predatorID = rmObjectDefCreate("predator");
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
   rmObjectDefAddConstraint(predatorID, avoidPlateau);
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
   rmObjectDefAddConstraint(relicID, avoidPlateau);
   addObjectDefPlayerLocConstraint(relicID, 80.0);
   addObjectLocsPerPlayer(relicID, false, 2 * getMapAreaSizeFactor(), 80.0, -1.0, avoidRelicMeters);

   generateLocs("relic locs");

   // Stragglers.
   placeStartingStragglers(cUnitTypeTreeOak);

   rmSetProgress(0.8);
   
   // Forests.
   float avoidForestMeters = 35.0;

   int playerForestDefID = rmAreaDefCreate("player forest");
   rmAreaDefSetSize(playerForestDefID, rmTilesToAreaFraction(60), rmTilesToAreaFraction(90));
   rmAreaDefSetForestType(playerForestDefID, cForestGreekMediterraneanLush);
   rmAreaDefSetAvoidSelfDistance(playerForestDefID, avoidForestMeters);
   rmAreaDefAddConstraint(playerForestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(playerForestDefID, vDefaultAvoidImpassableLand10);
   rmAreaDefAddConstraint(playerForestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddConstraint(playerForestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(playerForestDefID, forceOnPlateau);

   // Starting forests.
   if(gameIs1v1() == true)
   {
      addSimAreaLocsPerPlayerPair(playerForestDefID, 3, 20.0, 80.0, avoidForestMeters);
   }
   else
   {
      addAreaLocsPerPlayer(playerForestDefID, 3,  20.0, 80.0, avoidForestMeters);
   }

   generateLocs("starting forest locs");

   // Global forests.
   int globalForestDefID = rmAreaDefCreate("global forest");
   rmAreaDefSetSize(globalForestDefID, rmTilesToAreaFraction(75), rmTilesToAreaFraction(125));
   rmAreaDefSetForestType(globalForestDefID, cForestGreekMediterraneanLush);
   rmAreaDefSetAvoidSelfDistance(globalForestDefID, avoidForestMeters);
   rmAreaDefAddConstraint(globalForestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(globalForestDefID, vDefaultAvoidImpassableLand10);
   rmAreaDefAddConstraint(globalForestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddConstraint(globalForestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(globalForestDefID, avoidPlateau);

   // Avoid the owner paths to prevent forests from closing off resources.
   rmAreaDefAddConstraint(globalForestDefID, vDefaultAvoidOwnerPaths);

   // Build for each player in the team area.
   buildAreaDefInTeamAreas(globalForestDefID, 9 * getMapAreaSizeFactor());

   rmSetProgress(0.9);

   // Embellishment.
   // Gold areas.
   buildAreaUnderObjectDef(startingGoldID, cTerrainGreekGrassRocks2, cTerrainGreekGrassRocks1, 6.0);
   buildAreaUnderObjectDef(closeGoldID, cTerrainGreekGrassRocks2, cTerrainGreekGrassRocks1, 6.0);
   buildAreaUnderObjectDef(bonusGoldID, cTerrainGreekGrassRocks2, cTerrainGreekGrassRocks1, 6.0);

   // Berries areas.
   buildAreaUnderObjectDef(startingBerriesID, cTerrainGreekGrass2, cTerrainGreekGrass1, 10.0);
   buildAreaUnderObjectDef(berriesID, cTerrainGreekGrass2, cTerrainGreekGrass1, 10.0);
   
   // Random trees.
   int randomTreeID = rmObjectDefCreate("random tree");
   rmObjectDefAddItem(randomTreeID, cUnitTypeTreeOak, 1);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidImpassableLand);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidTree);
   rmObjectDefPlaceAnywhere(randomTreeID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

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

   int rockMediumID = rmObjectDefCreate("rock medium");
   rmObjectDefAddItem(rockMediumID, cUnitTypeRockGreekMedium, 1);
   rmObjectDefAddConstraint(rockMediumID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockMediumID, rmCreateTerrainTypeMaxDistanceConstraint(cTerrainGreekCliff1, 2.0));
   rmObjectDefPlaceAnywhere(rockMediumID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   // Plants.
   int plantBushID = rmObjectDefCreate("plant bush");
   rmObjectDefAddItem(plantBushID, cUnitTypePlantGreekBush, 1);
   rmObjectDefAddConstraint(plantBushID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantBushID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefPlaceAnywhere(plantBushID, 0, 20 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantShrubID = rmObjectDefCreate("plant shrub");
   rmObjectDefAddItem(plantShrubID, cUnitTypePlantGreekShrub, 1);
   rmObjectDefAddConstraint(plantShrubID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantShrubID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefPlaceAnywhere(plantShrubID, 0, 20 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantGrassID = rmObjectDefCreate("plant grass");
   rmObjectDefAddItem(plantGrassID, cUnitTypePlantGreekGrass, 1);
   rmObjectDefAddConstraint(plantGrassID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantGrassID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(plantGrassID, vDefaultAvoidEdge);
   rmObjectDefPlaceAnywhere(plantGrassID, 0, 20 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantFernID = rmObjectDefCreate("plant fern");
   rmObjectDefAddItem(plantFernID, cUnitTypePlantGreekFern, 1);
   rmObjectDefAddConstraint(plantFernID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantFernID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(plantFernID, vDefaultAvoidEdge);
   rmObjectDefPlaceAnywhere(plantFernID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantWeedsID = rmObjectDefCreate("plant weeds");
   rmObjectDefAddItem(plantWeedsID, cUnitTypePlantGreekWeeds, 1);
   rmObjectDefAddConstraint(plantWeedsID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantWeedsID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(plantWeedsID, vDefaultAvoidEdge);
   rmObjectDefPlaceAnywhere(plantWeedsID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());

   // Logs.
   int logID = rmObjectDefCreate("log");
   rmObjectDefAddItem(logID, cUnitTypeRottingLog, 1);
   rmObjectDefAddConstraint(logID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(logID, vDefaultAvoidImpassableLand);
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
