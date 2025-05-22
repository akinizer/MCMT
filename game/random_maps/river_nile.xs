include "lib2/rm_core.xs";

void generate()
{
   rmSetProgress(0.0);

   // Define mixes.
   int baseMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.15, 1);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptGrassDirt2, 1.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptGrassDirt1, 1.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptGrass1, 2.0);

   // Define mixes.
   int outerMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(outerMixID, cNoiseFractalSum, 0.075, 4, 0.5);
   rmCustomMixAddPaintEntry(outerMixID, cTerrainEgyptSand3, 4.0);
   rmCustomMixAddPaintEntry(outerMixID, cTerrainEgyptSand2, 2.0);
   rmCustomMixAddPaintEntry(outerMixID, cTerrainEgyptSand1, 4.0);

   // Water overrides.
   rmWaterTypeAddBeachLayer(cWaterEgyptRiverNile, cTerrainEgyptGrassRocks2, 2.0, 2.0);
   rmWaterTypeAddBeachLayer(cWaterEgyptRiverNile, cTerrainEgyptGrassRocks1, 4.0, 2.0);
   rmWaterTypeAddBeachLayer(cWaterEgyptRiverNile, cTerrainEgyptGrassDirt1, 6.0, 2.0);

   // Map size and terrain init.
   int axisTiles = getScaledAxisTiles(152);

   float axisMultiplier = 0.85;
   int longerAxis = getRandomXZAxis(0.5);

   // Set size.
   float sclr=6.9;
   if(cMapSizeCurrent == 1)
   {
      sclr=8.4;
   }

   if(longerAxis == cAxisX)
   {
      rmSetMapSize(axisMultiplier * axisTiles * sclr, (1.0 / axisMultiplier) * axisTiles * sclr);
   }
   else if(longerAxis == cAxisZ)
   {
      rmSetMapSize((1.0 / axisMultiplier) * axisTiles * sclr, axisMultiplier * axisTiles * sclr);
   }
   
   rmInitializeWater(cWaterEgyptRiverNile);

   rmSetProgress(0.1);
   
   // Player placement.
   rmSetTeamSpacingModifier(0.85);
   rmPlacePlayersOnSquare(0.35, 0.35);

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCivFromCulture(cCultureEgyptian);

   // KotH.
   if (gameIsKotH() == true)
   {
      int islandKotHID = rmAreaCreate("koth island");
      rmAreaSetSize(islandKotHID, rmRadiusToAreaFraction(30.0));
      rmAreaSetLoc(islandKotHID, cCenterLoc);
      //rmAreaSetMix(islandKotHID, baseMixID);

      rmAreaSetCoherence(islandKotHID, 0.5);
      rmAreaSetEdgeSmoothDistance(islandKotHID, 5);
      rmAreaSetHeight(islandKotHID, -0.99);
      rmAreaAddHeightBlend(islandKotHID, cBlendEdge, cFilter5x5Box, 10.0, 5.0);
      
      rmAreaAddToClass(islandKotHID, vKotHClassID);

      rmAreaBuild(islandKotHID);
   }

   placeKotHObjects();

   // Lighting.
   rmSetLighting(cLightingSetRmRiverNile01);

   rmSetProgress(0.2);

   // Set up constraints for the paths from player spawns to the edge.
   // By letting player areas avoid the paths of other players, we can easily prevent player areas from getting enclosed.
   // TODO Function.
   int[] playerEdgePathConstraints = new int(cNumberPlayersPlusNature, cInvalidID);
   float playerEdgePathDist = 20.0;

   for(int i = 1; i <= cNumberPlayers; i++)
   {
      int pathID = rmPathDefGetCreatedPath(vPlayerLocEdgePathDef, i - 1);
      int pathOwnerID = rmPathGetOwnerID(pathID);

      playerEdgePathConstraints[pathOwnerID] = rmCreatePathDistanceConstraint(pathID, playerEdgePathDist);
   }

   float riverWidth = 35.0 * getMapAreaSizeFactor();

   // Player areas.
   int playerIslandClassID = rmClassCreate();
   int avoidPlayerIsland = rmCreateClassDistanceConstraint(playerIslandClassID, 0.1);
   int playerIslandAvoidPlayerIsland = rmCreateClassDistanceConstraint(playerIslandClassID, riverWidth);

   for(int i = 1; i <= cNumberPlayers; i++)
   {
      int locID = vTeamPlayerLocOrderPlaced[i];
      int playerID = rmGetPlayerLocOwner(locID);

      int playerIslandID = rmAreaCreate("player island " + playerID);
      rmAreaSetSize(playerIslandID, 1.0);
      rmAreaSetLocPlayer(playerIslandID, playerID);

      // rmAreaSetBlobDistance(playerIslandID, 40.0, 80.0);
      // rmAreaSetBlobs(playerIslandID, 3, 5);

      // Never allow these to cross player edge paths that are not our own (or we might surround other areas).
      for(int j = 1; j <= cNumberPlayers; j++)
      {
         if(j == playerID)
         {
            continue;
         }

         rmAreaAddConstraint(playerIslandID, playerEdgePathConstraints[j]);
      }

      rmAreaAddConstraint(playerIslandID, playerIslandAvoidPlayerIsland);
      rmAreaAddToClass(playerIslandID, playerIslandClassID);
   }

   rmAreaBuildAll();

   rmSetProgress(0.3);

   // Team areas.
   int teamIslandClassID = rmClassCreate();
   int avoidTeamIsland = rmCreateClassDistanceConstraint(teamIslandClassID, 0.1);
   int teamIslandAvoidTeamIsland = rmCreateClassDistanceConstraint(teamIslandClassID, riverWidth);

   for(int i = 1; i <= cNumberTeams; i++)
   {
      int teamIslandID = rmAreaCreate("team island " + i);
      rmAreaSetSize(teamIslandID, 1.0);
      rmAreaSetLocTeam(teamIslandID, i);

      rmAreaSetMix(teamIslandID, baseMixID);

      rmAreaSetHeight(teamIslandID, 0.5);
      rmAreaAddHeightBlend(teamIslandID, cBlendEdge, cFilter5x5Box, 5, 5);
      rmAreaSetHeightNoise(teamIslandID, cNoiseFractalSum, 6.0, 0.015, 3, 1.0);
      rmAreaSetHeightNoiseBias(teamIslandID, 1.0); // Only grow upwards.
      rmAreaSetHeightNoiseEdgeFalloffDist(teamIslandID, 20.0);

      // Higher coherence gives smoother rivers.
      rmAreaSetEdgeSmoothDistance(teamIslandID, 5, false);

      for(int j = 1; j <= cNumberPlayers; j++)
      {
         if(rmGetPlayerTeam(j) != i)
         {
            // Avoid player areas that don't belong to our team.
            rmAreaAddConstraint(teamIslandID, rmCreateAreaDistanceConstraint(rmAreaGetID("player island " + j), riverWidth));
         }
      }
      rmAreaAddConstraint(teamIslandID, teamIslandAvoidTeamIsland);
      rmAreaAddToClass(teamIslandID, teamIslandClassID);

      vTeamAreaIDs[i] = teamIslandID;
   }

   rmAreaBuildAll();

   rmSetProgress(0.4);

   // Outer area terrain mix.
   float shoreWidth = 30.0 * sqrt(getMapAreaSizeFactor());

   int desertClassID = rmClassCreate();
   int forceInDesertArea = rmCreateClassMaxDistanceConstraint(desertClassID, 0.0);
   // Increase the width here if oyu add more (grass) layers below.
   int avoidDesertAreaEdge = rmCreateClassDistanceConstraint(desertClassID, 10.0, cClassAreaEdgeDistance);
   int avoidDesertArea = rmCreateClassDistanceConstraint(desertClassID, 1.0);

   int desertAreaAvoidWater = rmCreateWaterDistanceConstraint(true, shoreWidth);

   for(int i = 1; i <= cNumberTeams; i++)
   {
      int teamContinentMixID = rmAreaCreate("team continent mix " + i);
      rmAreaSetSize(teamContinentMixID, 1.0);

      rmAreaAddTerrainLayer(teamContinentMixID, cTerrainEgyptGrassDirt1, 0);
      rmAreaAddTerrainLayer(teamContinentMixID, cTerrainEgyptGrassDirt2, 1);
      rmAreaAddTerrainLayer(teamContinentMixID, cTerrainEgyptGrassDirt3, 2);
      rmAreaSetMix(teamContinentMixID, outerMixID);

      rmAreaAddToClass(teamContinentMixID, desertClassID);
      rmAreaAddConstraint(teamContinentMixID, desertAreaAvoidWater);
      // This is kinda stupid but reliable.
      rmAreaSetParent(teamContinentMixID, rmAreaGetID("team island " + i));
   }

   rmAreaBuildAll();

   rmSetProgress(0.5);

   // Settlements and towers.
   placeStartingTownCenters();

   // Starting towers.
   int startingTowerID = rmObjectDefCreate("starting tower");
   rmObjectDefAddItem(startingTowerID, cUnitTypeSentryTower, 1);
   rmObjectDefAddConstraint(startingTowerID, vDefaultAvoidAll);
   addObjectLocsPerPlayer(startingTowerID, true, 4, cStartingTowerMinDist, cStartingTowerMaxDist, cStartingTowerAvoidanceMeters);
   generateLocs("starting tower locs");

   // Settlements.
   int firstSettlementID = rmObjectDefCreate("first settlement");
   rmObjectDefAddItem(firstSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidWater);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidTowerLOS);

   int secondSettlementID = rmObjectDefCreate("second settlement");
   rmObjectDefAddItem(secondSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidWater);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidTowerLOS);

   if(gameIs1v1() == true)
   {
      addObjectLocsPerPlayer(firstSettlementID, false, 1, 60.0, 80.0, cSettlementDist1v1, cBiasBackward);
      addObjectLocsPerPlayer(secondSettlementID, false, 1, 60.0, 120.0, cSettlementDist1v1, cBiasForward);
   }
   else
   {
      addObjectLocsPerPlayer(firstSettlementID, false, 1, 60.0, 80.0, cCloseSettlementDist, cBiasBackward);
      addObjectLocsPerPlayer(secondSettlementID, false, 1, 80.0, 120.0, cFarSettlementDist, cBiasForward);
   }

   // Other map sizes settlements.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int bonusSettlementID = rmObjectDefCreate("bonus settlement");
      rmObjectDefAddItem(bonusSettlementID, cUnitTypeSettlement, 1);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidEdge);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidWater);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidTowerLOS);
      addObjectLocsPerPlayer(bonusSettlementID, false, 1 * getMapAreaSizeFactor(), 90.0, -1.0, 90.0);
   }

   generateLocs("settlement locs");

   rmSetProgress(0.6);

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

   // Starting hunt.
   int startingHuntID = rmObjectDefCreate("starting hunt");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeRhinoceros, 1);
   }
   else
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeBoar, xsRandInt(2, 3));
   }
   rmObjectDefAddConstraint(startingHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(startingHuntID, vDefaultForceInTowerLOS);
   addObjectLocsPerPlayer(startingHuntID, false, 1, cStartingHuntMinDist, cStartingHuntMaxDist, cStartingObjectAvoidanceMeters);

   // Berries.
   int startingBerriesID = rmObjectDefCreate("starting berries");
   rmObjectDefAddItem(startingBerriesID, cUnitTypeBerryBush, xsRandInt(5, 9), cBerryClusterRadius);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidWater);
   addObjectLocsPerPlayer(startingBerriesID, false, 1, cStartingBerriesMinDist, cStartingBerriesMaxDist, cStartingObjectAvoidanceMeters);
   
   // Chicken.
   int startingChickenID = rmObjectDefCreate("starting chicken");
   rmObjectDefAddItem(startingChickenID, cUnitTypeChicken, xsRandInt(5, 9));
   rmObjectDefAddConstraint(startingChickenID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidWater);
   addObjectLocsPerPlayer(startingChickenID, false, 1, cStartingChickenMinDist, cStartingChickenMaxDist, cStartingObjectAvoidanceMeters);

   // Herdables.
   int startingHerdID = rmObjectDefCreate("starting herd");
   rmObjectDefAddItem(startingHerdID, cUnitTypeGoat, 2);
   rmObjectDefAddConstraint(startingHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidWater);
   addObjectLocsPerPlayer(startingHerdID, true, 1, cStartingHerdMinDist, cStartingHerdMaxDist);

   generateLocs("starting food locs");

   // Gold.
   float avoidGoldMeters = 50.0;

   // Close gold.
   int closeGoldID = rmObjectDefCreate("close gold");
   rmObjectDefAddItem(closeGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidImpassableLand16);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeGoldID, 60.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeGoldID, false, 1, 60.0, 70.0, avoidGoldMeters, cBiasForward);
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
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidImpassableLand16);
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

   // Hunt.
   float avoidHuntMeters = 30.0;
   
   // Close hunt 1.
   int closeHunt1ID = rmObjectDefCreate("close hunt 1");
   rmObjectDefAddItem(closeHunt1ID, cUnitTypeGazelle, xsRandInt(4, 8));
   rmObjectDefAddConstraint(closeHunt1ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHunt1ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHunt1ID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(closeHunt1ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHunt1ID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeHunt1ID, 50.0);
   addObjectLocsPerPlayer(closeHunt1ID, false, 1, 50.0, 80.0, avoidHuntMeters);

   // Close hunt 2.
   int closeHunt2ID = rmObjectDefCreate("close hunt 2");
   rmObjectDefAddItem(closeHunt2ID, cUnitTypeGiraffe, xsRandInt(2, 3));
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(closeHunt2ID, cUnitTypeGazelle, xsRandInt(2, 3));
   }
   rmObjectDefAddConstraint(closeHunt2ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHunt2ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHunt2ID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(closeHunt2ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHunt2ID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeHunt2ID, 50.0);
   addObjectLocsPerPlayer(closeHunt2ID, false, 1, 50.0, 80.0, avoidHuntMeters);

   // Bonus hunt.
   float bonusHuntFloat = xsRandFloat(0.0, 1.0);
   int bonusHuntID = rmObjectDefCreate("bonus hunt");
   if(bonusHuntFloat < 1.0 / 3.0)
   {
      rmObjectDefAddItem(bonusHuntID, cUnitTypeAurochs, xsRandInt(2, 4));
   }
   else if(bonusHuntFloat < 2.0 / 3.0)
   {
      rmObjectDefAddItem(bonusHuntID, cUnitTypeElephant, xsRandInt(1, 2));
   }
   else
   {
      rmObjectDefAddItem(bonusHuntID, cUnitTypeBoar, xsRandInt(2, 5));
   }
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(bonusHuntID, 80.0);
   addObjectLocsPerPlayer(bonusHuntID, false, 1, 80.0, -1.0, avoidHuntMeters);

   // Shore hunt.
   int numShoreHunt = 1;
   if(gameIs1v1() == true)
   {
      numShoreHunt = xsRandInt(1, 2);
   }

   int shoreHuntforceNearWater = rmCreateWaterMaxDistanceConstraint(true, 5.0);

   for(int i = 0; i < numShoreHunt; i++)
   {
      int shoreHuntID = rmObjectDefCreate("shore hunt " + i);
      if(xsRandBool(0.5) == true)
      {
         rmObjectDefAddItem(shoreHuntID, cUnitTypeHippopotamus, xsRandInt(3, 4));
      }
      else
      {
         rmObjectDefAddItem(shoreHuntID, cUnitTypeWaterBuffalo, xsRandInt(3, 4));
      }
      rmObjectDefAddConstraint(shoreHuntID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(shoreHuntID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(shoreHuntID, vDefaultAvoidWater, cObjectConstraintBufferNone);
      rmObjectDefAddConstraint(shoreHuntID, shoreHuntforceNearWater, cObjectConstraintBufferNone);
      rmObjectDefAddConstraint(shoreHuntID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(shoreHuntID, vDefaultAvoidSettlementRange);
      addObjectDefPlayerLocConstraint(shoreHuntID, 80.0);
      addObjectLocsPerPlayer(shoreHuntID, false, 1, 80.0, -1.0, avoidHuntMeters);
   }

   // Other map sizes hunt.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int largeMapHuntID = rmObjectDefCreate("large map hunt");
      if(xsRandBool(0.5) == true)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeGiraffe, xsRandInt(3, 5));
         if(xsRandBool(0.5) == true)
         {
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeGazelle, xsRandInt(2, 5));
         }
      }
      else
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeElephant, xsRandInt(1, 3));
      }

      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidWater);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidSettlementRange);
      addObjectDefPlayerLocConstraint(largeMapHuntID, 80.0);
      addObjectLocsPerPlayer(largeMapHuntID, false, 1 * getMapAreaSizeFactor(), 80.0, -1.0, avoidHuntMeters);
   }
   
   generateLocs("hunt locs");

   // Berries.
   float avoidBerriesMeters = 40.0;
  
   // Shore berries.
   int shoreBerriesID = rmObjectDefCreate("shore berries");
   rmObjectDefAddItem(shoreBerriesID, cUnitTypeBerryBush, xsRandInt(5, 9), cBerryClusterRadius);
   rmObjectDefAddConstraint(shoreBerriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(shoreBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(shoreBerriesID, vDefaultBerriesAvoidWater);
   rmObjectDefAddConstraint(shoreBerriesID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(shoreBerriesID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(shoreBerriesID, avoidDesertArea);
   addObjectDefPlayerLocConstraint(shoreBerriesID, 75.0);
   addObjectLocsPerPlayer(shoreBerriesID, false, 1 * getMapSizeBonusFactor(), 75.0, -1.0, avoidBerriesMeters);

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
   addObjectLocsPerPlayer(closeHerdID, false, 1, 50.0, 70.0, avoidHerdMeters);

   int bonusHerdID = rmObjectDefCreate("bonus herd");
   rmObjectDefAddItem(bonusHerdID, cUnitTypeGoat, xsRandInt(1, 3));
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidAll);
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
   float avoidDesertForestMeters = 30.0;
   
   int desertForestClassID = rmClassCreate();

   int desertForestID = rmAreaDefCreate("desert forest");
   rmAreaDefSetSizeRange(desertForestID, rmTilesToAreaFraction(60), rmTilesToAreaFraction(100));
   rmAreaDefSetForestType(desertForestID, cForestEgyptPalm);
   rmAreaDefSetAvoidSelfDistance(desertForestID, avoidDesertForestMeters);
   rmAreaDefAddConstraint(desertForestID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(desertForestID, forceInDesertArea);
   rmAreaDefAddConstraint(desertForestID, avoidDesertAreaEdge); // Avoid the edge due to layering.
   rmAreaDefAddConstraint(desertForestID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(desertForestID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddToClass(desertForestID, desertForestClassID);

   // Starting forests.
   if(gameIs1v1() == true)
   {
      addSimAreaLocsPerPlayerPair(desertForestID, 3, cStartingForestMinDist, cStartingForestMaxDist, avoidDesertForestMeters);
   }
   else
   {
      addAreaLocsPerPlayer(desertForestID, 3, cStartingForestMinDist, cStartingForestMaxDist, avoidDesertForestMeters);
   }

   generateLocs("starting forest locs");

   // Global forests.
   // Avoid the owner paths to prevent forests from closing off resources.
   rmAreaDefAddConstraint(desertForestID, vDefaultAvoidOwnerPaths, 0.0);
   // rmAreaDefSetConstraintBuffer(desertForestID, 0.0, 6.0);

   // Build for each player in the team area.
   buildAreaDefInTeamAreas(desertForestID, 7 * getMapAreaSizeFactor());

   // Nile forest.
   float avoidNileForestMeters = 25.0;
   int avoidDesertForest = rmCreateClassDistanceConstraint(desertForestClassID, avoidNileForestMeters);

   int shoreForestID = rmAreaDefCreate("shore forest");
   rmAreaDefSetSizeRange(shoreForestID, rmTilesToAreaFraction(60), rmTilesToAreaFraction(100));
   rmAreaDefSetForestType(shoreForestID, cForestEgyptNile);
   rmAreaDefSetAvoidSelfDistance(shoreForestID, avoidDesertForestMeters);
   rmAreaDefAddConstraint(shoreForestID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(shoreForestID, avoidDesertForest);
   rmAreaDefAddConstraint(shoreForestID, avoidDesertArea);
   rmAreaDefAddConstraint(shoreForestID, vDefaultAvoidWater4);
   rmAreaDefAddConstraint(shoreForestID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(shoreForestID, vDefaultForestAvoidTownCenter);

   // Avoid the owner paths to prevent forests from closing off resources.
   rmAreaDefAddConstraint(shoreForestID, vDefaultAvoidOwnerPaths, 0.0);
   // rmAreaDefSetConstraintBuffer(shoreForestID, 0.0, 6.0);

   // Build for each player in the team area.
   buildAreaDefInTeamAreas(shoreForestID, 7 * getMapAreaSizeFactor());

   // Stragglers.
   placeStartingStragglers(cUnitTypeTreePalm);

   rmSetProgress(0.8);

   // Fish.
   float fishDistMeters = 20.0;

   int fishID = rmObjectDefCreate("fish");
   rmObjectDefAddItem(fishID, cUnitTypePerch, 3, 6.0);
   rmObjectDefAddConstraint(fishID, rmCreatePassabilityDistanceConstraint(cPassabilityLand, true, 7.0));
   rmObjectDefAddConstraint(fishID, rmCreateTypeDistanceConstraint(cUnitTypeFishResource, fishDistMeters));
   rmObjectDefAddConstraint(fishID, vDefaultAvoidEdge);
   // Unchecked.
   rmObjectDefPlaceAnywhere(fishID, 0, 5 * cNumberPlayers * getMapAreaSizeFactor());

   rmSetProgress(0.9);

   // Embellishment.
   // Gold areas.
   buildAreaUnderObjectDef(startingGoldID, cTerrainEgyptDirtRocks2, cTerrainEgyptDirtRocks1, 6.0);
   buildAreaUnderObjectDef(closeGoldID, cTerrainEgyptDirtRocks2, cTerrainEgyptDirtRocks1, 6.0);
   buildAreaUnderObjectDef(bonusGoldID, cTerrainEgyptDirtRocks2, cTerrainEgyptDirtRocks1, 6.0);

   // Berries areas.
   buildAreaUnderObjectDef(startingBerriesID, cTerrainEgyptGrass1, cTerrainEgyptGrassDirt2, 11.0);
   buildAreaUnderObjectDef(shoreBerriesID, cTerrainEgyptGrass2, cTerrainEgyptGrass1, 11.0);

   // Random trees.
   int randomTreeID = rmObjectDefCreate("random tree");
   rmObjectDefAddItem(randomTreeID, cUnitTypeTreePalm, 1);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidAll);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidWater4);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidTree);
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

   // Grassy embellishments.
   // Grass.
   int grassID = rmObjectDefCreate("grass");
   rmObjectDefAddItem(grassID, cUnitTypePlantEgyptianGrass, 1);
   rmObjectDefAddConstraint(grassID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(grassID, vDefaultAvoidWater4);
   rmObjectDefAddConstraint(grassID, avoidDesertArea);
   rmObjectDefPlaceAnywhere(grassID, 0, 30 * cNumberPlayers * getMapAreaSizeFactor());

   // Fern.
   int fernID = rmObjectDefCreate("fern");
   rmObjectDefAddItem(fernID, cUnitTypePlantEgyptianFern, 1);
   rmObjectDefAddConstraint(fernID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(fernID, vDefaultAvoidWater4);
   rmObjectDefAddConstraint(fernID, avoidDesertArea);
   rmObjectDefPlaceAnywhere(fernID, 0, 30 * cNumberPlayers * getMapAreaSizeFactor());

   // Bush.
   int bushID = rmObjectDefCreate("bush");
   rmObjectDefAddItem(bushID, cUnitTypePlantEgyptianBush, 1);
   rmObjectDefAddConstraint(bushID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(bushID, vDefaultAvoidWater4);
   rmObjectDefAddConstraint(bushID, avoidDesertArea);
   rmObjectDefPlaceAnywhere(bushID, 0, 30 * cNumberPlayers * getMapAreaSizeFactor());

   // Deserty embellishments.
   // Grass.
   int grassDeadID = rmObjectDefCreate("grass dead");
   rmObjectDefAddItem(grassDeadID, cUnitTypePlantDeadGrass, 1);
   rmObjectDefAddConstraint(grassDeadID, createSymmetricBoxConstraint(rmXTileIndexToFraction(1), rmZTileIndexToFraction(1)));
   rmObjectDefAddConstraint(grassDeadID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(grassDeadID, forceInDesertArea);
   rmObjectDefAddConstraint(grassDeadID, avoidDesertAreaEdge);
   rmObjectDefPlaceAnywhere(grassDeadID, 0, 20 * cNumberPlayers * getMapAreaSizeFactor());

   // Fern.
   int fernDeadID = rmObjectDefCreate("fern dead");
   rmObjectDefAddItem(fernDeadID, cUnitTypePlantDeadFern, 1);
   rmObjectDefAddConstraint(fernDeadID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(fernDeadID, forceInDesertArea);
   rmObjectDefAddConstraint(fernDeadID, avoidDesertAreaEdge);
   rmObjectDefPlaceAnywhere(fernDeadID, 0, 20 * cNumberPlayers * getMapAreaSizeFactor());

   // Bush.
   int bushDeadID = rmObjectDefCreate("bush dead");
   rmObjectDefAddItem(bushDeadID, cUnitTypePlantDeadBush, 1);
   rmObjectDefAddConstraint(bushDeadID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(bushDeadID, forceInDesertArea);
   rmObjectDefAddConstraint(bushDeadID, avoidDesertAreaEdge);
   rmObjectDefPlaceAnywhere(bushDeadID, 0, 20 * cNumberPlayers * getMapAreaSizeFactor());

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeVulture, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   rmSetProgress(1.0);
}
