include "lib2/rm_core.xs";
include "lib2/rm_connections.xs";

void generate()
{
   rmSetProgress(0.0);

   // Define mixes.
   int baseMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.125, 5, 0.5);
   // rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseSnowRocks2, 8.0);
   // rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseSnowRocks1, 4.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseSnow1, 4.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseSnow2, 2.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseSnow3, 4.0);
   
   // Map size and terrain init.
   int axisTiles = getScaledAxisTiles(136);

   float axisMultiplier = 0.9;
   int longerAxis = getRandomXZAxis(0.5);

    // Set size.
   float sclr=6.9;
   if(cMapSizeCurrent == 1)
   {
      sclr=8.4;
   }
   

   if(longerAxis == cAxisX)
   {
      rmSetMapSize(axisMultiplier * axisTiles * sclr , (1.0 / axisMultiplier) * axisTiles * sclr);
   }
   else if(longerAxis == cAxisZ)
   {
      rmSetMapSize((1.0 / axisMultiplier) * axisTiles * sclr, axisMultiplier * axisTiles * sclr);
   }
   
   rmInitializeLand(cTerrainNorseCliffSnow1, 10.0);

   // Player placement.
   rmSetTeamSpacingModifier(0.8);
   rmPlacePlayersOnSquare(0.3, 0.3);

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCivFromCulture(cCultureNorse);

   // Lighting.
   rmSetLighting(cLightingSetRmJotunheim01);

   rmSetProgress(0.1);

   // Global elevation.
   rmAddGlobalHeightNoise(cNoiseFractalSum, 20.0, 0.15, 5, 0.5);

   // Create player areas to restrict team areas (in case of weird setups like 1v11).
   // Player areas.
   int playerIslandClassID = rmClassCreate();
   int avoidPlayerIsland = rmCreateClassDistanceConstraint(playerIslandClassID, 1.0);
   int playerIslandAvoidPlayerIsland = rmCreateClassDistanceConstraint(playerIslandClassID, 1.0);

   for(int i = 1; i <= cNumberPlayers; i++)
   {
      int playerIslandID = rmAreaCreate("player island " + i);
      rmAreaSetSize(playerIslandID, 1.0);
      rmAreaSetLocPlayer(playerIslandID, i);

      rmAreaSetCoherence(playerIslandID, 0.0);

      rmAreaAddConstraint(playerIslandID, playerIslandAvoidPlayerIsland);
      rmAreaAddToClass(playerIslandID, playerIslandClassID);
   }

   rmAreaBuildAll();

   rmSetProgress(0.2);

   int snowAreaDefID = rmAreaDefCreate("snow area");
   rmAreaDefSetMix(snowAreaDefID, baseMixID);
   rmAreaDefSetCliffType(snowAreaDefID, cCliffNorseSnow);
   rmAreaDefSetCliffSideRadius(snowAreaDefID, 1, 0);
   rmAreaDefSetCliffEmbellishmentDensity(snowAreaDefID, 0.5);
   rmAreaDefSetCliffLayerPaint(snowAreaDefID, cCliffLayerOuterSideClose, false);
   rmAreaDefSetCliffLayerPaint(snowAreaDefID, cCliffLayerOuterSideFar, false);
   rmAreaDefSetHeight(snowAreaDefID, 0.0);
   rmAreaDefAddHeightBlend(snowAreaDefID, cBlendEdge, cFilter5x5Gaussian, 5);

   // Team areas.
   int[] teamAreaIDs = new int(0, 0); // Empty array, team area IDs for connections go here.
   int teamIslandClassID = rmClassCreate();
   int teamIslandAvoidTeamIsland = rmCreateClassDistanceConstraint(teamIslandClassID, 1.0);
   int teamIslandAvoidEdge = createSymmetricBoxConstraint(rmXTileIndexToFraction(4), rmXTileIndexToFraction(4));
   int forceInTeamAreas = rmCreateClassMaxDistanceConstraint(teamIslandClassID, 0.0);

   for(int i = 1; i <= cNumberTeams; i++)
   {
      int teamID = vTeamOrderPlaced[i];

      int teamIslandID = rmAreaDefCreateArea(snowAreaDefID, "team island " + teamID);
      rmAreaSetSize(teamIslandID, 1.0);
      rmAreaSetLocTeam(teamIslandID, teamID);

      for(int j = 1; j <= cNumberPlayers; j++)
      {
         if(rmGetPlayerTeam(j) != teamID)
         {
            // Avoid player areas that don't belong to our team.
            rmAreaAddConstraint(teamIslandID, rmCreateAreaDistanceConstraint(rmAreaGetID("player island " + j), 0.1));
         }
      }
      rmAreaAddConstraint(teamIslandID, teamIslandAvoidTeamIsland);
      rmAreaAddConstraint(teamIslandID, teamIslandAvoidEdge);
      rmAreaSetConstraintBuffer(teamIslandID, 0.0, 14.0);

      rmAreaAddToClass(teamIslandID, teamIslandClassID);

      teamAreaIDs.add(teamIslandID);
   }

   rmAreaBuildAll();

   // KotH.
   if (gameIsKotH() == true)
   {
      int islandKotHID = rmAreaDefCreateArea(snowAreaDefID, "koth island");
      rmAreaSetSize(islandKotHID, rmTilesToAreaFraction(361)); // 19x19.
      rmAreaSetLoc(islandKotHID, cCenterLoc);
      rmAreaSetCoherence(islandKotHID, 0.5);
      rmAreaSetCoherenceSquare(islandKotHID, true);
      
      rmAreaAddToClass(islandKotHID, vKotHClassID);

      rmAreaBuild(islandKotHID);
   }

   rmSetProgress(0.3);

   // By popular demand go for the variant with only one connection to each adjacent team.
   // Path.
   float pathWidth = 25.0;

   int pathDefID = rmPathDefCreate("team connection path");
   // No params to set here, we want direct paths.

   // Areas.
   int pathAreaDefID = rmAreaDefCreate("team connection area");
   rmAreaDefSetMix(pathAreaDefID, baseMixID);

   rmAreaDefSetHeight(pathAreaDefID, 0.0);
   rmAreaDefAddHeightConstraint(pathAreaDefID, rmCreatePassabilityMaxDistanceConstraint(cPassabilityLand, false, 0.0));
   rmAreaDefAddHeightBlend(pathAreaDefID, cBlendAll, cFilter5x5Gaussian);
   
   rmAreaDefSetCliffType(pathAreaDefID, cCliffNorseSnow);
   rmAreaDefSetCliffSideRadius(pathAreaDefID, 0, 2);
   rmAreaDefSetCliffLayerEmbellishmentDensity(pathAreaDefID, cCliffLayerInnerSideClose, 0.5);
   rmAreaDefSetCliffLayerEmbellishmentDensity(pathAreaDefID, cCliffLayerInnerSideFar, 0.5);
   rmAreaDefSetCliffLayerPaint(pathAreaDefID, cCliffLayerOuterSideClose, false);
   rmAreaDefSetCliffLayerPaint(pathAreaDefID, cCliffLayerOuterSideFar, false);

   rmAreaDefAddCliffEdgeConstraint(pathAreaDefID, cCliffEdgeIgnored, vDefaultAvoidImpassableLand);

   // Create the connections at the area origins and wrap around (also connecting the last to the first team).
   int wrap = (cNumberTeams <= 2) ? cAreaConnectionTypeSeq : cAreaConnectionTypeWrap;
   createAreaConnections("team connection", pathDefID, pathAreaDefID, teamAreaIDs, pathWidth, 10.0, 0.0, wrap);
   
   if(gameIsKotH() == true)
   {
      createAreaToLocConnections("koth connection", pathDefID, pathAreaDefID, teamAreaIDs, cCenterLoc, 15.0, 10.0);
   }

   rmSetProgress(0.4);

   // KotH.
   placeKotHObjects();

   // Settlements and towers.
   placeStartingTownCenters();

   // Starting towers.
   int startingTowerID = rmObjectDefCreate("starting tower");
   rmObjectDefAddItem(startingTowerID, cUnitTypeSentryTower, 1);
   rmObjectDefAddConstraint(startingTowerID, vDefaultAvoidAll);
   rmObjectDefAddConstraint(startingTowerID, vDefaultAvoidImpassableLand8);
   addObjectLocsPerPlayer(startingTowerID, true, 4, cStartingTowerMinDist, cStartingTowerMaxDist, cStartingTowerAvoidanceMeters);
   generateLocs("starting tower locs");

   // Settlements.
   float avoidSettlementMeters = 60.0;

   int firstSettlementID = rmObjectDefCreate("first settlement");
   rmObjectDefAddItem(firstSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidImpassableLand);

   int secondSettlementID = rmObjectDefCreate("second settlement");
   rmObjectDefAddItem(secondSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidImpassableLand);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidKotH);

   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(firstSettlementID, false, 1, 60.0, 80.0, avoidSettlementMeters, cBiasBackward);
      addSimObjectLocsPerPlayerPair(secondSettlementID, false, 1, 80.0, 100.0, avoidSettlementMeters, cBiasForward);
   }
   else
   {
      // TODO Center avoidance?
      addObjectLocsPerPlayer(firstSettlementID, false, 1, 60.0, 80.0, avoidSettlementMeters, cBiasBackward | cBiasAllyInside);
      addObjectLocsPerPlayer(secondSettlementID, false, 1, 80.0, 120.0, avoidSettlementMeters, cBiasAggressive | cBiasAllyInside);
   }
   
   // Other map sizes settlements.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int bonusSettlementID = rmObjectDefCreate("bonus settlement");
      rmObjectDefAddItem(bonusSettlementID, cUnitTypeSettlement, 1);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidEdge);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidImpassableLand);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidKotH);
      addObjectLocsPerPlayer(bonusSettlementID, false, 1 * getMapAreaSizeFactor(), 90.0, -1.0, 100.0);
   }

   generateLocs("settlement locs");

   rmSetProgress(0.5);

   // Starting objects.
   // Starting gold.
   int startingGoldID = rmObjectDefCreate("starting gold");
   rmObjectDefAddItem(startingGoldID, cUnitTypeMineGoldMedium, 1);
   rmObjectDefAddConstraint(startingGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(startingGoldID, vDefaultStartingGoldAvoidTower);
   rmObjectDefAddConstraint(startingGoldID, vDefaultForceStartingGoldNearTower);
   addObjectLocsPerPlayer(startingGoldID, false, 1, cStartingGoldMinDist, cStartingGoldMaxDist, cStartingObjectAvoidanceMeters, cBiasNotAggressive);

   generateLocs("starting gold locs");

   // Berries.
   int startingBerriesID = rmObjectDefCreate("starting berries");
   rmObjectDefAddItem(startingBerriesID, cUnitTypeBerryBush, xsRandInt(5, 9), cBerryClusterRadius);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidImpassableLand);
   addObjectLocsPerPlayer(startingBerriesID, false, 1, cStartingBerriesMinDist, cStartingBerriesMaxDist, cStartingObjectAvoidanceMeters);

   // Starting hunt.
   float startingHuntFloat = xsRandFloat(0.0, 1.0);
   int startingHuntID = rmObjectDefCreate("starting hunt");
   if(startingHuntFloat < 1.0 / 3.0)
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeCaribou, xsRandInt(3, 6));
      rmObjectDefAddItem(startingHuntID, cUnitTypeElk, xsRandInt(3, 6));
   }
   else if(startingHuntFloat < 2.0 / 3.0)
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeElk, xsRandInt(4, 8));
   }
   else
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeCaribou, xsRandInt(4, 8));
   }
   rmObjectDefAddConstraint(startingHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(startingHuntID, vDefaultForceInTowerLOS);
   addObjectLocsPerPlayer(startingHuntID, false, 1, cStartingHuntMinDist, cStartingHuntMaxDist, cStartingObjectAvoidanceMeters);

   // Chicken.
   int startingChickenID = rmObjectDefCreate("starting chicken");

   int chickenNum = xsRandInt(6, 10);

   // Set chicken variation, excluding whites, as they are hard to see on snow maps.
   for (int i = 0; i < chickenNum; i++)
   {
      rmObjectDefAddItem(startingChickenID, cUnitTypeChicken, 1);
      rmObjectDefSetItemVariation(startingChickenID, i, xsRandInt(cChickenVariationBrown, cChickenVariationBlack));
   }
   rmObjectDefAddConstraint(startingChickenID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidImpassableLand);
   addObjectLocsPerPlayer(startingChickenID, false, 1, cStartingChickenMinDist, cStartingChickenMaxDist, cStartingObjectAvoidanceMeters);

   // Herdables.
   int startingHerdID = rmObjectDefCreate("starting herd");
   rmObjectDefAddItem(startingHerdID, cUnitTypeCow, xsRandInt(1, 4));
   rmObjectDefAddConstraint(startingHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidImpassableLand);
   addObjectLocsPerPlayer(startingHerdID, true, 1, cStartingHerdMinDist, cStartingHerdMaxDist);

   generateLocs("starting food locs");

   rmSetProgress(0.6);

   // Gold.
   float avoidGoldMeters = 50.0;

   // Close gold.
   int closeGoldID = rmObjectDefCreate("close gold");
   rmObjectDefAddItem(closeGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(closeGoldID, forceInTeamAreas);
   addObjectDefPlayerLocConstraint(closeGoldID, 50.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeGoldID, false, 1, 50.0, 70.0, avoidGoldMeters);
   }
   else
   {
      addObjectLocsPerPlayer(closeGoldID, false, 1, 50.0, -1.0, avoidGoldMeters);
   }

   // Bonus gold.
   int bonusGoldID = rmObjectDefCreate("bonus gold");
   rmObjectDefAddItem(bonusGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(bonusGoldID, forceInTeamAreas);
   addObjectDefPlayerLocConstraint(bonusGoldID, 70.0);

   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusGoldID, false, 2 * getMapSizeBonusFactor(), 60.0, -1.0, avoidGoldMeters);
   }
   else
   {
      addObjectLocsPerPlayer(bonusGoldID, false, 2 * getMapSizeBonusFactor(), 60.0, -1.0, avoidGoldMeters);
   }

   generateLocs("gold locs");

   rmSetProgress(0.6);

   // Hunt.
   float avoidHuntMeters = 50.0;

   // Close hunt.
   int closeHuntID = rmObjectDefCreate("close hunt");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeCaribou, xsRandInt(4, 8));
   }
   else
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeElk, xsRandInt(4, 8));
   }
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(closeHuntID, forceInTeamAreas);
   addObjectDefPlayerLocConstraint(closeHuntID, 55.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeHuntID, false, 1, 60.0, 80.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(closeHuntID, false, 1, 60.0, 80.0, avoidHuntMeters);
   }

   // Bonus hunt.
   float bonusHuntFloat = xsRandFloat(0.0, 1.0);
   int bonusHuntID = rmObjectDefCreate("bonus hunt");
   if(bonusHuntFloat < 1.0 / 3.0)
   {
      rmObjectDefAddItem(bonusHuntID, cUnitTypeAurochs, xsRandInt(3, 5));
   }
   else if(bonusHuntFloat < 2.0 / 3.0)
   {
      rmObjectDefAddItem(bonusHuntID, cUnitTypeBoar, xsRandInt(3, 5));
   }
   else
   {
      rmObjectDefAddItem(bonusHuntID, cUnitTypeElk, xsRandInt(3, 6));
      rmObjectDefAddItem(bonusHuntID, cUnitTypeCaribou, xsRandInt(3, 6));
   }
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(bonusHuntID, forceInTeamAreas);
   addObjectDefPlayerLocConstraint(bonusHuntID, 60.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusHuntID, false, 1, 60.0, -1.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(bonusHuntID, false, 1, 60.0, -1.0, avoidHuntMeters);
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
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeAurochs, xsRandInt(2, 4));
      }
      else
      {
         rmObjectDefAddItem(bonusHuntID, cUnitTypeElk, xsRandInt(3, 6));
         rmObjectDefAddItem(bonusHuntID, cUnitTypeCaribou, xsRandInt(3, 6));
      }

      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidImpassableLand);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidSettlementRange);
      rmObjectDefAddConstraint(largeMapHuntID, forceInTeamAreas);
      addObjectDefPlayerLocConstraint(largeMapHuntID, 80.0);
      addObjectLocsPerPlayer(largeMapHuntID, false, 2 * getMapSizeBonusFactor(), 80.0, -1.0, avoidHuntMeters);
   }

   generateLocs("hunt locs");

   rmSetProgress(0.7);

   // No additional berries on this map.

   // Herdables.
   float avoidHerdMeters = 50.0;

   int closeHerdID = rmObjectDefCreate("close herd");
   rmObjectDefAddItem(closeHerdID, cUnitTypeCow, xsRandInt(1, 2));
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHerdID, forceInTeamAreas);
   addObjectLocsPerPlayer(closeHerdID, false, xsRandInt(1, 2), 50.0, 70.0, avoidHerdMeters);

   int bonusHerdID = rmObjectDefCreate("bonus herd");
   rmObjectDefAddItem(bonusHerdID, cUnitTypeCow, xsRandInt(1, 3));
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHerdID, forceInTeamAreas);
   addObjectLocsPerPlayer(bonusHerdID, false, 1 * getMapSizeBonusFactor(), 70.0, -1.0, avoidHerdMeters);

   generateLocs("herd locs");

   // Predators.
   float avoidPredatorMeters = 50.0;

   int predatorID = rmObjectDefCreate("predator");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(predatorID, cUnitTypeArcticWolf, xsRandInt(1, 2));
   }
   else
   {
      rmObjectDefAddItem(predatorID, cUnitTypeBear, xsRandInt(1, 3));
   }
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(predatorID, forceInTeamAreas);
   addObjectDefPlayerLocConstraint(predatorID, 80.0);
   addObjectLocsPerPlayer(predatorID, false, xsRandInt(1, 2) * getMapAreaSizeFactor(), 70.0, -1.0, avoidPredatorMeters);

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
   rmObjectDefAddConstraint(relicID, forceInTeamAreas);
   addObjectDefPlayerLocConstraint(relicID, 70.0);
   addObjectLocsPerPlayer(relicID, false, 2 * getMapAreaSizeFactor(), 60.0, -1.0, avoidRelicMeters);

   generateLocs("relic locs");

   rmSetProgress(0.8);

   // Forests.
   float avoidForestMeters = 30.0;

   int forestDefID = rmAreaDefCreate("forest");
   rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(80), rmTilesToAreaFraction(120));
   rmAreaDefSetForestType(forestDefID, cForestNorsePineSnow);
   rmAreaDefSetAvoidSelfDistance(forestDefID, avoidForestMeters);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidImpassableLand10);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddConstraint(forestDefID, forceInTeamAreas);

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
   buildAreaUnderObjectDef(startingGoldID, cTerrainNorseSnowRocks2, cTerrainNorseSnowRocks1, 10.0);
   buildAreaUnderObjectDef(closeGoldID, cTerrainNorseSnowRocks2, cTerrainNorseSnowRocks1, 10.0);
   buildAreaUnderObjectDef(bonusGoldID, cTerrainNorseSnowRocks2, cTerrainNorseSnowRocks1, 10.0);

   // Berries areas.
   buildAreaUnderObjectDef(startingBerriesID, cTerrainNorseSnowGrass2, cTerrainNorseSnowGrass1, 10.0);

   // Random trees.
   int randomTreeID = rmObjectDefCreate("random tree");
   rmObjectDefAddItem(randomTreeID, cUnitTypeTreePineSnow, 1);
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
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefPlaceAnywhere(rockTinyID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());

   int rockSmallID = rmObjectDefCreate("rock small");
   rmObjectDefAddItem(rockSmallID, cUnitTypeRockNorseSmall, 1);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefPlaceAnywhere(rockSmallID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());

   // Plants.
   int plantGrassID = rmObjectDefCreate("plant shrub");
   rmObjectDefAddItem(plantGrassID, cUnitTypePlantSnowGrass, 1);
   rmObjectDefAddConstraint(plantGrassID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantGrassID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefPlaceAnywhere(plantGrassID, 0, 40 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantFernID = rmObjectDefCreate("plant fern");
   rmObjectDefAddItemRange(plantFernID, cUnitTypePlantSnowFern, 1, 2, 0.0, 4.0);
   rmObjectDefAddConstraint(plantFernID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantFernID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefPlaceAnywhere(plantFernID, 0, 30 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantWeedsID = rmObjectDefCreate("plant weeds");
   rmObjectDefAddItemRange(plantWeedsID, cUnitTypePlantSnowWeeds, 1, 3, 0.0, 4.0);
   rmObjectDefAddConstraint(plantWeedsID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantWeedsID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefPlaceAnywhere(plantWeedsID, 0, 20 * cNumberPlayers * getMapAreaSizeFactor());

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeHawk, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   int snowVFXID = rmObjectDefCreate("snow");
   rmObjectDefAddItem(snowVFXID, cUnitTypeVFXSnow, 1);
   rmObjectDefPlaceAnywhere(snowVFXID, 0, 20);

   rmSetProgress(1.0);
}
