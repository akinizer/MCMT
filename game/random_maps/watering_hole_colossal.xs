include "lib2/rm_core.xs";
include "lib2/rm_connections.xs";

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

   // Water overrides.
   rmWaterTypeAddBeachLayer(cWaterEgyptWateringHole, cTerrainEgyptBeach1, 3.0, 2.0);
   rmWaterTypeAddBeachLayer(cWaterEgyptWateringHole, cTerrainEgyptSavannah2, 6.0, 2.0);

   // Map size and terrain init.
   int axisTiles = (gameIs1v1() == true) ? getScaledAxisTiles(144) : getScaledAxisTiles(136);

   // Set size.
   float sclr=3;
   if(cMapSizeCurrent == 1)
   {
      sclr=3.5;
   }

   rmSetMapSize(axisTiles * sclr);
   rmInitializeWater(cWaterEgyptWateringHole);

   // Player placement.
   float placementRadiusFraction = xsRandFloat(0.4, 0.425);
   if(cNumberPlayers > 8)
   {
      placementRadiusFraction = 0.4;
   }
   rmPlacePlayersOnCircle(placementRadiusFraction);

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCivFromCulture(cCultureEgyptian);

   // Lighting.
   rmSetLighting(cLightingSetRmWateringHole01);

   rmSetProgress(0.1);

   // Randomly build some small islands in the center.
   float playerIslandDist = 10.0 + (5 * getMapAreaSizeFactor());
   float playerAreaRadius = (gameIs1v1() == true) ? 50.0 : 65.0;
   float islandAvoidPlayerDist = playerAreaRadius + playerIslandDist;

   int islandClassID = rmClassCreate();
   int avoidIsland = rmCreateClassDistanceConstraint(islandClassID, 0.1);
   int islandAvoidPlayerCore = createPlayerLocDistanceConstraint(islandAvoidPlayerDist);
   /*
   * This is rather tricky.
   * We only want to allow the islands to get behind the placement radius if
   * there is enough space, otherwise generation gets awkward and can result
   * in outlining the box constraint (and weird river shapes).
   */
   // Find out how far players are apart (use fractions since we have a square map).
   int p1 = vDefaultTeamPlayerOrder[1];
   int p2 = vDefaultTeamPlayerOrder[2];
   int islandAvoidEdge = cInvalidID;
   float minGapMeters = 20.0;
   vector p1Loc = rmGetPlayerLoc(p1);
   vector p2Loc = rmGetPlayerLoc(p2);
   float distFraction = p1Loc.distance(p2Loc);
   float distMeters = rmXFractionToMeters(distFraction);
   if(distMeters < (2.0 * islandAvoidPlayerDist + minGapMeters) || cNumberPlayers > 8)
   {
      islandAvoidEdge = rmCreateLocMaxDistanceConstraint(cCenterLoc, rmXFractionToMeters(placementRadiusFraction));
   }
   else
   {
      islandAvoidEdge = createSymmetricBoxConstraint(rmXMetersToFraction(islandAvoidPlayerDist * sqrt(getMapAreaSizeFactor())));
   }

   int islandID = rmAreaCreate("island");
   if(gameIs1v1() == true)
   {
      float minFraction = rmRadiusToAreaFraction(rmXFractionToMeters(0.4) - islandAvoidPlayerDist + 1.25 * playerIslandDist);
      float maxFraction = rmRadiusToAreaFraction(rmXFractionToMeters(0.4) - islandAvoidPlayerDist + 2.0 * playerIslandDist);
      rmAreaSetSize(islandID, xsRandFloat(minFraction, minFraction));
      rmAreaSetCoherence(islandID, 0.2 * xsRandInt(0, 4));
   }
   else
   {
      // Currently unused fraction values - consider as variation later.
      //float minFraction = rmRadiusToAreaFraction(rmXFractionToMeters(placementRadiusFraction) - islandAvoidPlayerDist);
      //float maxFraction = rmRadiusToAreaFraction(rmXFractionToMeters(placementRadiusFraction) - islandAvoidPlayerDist + playerIslandDist);
      rmAreaSetSize(islandID, 1.0);
   }
   rmAreaSetMix(islandID, baseMixID);
   rmAreaSetLoc(islandID, cCenterLoc);

   rmAreaSetHeight(islandID, 0.5);
   rmAreaAddHeightBlend(islandID, cBlendAll, cFilter5x5Box, 5, 5.0);
   rmAreaSetEdgeSmoothDistance(islandID, 5);

   rmAreaAddConstraint(islandID, islandAvoidEdge);
   rmAreaAddConstraint(islandID, islandAvoidPlayerCore);
   rmAreaAddToClass(islandID, islandClassID);

   rmAreaBuild(islandID);

   // Set up the connection area ID array.
   int[] areaIDsToConnect = new int(0, 0);
   areaIDsToConnect.add(islandID);

   rmSetProgress(0.2);

   // Player areas.
   int playerIslandClassID = rmClassCreate();

   int avoidPlayerIsland = rmCreateClassDistanceConstraint(playerIslandClassID, 0.1);
   int playerIslandAvoidIsland = rmCreateClassDistanceConstraint(islandClassID, playerIslandDist);
   int playerIslandAvoidPlayerIsland = rmCreateClassDistanceConstraint(playerIslandClassID, playerIslandDist);

   for(int i = 1; i <= cNumberPlayers; i++)
   {
      int playerLocID = vDefaultTeamPlayerLocOrder[i];
      int playerID = rmGetPlayerLocOwner(playerLocID);

      int playerIslandID = rmAreaCreate("player island " + playerID);
      rmAreaSetSize(playerIslandID, 0.5);
      rmAreaSetMix(playerIslandID, baseMixID);
      rmAreaSetLocPlayer(playerIslandID, playerID);

      rmAreaSetHeight(playerIslandID, 0.5);
      rmAreaAddHeightBlend(playerIslandID, cBlendAll, cFilter5x5Box, 2);

      rmAreaAddConstraint(playerIslandID, playerIslandAvoidIsland);
      rmAreaAddConstraint(playerIslandID, playerIslandAvoidPlayerIsland);
      rmAreaAddToClass(playerIslandID, playerIslandClassID);

      vPlayerLocAreaIDs[playerLocID] = playerIslandID;
   }
   
   rmAreaBuildAll();

   rmSetProgress(0.3);

   /*
   * We want to connect players randomly with each other.
   * Since no assumption about player placement should be made, we will simply
   * generate a random player array and then iterate over this.
   */
   int[] shuffledPlayers = createSequentialIntArray(0, cNumberPlayersPlusNature, cShuffleAllExceptFirst);
   for(int i = 1; i <= cNumberPlayers; i++)
   {
      areaIDsToConnect.add(rmAreaGetID("player island " + shuffledPlayers[i]));
   }

   // Connections.
   float connectionWidth = 20.0 * getMapAreaSizeFactor();
   // Connection area def (used for all connections).
   int pathAreaDefID = rmAreaDefCreate("connection area def");
   rmAreaDefSetMix(pathAreaDefID, baseMixID);
   rmAreaDefSetHeight(pathAreaDefID, 1.0);
   rmAreaDefAddHeightBlend(pathAreaDefID, cBlendAll, cFilter5x5Box, 4, 2);

   // Island connection path definition.
   int pathDefID = rmPathDefCreate("connection path def");

   // Create default connections.
   createAreaConnections("player connection", pathDefID, pathAreaDefID, areaIDsToConnect, connectionWidth);

   // Extra connections.
   if(gameIs1v1() == true)
   {
      int extraConnectionAvoidPlayerCore = createPlayerLocDistanceConstraint(80.0);

      // We now require our waypoints to avoid the player core, but still spawn in the player areas.
      rmPathDefAddConstraint(pathDefID, extraConnectionAvoidPlayerCore);
      
      // -1.0 to randomize the position within the area.
      createAreaConnections("extra connection", pathDefID, pathAreaDefID, areaIDsToConnect, connectionWidth, 0.0, rmGetMapXMeters(), cAreaConnectionTypeWrap);
   }
   else
   {
      // Use both to build ally connections.
      createAllyConnections("ally connection", pathDefID, pathAreaDefID, connectionWidth);
   }

   // KotH.
   placeKotHObjects();

   // Only in team games: Build bonus ponds.
   if(gameIs1v1() == false)
   {
      //  Ponds.
      int numPonds = cNumberPlayers * getMapAreaSizeFactor();
      float pondSize = rmRadiusToAreaFraction(20.0);

      int pondClassID = rmClassCreate();
      int pondAvoidPond = rmCreateClassDistanceConstraint(pondClassID, 30.0);
      int pondAvoidPlayerIsland = rmCreateClassDistanceConstraint(playerIslandClassID, 50.0);

      for(int i = 0; i < numPonds; i++)
      {
         int pondID = rmAreaCreate("pond " + i);
         rmAreaSetSize(pondID, pondSize);
         rmAreaSetWaterType(pondID, cWaterEgyptWateringHole);

         rmAreaSetHeight(pondID, 0.0);
         rmAreaSetEdgeSmoothDistance(pondID, 10);

         rmAreaAddToClass(pondID, pondClassID);
         rmAreaAddConstraint(pondID, pondAvoidPond);
         rmAreaAddConstraint(pondID, pondAvoidPlayerIsland);
         rmAreaAddConstraint(pondID, vDefaultAvoidKotH);
      }

      rmAreaBuildAll();
   }

   rmSetProgress(0.4);

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
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidCorner40);

   int secondSettlementID = rmObjectDefCreate("second settlement");
   rmObjectDefAddItem(secondSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidWater);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(secondSettlementID, avoidPlayerIsland);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidKotH);

   if(gameIs1v1() == true)
   {
      rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidSiegeShipRange);
      rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidSiegeShipRange);
      addSimObjectLocsPerPlayerPair(firstSettlementID, false, 1, 60.0, 80.0, cSettlementDist1v1, cBiasBackward);
      addSimObjectLocsPerPlayerPair(secondSettlementID, false, 1, 70.0, 120.0, 90.0, cBiasAggressive);
   }
   else
   {
      addObjectLocsPerPlayer(firstSettlementID, false, 1, 50.0, 80.0, cCloseSettlementDist, cBiasDefensive | cBiasAllyOutside);
      addObjectLocsPerPlayer(secondSettlementID, false, 1, 70.0, 150.0, cFarSettlementDist, cBiasAggressive | cBiasAllyInside);
   }
   
   // Other map sizes settlements.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      bool insideBool = xsRandBool(0.5);
      int bonusSettlementID = rmObjectDefCreate("bonus settlement");
      rmObjectDefAddItem(bonusSettlementID, cUnitTypeSettlement, 1);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidEdge);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidWater);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidCorner40);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidSiegeShipRange);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidKotH);
      if (insideBool == true)
      {
         rmObjectDefAddConstraint(bonusSettlementID, avoidPlayerIsland);
      }
      else
      {
         rmObjectDefAddConstraint(bonusSettlementID, playerIslandAvoidIsland);
      }

      addObjectLocsPerPlayer(bonusSettlementID, false, 1, 100.0, -1.0, 90.0);

      if (cMapSizeCurrent > cMapSizeLarge)
      {
         int fourthSettlementID = rmObjectDefCreate("fourth settlement");
         rmObjectDefAddItem(fourthSettlementID, cUnitTypeSettlement, 1);
         rmObjectDefAddConstraint(fourthSettlementID, vDefaultSettlementAvoidEdge);
         rmObjectDefAddConstraint(fourthSettlementID, vDefaultSettlementAvoidWater);
         rmObjectDefAddConstraint(fourthSettlementID, vDefaultAvoidTowerLOS);
         rmObjectDefAddConstraint(fourthSettlementID, vDefaultAvoidCorner);
         rmObjectDefAddConstraint(fourthSettlementID, vDefaultSettlementAvoidSiegeShipRange);
         rmObjectDefAddConstraint(fourthSettlementID, vDefaultAvoidKotH);
         // Invert logic from previous town center, to ensure in giant maps, one spawns in the middle, and one in the player area.
         if (insideBool == false)
         {
            rmObjectDefAddConstraint(fourthSettlementID, avoidPlayerIsland);
         }
         else
         {
            rmObjectDefAddConstraint(fourthSettlementID, playerIslandAvoidIsland);
         }
         addObjectLocsPerPlayer(fourthSettlementID, false, 1, 100.0, -1.0, 90.0);
      }
   }

   // For now, only generate connections to 3rd TCs if we succeed.
   if(generateLocs("settlement locs", true, true, true, false) == true)
   {
      if(gameIs1v1() == false)
      {
         int locStartIdx = cNumberPlayers;
         int locEndIdx = 2 * cNumberPlayers;
         float settlementAreaSize = rmTilesToAreaFraction(25);
         int settlementIgnoreRoad1Terrain = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptRoad1, 1.0);
         int settlementIgnoreRoad2Terrain = rmCreateTerrainTypeDistanceConstraint(cTerrainEgyptRoad2, 1.0);

         for(int i = locStartIdx; i < locEndIdx; i++)
         {
            int ownerID = rmLocGenGetLocOwner(i);

            // Create a new path from the settlement to the player spawn.
            int pathID = rmPathCreate("settlement path " + ownerID);
            rmPathAddWaypoint(pathID, rmLocGenGetLoc(i));
            rmPathAddWaypoint(pathID, rmGetPlayerLoc(ownerID));
            rmPathBuild(pathID);

            int connectionID = rmAreaCreate("settlement area " + ownerID);
            rmAreaSetMix(connectionID, baseMixID);
            rmAreaSetHeight(connectionID, 1.0);
            rmAreaAddHeightBlend(connectionID, cBlendAll, cFilter5x5Box, 4, 2);
            rmAreaSetPath(connectionID, pathID, 15.0);
            rmAreaAddTerrainConstraint(connectionID, settlementIgnoreRoad1Terrain);
            rmAreaAddTerrainConstraint(connectionID, settlementIgnoreRoad2Terrain);
            rmAreaBuild(connectionID);
         }
      }
   }

   // Don't forget to clean up.
   resetLocGen();

   rmSetProgress(0.5);

   // Starting objects.
   // Starting gold.
   int startingGoldID = rmObjectDefCreate("starting gold");
   rmObjectDefAddItem(startingGoldID, cUnitTypeMineGoldMedium, 1);
   rmObjectDefAddConstraint(startingGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingGoldID, vDefaultGoldAvoidWater);
   rmObjectDefAddConstraint(startingGoldID, vDefaultStartingGoldAvoidTower);
   rmObjectDefAddConstraint(startingGoldID, vDefaultForceStartingGoldNearTower);
   addObjectLocsPerPlayer(startingGoldID, false, 1, cStartingGoldMinDist, cStartingGoldMaxDist, cStartingObjectAvoidanceMeters);

   generateLocs("starting gold locs");

   // Starting hunt.
   int startingHuntID = rmObjectDefCreate("starting hunt");
   rmObjectDefAddItem(startingHuntID, cUnitTypeGazelle, 8);
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
   rmObjectDefAddItem(startingHerdID, cUnitTypePig, xsRandInt(1, 2));
   rmObjectDefAddConstraint(startingHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidWater);
   addObjectLocsPerPlayer(startingHerdID, true, 1, cStartingHerdMinDist, cStartingHerdMaxDist);

   generateLocs("starting food locs");

   // Gold.
   float avoidGoldMeters = 50.0;

   // Player gold.
   int playerGoldID = rmObjectDefCreate("player gold");
   rmObjectDefAddItem(playerGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(playerGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(playerGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(playerGoldID, vDefaultGoldAvoidWater);
   rmObjectDefAddConstraint(playerGoldID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(playerGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(playerGoldID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(playerGoldID, rmCreateAreaDistanceConstraint(islandID, 20.0));
   if(gameIs1v1() == true && cMapSizeCurrent == cMapSizeStandard)
   {
      float goldFloat = xsRandFloat(0.0, 1.0);
      int numMediumGold = 0;
      int numFarGold = 0;

      if(goldFloat < 1.0 / 3.0)
      {
         numMediumGold = 2;
         numFarGold = 1;
      }
      else if(goldFloat < 2.0 / 3.0)
      {
         numMediumGold = 1;
         numFarGold = 2;
      }
      else
      {
         numMediumGold = 1;
         numFarGold = 1;
      }

      //addSimObjectLocsPerPlayerPair(playerGoldID, false, 1, 50.0, 70.0, avoidGoldMeters);
      addMirroredObjectLocsPerPlayerPair(playerGoldID, false, 1, 50.0, 70.0, avoidGoldMeters);
      if(numMediumGold > 1)
      {
         addMirroredObjectLocsPerPlayerPair(playerGoldID, false, 1, 50.0, 90.0, avoidGoldMeters);
      }

      addMirroredObjectLocsPerPlayerPair(playerGoldID, false, 1, 70.0, -1.0, avoidGoldMeters);
      if(numFarGold > 1)
      {
         addMirroredObjectLocsPerPlayerPair(playerGoldID, false, 1, 70.0, -1.0, avoidGoldMeters);
      }
   }
   else
   {
      addObjectLocsPerPlayer(playerGoldID, false, 2 * getMapSizeBonusFactor(), 50.0, -1.0, avoidGoldMeters, cBiasNone, cInAreaPlayer);
   }

   // Bonus gold.
   int bonusGoldID = rmObjectDefCreate("bonus gold");
   rmObjectDefAddItem(bonusGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidWater);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(bonusGoldID, avoidPlayerIsland);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusGoldID, false, xsRandInt(1, 2) * getMapAreaSizeFactor(), 0.0, -1.0, avoidGoldMeters);
   }
   else
   {
      addObjectLocsPerPlayer(bonusGoldID, false, xsRandInt(1, 2) * getMapAreaSizeFactor(), 0.0, -1.0, avoidGoldMeters);
   }

   generateLocs("gold locs");

   rmSetProgress(0.6);

   // Hunt.
   float avoidPlayerHuntMeters = 50.0;

   // Close hunt.
   int closeHuntID = rmObjectDefCreate("close hunt");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeHippopotamus, xsRandInt(2, 3));
   }
   else
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeRhinoceros, 2);
   }
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidWater);
   // rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(closeHuntID, avoidIsland);
   rmObjectDefAddConstraint(closeHuntID, rmCreateTypeDistanceConstraint(cUnitTypeHuntable, avoidPlayerHuntMeters));
   if(xsRandBool(2.0 / 3.0) == true)
   {
      rmObjectDefAddConstraint(closeHuntID, vDefaultForceInTowerLOS);
      addObjectLocsPerPlayer(closeHuntID, false, 1, 30.0, 50.0, avoidPlayerHuntMeters);
   }
   else
   {
      rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidTowerLOS);
      addObjectLocsPerPlayer(closeHuntID, false, 1, 50.0, 70.0, avoidPlayerHuntMeters, cBiasNone, cInAreaPlayer);
   }

   // Player hunt (1 or 2).
   int numPlayerHunt = (xsRandBool(0.0) == true) ? 1 : 2;
   for(int i = 1; i <= numPlayerHunt; i++)
   {
      int playerHuntID = rmObjectDefCreate("player hunt " + i);
      if(xsRandBool(0.5) == true)
      {
         rmObjectDefAddItem(playerHuntID, cUnitTypeZebra, xsRandInt(6, 10));
      }
      else
      {
         rmObjectDefAddItem(playerHuntID, cUnitTypeGazelle, xsRandInt(6, 10));
      }
      rmObjectDefAddConstraint(playerHuntID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(playerHuntID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(playerHuntID, vDefaultFoodAvoidWater);
      rmObjectDefAddConstraint(playerHuntID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(playerHuntID, vDefaultAvoidSettlementRange);
      rmObjectDefAddConstraint(playerHuntID, avoidIsland);
      if(gameIs1v1() == true && cMapSizeCurrent == cMapSizeStandard)
      {
         addMirroredObjectLocsPerPlayerPair(playerHuntID, false, 1, 50.0, 90.0, avoidPlayerHuntMeters);
      }
      else
      {
         addObjectLocsPerPlayer(playerHuntID, false, 1 * getMapAreaSizeFactor(), 50.0, -1.0, avoidPlayerHuntMeters, cBiasNone, cInAreaPlayer);
      }
   }

   // Player hunt 3.
   int playerHunt3ID = rmObjectDefCreate("player hunt 3");
   rmObjectDefAddItem(playerHunt3ID, cUnitTypeCrownedCrane, xsRandInt(5, 8));
   rmObjectDefAddConstraint(playerHunt3ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(playerHunt3ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(playerHunt3ID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(playerHunt3ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(playerHunt3ID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(playerHunt3ID, vDefaultAvoidWater, cObjectConstraintBufferNone);
   rmObjectDefAddConstraint(playerHunt3ID, rmCreateWaterMaxDistanceConstraint(true, 10.0), cObjectConstraintBufferNone);
   rmObjectDefAddConstraint(playerHunt3ID, avoidIsland);
   if(gameIs1v1() == true)
   {
      addMirroredObjectLocsPerPlayerPair(playerHunt3ID, false, 1 * getMapSizeBonusFactor(), 50.0, -1.0, avoidPlayerHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(playerHunt3ID, false, 1 * getMapSizeBonusFactor(), 50.0, -1.0, avoidPlayerHuntMeters, cBiasNone, cInAreaPlayer);
   }

   // Player hunt 4.
   if(cNumberPlayers < 9)
   {
      float playerHunt4Float = xsRandFloat(0.0, 1.0);
      int playerHunt4ID = rmObjectDefCreate("player hunt 4");
      if(playerHunt4Float < 1.0 / 3.0)
      {
         rmObjectDefAddItem(playerHunt4ID, cUnitTypeElephant, xsRandInt(1, 2));
      }
      else if(playerHunt4Float < 2.0 / 3.0)
      {
         rmObjectDefAddItem(playerHunt4ID, cUnitTypeHippopotamus, xsRandInt(3, 5));
      }
      else
      {
         rmObjectDefAddItem(playerHunt4ID, cUnitTypeZebra, xsRandInt(3, 6));
      }
      rmObjectDefAddConstraint(playerHunt4ID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(playerHunt4ID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(playerHunt4ID, vDefaultFoodAvoidWater);
      rmObjectDefAddConstraint(playerHunt4ID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(playerHunt4ID, vDefaultAvoidSettlementRange);
      rmObjectDefAddConstraint(playerHunt4ID, avoidIsland);
      if(gameIs1v1() == true)
      {
         addMirroredObjectLocsPerPlayerPair(playerHunt4ID, false, 1 * getMapAreaSizeFactor(), 70.0, -1.0, avoidPlayerHuntMeters);
      }
      else
      {
         addObjectLocsPerPlayer(playerHunt4ID, false, 1 * getMapAreaSizeFactor(), 70.0, -1.0, avoidPlayerHuntMeters, cBiasNone, cInAreaPlayer);
      }
   }

   // Bonus hunt.
   float avoidBonusHuntMeters = 30.0;

   for(int i = 0; i < 3 * getMapAreaSizeFactor(); i++)
   {
      float bonusHuntFloat = xsRandFloat(0.0, 1.0);
      int bonusHuntID = rmObjectDefCreate("bonus hunt " + i);
      if(bonusHuntFloat < 1.0 / 6.0)
      {
         rmObjectDefAddItem(bonusHuntID, cUnitTypeElephant, 2);
      }
      else if(bonusHuntFloat < 2.0 / 6.0)
      {
         rmObjectDefAddItem(bonusHuntID, cUnitTypeRhinoceros, xsRandInt(2, 4));
      }
      else if(bonusHuntFloat < 3.0 / 6.0)
      {
         rmObjectDefAddItem(bonusHuntID, cUnitTypeWaterBuffalo, xsRandInt(4, 6));
         if(xsRandBool(0.5) == true)
         {
            rmObjectDefAddItem(bonusHuntID, cUnitTypeZebra, xsRandInt(2, 4));
         }
      }
      else if(bonusHuntFloat < 4.0 / 6.0)
      {
         rmObjectDefAddItem(bonusHuntID, cUnitTypeHippopotamus, xsRandInt(3, 5));
      }
      else if(bonusHuntFloat < 5.0 / 6.0)
      {
         rmObjectDefAddItem(bonusHuntID, cUnitTypeZebra, xsRandInt(5, 6));
         if(xsRandBool(0.5) == true)
         {
            rmObjectDefAddItem(bonusHuntID, cUnitTypeGiraffe, xsRandInt(2, 4));
         }
      }
      else
      {
         rmObjectDefAddItem(bonusHuntID, cUnitTypeGazelle, xsRandInt(6, 9));
      }
      rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidWater);
      rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidSettlementRange);
      rmObjectDefAddConstraint(bonusHuntID, avoidPlayerIsland);
      addObjectDefPlayerLocConstraint(bonusHuntID, 50.0);
      if(gameIs1v1() == true)
      {
         addSimObjectLocsPerPlayerPair(bonusHuntID, false, 1, 0.0, -1.0, avoidBonusHuntMeters);
      }
      else
      {
         addObjectLocsPerPlayer(bonusHuntID, false, 1, 0.0, -1.0, avoidBonusHuntMeters);
      }
   }

   generateLocs("hunt locs");

   rmSetProgress(0.7);

   // Berries.
   float avoidBerriesMeters = 50.0;

   int berriesID = rmObjectDefCreate("berries");
   rmObjectDefAddItem(berriesID, cUnitTypeBerryBush, xsRandInt(5, 9), cBerryClusterRadius);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(berriesID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(berriesID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(berriesID, avoidPlayerIsland);
   addObjectDefPlayerLocConstraint(berriesID, 80.0);
   if(gameIsFair() == true)
   {
      addObjectLocsPerPlayer(berriesID, false, 1 * getMapSizeBonusFactor(), 80.0, -1.0, avoidBerriesMeters);
   }
   else
   {
      addObjectLocsPerPlayer(berriesID, false, 1 * getMapSizeBonusFactor(), 80.0, -1.0, avoidBerriesMeters, cBiasNone, cInAreaNone);
   }

   generateLocs("berries locs");

   // Herdables.
   float avoidHerdMeters = 50.0;

   int closeHerdID = rmObjectDefCreate("close herd");
   rmObjectDefAddItem(closeHerdID, cUnitTypePig, xsRandInt(2, 3));
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidWater);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHerdID, avoidIsland);
   addObjectLocsPerPlayer(closeHerdID, false, 1, 50.0, 70.0, avoidHerdMeters, cBiasNone, cInAreaPlayer);

   int bonusHerdID = rmObjectDefCreate("bonus herd");
   rmObjectDefAddItem(bonusHerdID, cUnitTypePig, xsRandInt(1, 2));
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidWater);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHerdID, avoidPlayerIsland);
   addObjectLocsPerPlayer(bonusHerdID, false, xsRandInt(1, 2) * getMapSizeBonusFactor(), 70.0, -1.0, avoidHerdMeters, cBiasNone, cInAreaTeam);

   generateLocs("herd locs");

   // Predators.
   float avoidPredatorMeters = 50.0;

   int playerPredatorID = rmObjectDefCreate("player predator");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(playerPredatorID, cUnitTypeHyena, xsRandInt(2, 3));
   }
   else
   {
      rmObjectDefAddItem(playerPredatorID, cUnitTypeLion, 2);
   }
   rmObjectDefAddConstraint(playerPredatorID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(playerPredatorID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(playerPredatorID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(playerPredatorID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(playerPredatorID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(playerPredatorID, avoidIsland);
   rmObjectDefAddConstraint(playerPredatorID, createPlayerLocDistanceConstraint(70.0));
   addObjectLocsPerPlayer(playerPredatorID, false, 1 * getMapAreaSizeFactor(), 50.0, -1.0, avoidPredatorMeters);

   int bonusPredatorID = rmObjectDefCreate("bonus predator");
   rmObjectDefAddItem(bonusPredatorID, cUnitTypeCrocodile, 2);
   rmObjectDefAddConstraint(bonusPredatorID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusPredatorID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(bonusPredatorID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusPredatorID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(bonusPredatorID, avoidPlayerIsland);
   rmObjectDefAddConstraint(bonusPredatorID, vDefaultAvoidWater, cObjectConstraintBufferNone);
   rmObjectDefAddConstraint(bonusPredatorID, rmCreateWaterMaxDistanceConstraint(true, 4.0), cObjectConstraintBufferNone);
   addObjectDefPlayerLocConstraint(bonusPredatorID, 70.0);
   addObjectLocsPerPlayer(bonusPredatorID, false, 1 * getMapAreaSizeFactor(), 50.0, -1.0, avoidPredatorMeters);

   generateLocs("predator locs");

   // Relics.
   float avoidRelicMeters = 80.0;

   int playerRelicID = rmObjectDefCreate("player relic");
   rmObjectDefAddItem(playerRelicID, cUnitTypeRelic, 1);
   rmObjectDefAddConstraint(playerRelicID, vDefaultAvoidAll);
   rmObjectDefAddConstraint(playerRelicID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(playerRelicID, vDefaultAvoidWater4);
   rmObjectDefAddConstraint(playerRelicID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(playerRelicID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(playerRelicID, avoidIsland);
   addObjectLocsPerPlayer(playerRelicID, false, 1 * getMapAreaSizeFactor(), 50.0, -1.0, avoidRelicMeters);

   int bonusRelicID = rmObjectDefCreate("bonus relic");
   rmObjectDefAddItem(bonusRelicID, cUnitTypeRelic, 1);
   rmObjectDefAddConstraint(bonusRelicID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusRelicID, vDefaultRelicAvoidAll);
   rmObjectDefAddConstraint(bonusRelicID, vDefaultRelicAvoidWater);
   rmObjectDefAddConstraint(bonusRelicID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusRelicID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(bonusRelicID, rmCreateClassDistanceConstraint(playerIslandClassID, 15.0));
   if(gameIsFair() == true)
   {
      addObjectLocsPerPlayer(bonusRelicID, false, 1 * getMapAreaSizeFactor(), 50.0, -1.0, avoidRelicMeters);
   }
   else
   {
      addObjectLocsPerPlayer(bonusRelicID, false, 1 * getMapAreaSizeFactor(), 50.0, -1.0, avoidRelicMeters, cBiasNone, cInAreaNone);
   }

   generateLocs("relic locs");

   rmSetProgress(0.8);

   // Forests.
   float avoidForestMeters = 25.0;

   int forestDefID = rmAreaDefCreate("forest");
   rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(50), rmTilesToAreaFraction(70));
   rmAreaDefSetForestType(forestDefID, cForestEgyptSavannah);
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
   buildAreaDefInTeamAreas(forestDefID, 12 * getMapAreaSizeFactor());

   // Stragglers.
   placeStartingStragglers(cUnitTypeTreeSavannah);

   rmSetProgress(0.9);

   // Embellishment.
   // Gold areas.
   buildAreaUnderObjectDef(startingGoldID, cTerrainEgyptDirtRocks2, cTerrainEgyptDirtRocks1, 6.0);
   buildAreaUnderObjectDef(playerGoldID, cTerrainEgyptDirtRocks2, cTerrainEgyptDirtRocks1, 6.0);
   buildAreaUnderObjectDef(bonusGoldID, cTerrainEgyptDirtRocks2, cTerrainEgyptDirtRocks1, 6.0);

   // Berries areas.
   buildAreaUnderObjectDef(startingBerriesID, cTerrainEgyptSavannah2, cInvalidID, 10.0);
   buildAreaUnderObjectDef(berriesID, cTerrainEgyptSavannah2, cInvalidID, 10.0);

   // Random trees.
   int randomTreeID = rmObjectDefCreate("random tree");
   rmObjectDefAddItem(randomTreeID, cUnitTypeTreeSavannah, 1);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidWater);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidTree);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefPlaceAnywhere(randomTreeID, 0, 5 * cNumberPlayers * getMapAreaSizeFactor());

   // Rocks.
   int rockTinyID = rmObjectDefCreate("rock tiny");
   rmObjectDefAddItem(rockTinyID, cUnitTypeRockEgyptTiny, 1);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefPlaceAnywhere(rockTinyID, 0,40 * cNumberPlayers * getMapAreaSizeFactor());

   int rockSmallID = rmObjectDefCreate("rock small");
   rmObjectDefAddItem(rockSmallID, cUnitTypeRockEgyptSmall, 1);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefPlaceAnywhere(rockSmallID, 0, 40 * cNumberPlayers * getMapAreaSizeFactor());

   // Plants.
   int plantGrassID = rmObjectDefCreate("plant grass");
   rmObjectDefAddItem(plantGrassID, cUnitTypePlantEgyptianGrass, 1);
   rmObjectDefAddConstraint(plantGrassID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantGrassID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefPlaceAnywhere(plantGrassID, 0, 35 * cNumberPlayers * getMapAreaSizeFactor());

   int plantShrubID = rmObjectDefCreate("plant shrub");
   rmObjectDefAddItem(plantShrubID, cUnitTypePlantEgyptianShrub, 1);
   rmObjectDefAddConstraint(plantShrubID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantShrubID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefPlaceAnywhere(plantShrubID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());

   int plantFernID = rmObjectDefCreate("plant fern");
   rmObjectDefAddItem(plantFernID, cUnitTypePlantEgyptianFern, 1);
   rmObjectDefAddConstraint(plantFernID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantFernID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefPlaceAnywhere(plantFernID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());

   // Water lilies.
   int lilyAvoidLand = rmCreateWaterDistanceConstraint(false, 2.0);
   int lilyForceNearLand = rmCreateWaterMaxDistanceConstraint(false, 6.0);

   int waterLilyID = rmObjectDefCreate("lily");
   rmObjectDefAddItem(waterLilyID, cUnitTypeWaterLily, 1);
   rmObjectDefAddConstraint(waterLilyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(waterLilyID, lilyAvoidLand, cObjectConstraintBufferNone);
   rmObjectDefAddConstraint(waterLilyID, lilyForceNearLand, cObjectConstraintBufferNone);
   rmObjectDefPlaceAnywhere(waterLilyID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   int waterLilyGroupID = rmObjectDefCreate("lily group");
   rmObjectDefAddItem(waterLilyGroupID, cUnitTypeWaterLily, xsRandInt(2, 4), 4.0);
   rmObjectDefAddConstraint(waterLilyGroupID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(waterLilyGroupID, lilyAvoidLand, cObjectConstraintBufferNone);
   rmObjectDefAddConstraint(waterLilyGroupID, lilyForceNearLand, cObjectConstraintBufferNone);
   rmObjectDefPlaceAnywhere(waterLilyGroupID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   // Reeds.
   int reedAvoidLand = rmCreateWaterDistanceConstraint(false, 2.0);
   int reedForceNearLand = rmCreateWaterMaxDistanceConstraint(false, 4.0);

   int waterReedID = rmObjectDefCreate("reed");
   rmObjectDefAddItem(waterReedID, cUnitTypeWaterReeds, 1);
   rmObjectDefAddConstraint(waterReedID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(waterReedID, reedAvoidLand, cObjectConstraintBufferNone);
   rmObjectDefAddConstraint(waterReedID, reedForceNearLand, cObjectConstraintBufferNone);
   rmObjectDefPlaceAnywhere(waterReedID, 0, 15 * cNumberPlayers * getMapAreaSizeFactor());

   int waterReedGroupID = rmObjectDefCreate("reed group");
   rmObjectDefAddItem(waterReedGroupID, cUnitTypeWaterReeds, xsRandInt(2, 4), 4.0);
   rmObjectDefAddConstraint(waterReedGroupID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(waterReedGroupID, reedAvoidLand, cObjectConstraintBufferNone);
   rmObjectDefAddConstraint(waterReedGroupID, reedForceNearLand, cObjectConstraintBufferNone);
   rmObjectDefPlaceAnywhere(waterReedGroupID, 0, 15 * cNumberPlayers * getMapAreaSizeFactor());

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeVulture, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   rmSetProgress(1.0);
}
