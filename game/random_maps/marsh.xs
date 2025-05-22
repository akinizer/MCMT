include "lib2/rm_core.xs";
include "lib2/rm_connections.xs";

void generate()
{
   rmSetProgress(0.0);

   // Define mixes.
   int centerMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(centerMixID, cNoiseFractalSum, 0.1, 1);
   rmCustomMixAddPaintEntry(centerMixID, cTerrainMarshGrassWet1, 3.0);
   rmCustomMixAddPaintEntry(centerMixID, cTerrainMarshGrassWet2, 2.0);
   rmCustomMixAddPaintEntry(centerMixID, cTerrainMarshGrassWet3, 2.0);

   int playerIslandMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(playerIslandMixID, cNoiseFractalSum, 0.2, 1);
   rmCustomMixAddPaintEntry(playerIslandMixID, cTerrainMarshGrass2, 2.0);
   rmCustomMixAddPaintEntry(playerIslandMixID, cTerrainMarshGrass1, 1.0);
   rmCustomMixAddPaintEntry(playerIslandMixID, cTerrainMarshGrassDirt1, 2.0);
   rmCustomMixAddPaintEntry(playerIslandMixID, cTerrainMarshGrassDirt2, 1.0);
   rmCustomMixAddPaintEntry(playerIslandMixID, cTerrainMarshGrassDirt3, 1.0);

   int borderMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(borderMixID, cNoiseFractalSum, 0.2, 1);
   rmCustomMixAddPaintEntry(borderMixID, cTerrainMarshGrass2, 1.0);
   rmCustomMixAddPaintEntry(borderMixID, cTerrainMarshGrass1, 1.0);
   rmCustomMixAddPaintEntry(borderMixID, cTerrainMarshGrassDirt1, 1.0);

 // Set size.
   int playerTiles=20000;
   int cNumberNonGaiaPlayers = 10;
   if(cMapSizeCurrent == 1)
   {
      playerTiles = 30000;
   }
   int size=2.0*sqrt(cNumberNonGaiaPlayers*playerTiles/0.9);
   rmSetMapSize(size, size);
   rmInitializeWater(cWaterMarshLake);

   // Player placement.
   /*
   * Radius computation: This has to be stretched for large/giant maps so that
   * we have a comparable edge distance to prevent the center completely
   * surrounding player areas.
   */
   float placementRadius = 0.375;
   //float actualPlacementRadius = placementRadius + (0.5 - placementRadius) * (1.0 - 1.0 / sqrt(getMapAreaSizeFactor()));
   rmPlacePlayersOnCircle(placementRadius);

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ (Greek or Atty).
   if(xsRandBool(0.5) == true)
   {
      rmSetNatureCivFromCulture(cCultureGreek);
   }
   else
   {
      rmSetNatureCivFromCulture(cCultureAtlantean);
   }

   // Lighting.
   rmSetLighting(cLightingSetRmMarsh01);

   rmSetProgress(0.1);

   // Relevant parameters.
   float playerIslandDist = 15.0;
   float playerAreaRadius = 50.0;
   float islandAvoidPlayerDist = playerIslandDist + playerAreaRadius;

   // Randomly build some small islands in the center.
   int islandClassID = rmClassCreate();
   int numIslands = (gameIs1v1() == true) ? 1 : 4;

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
   vector p1Loc = rmGetPlayerLoc(p1);
   vector p2Loc = rmGetPlayerLoc(p2);
   float distFraction = p1Loc.distance(p2Loc);
   float distMeters = rmXFractionToMeters(distFraction);
   float minGapMeters = 20.0;
   float islandDist = 20.0;

   if(distMeters < (2.0 * islandAvoidPlayerDist + minGapMeters) || cNumberPlayers > 8)
   {
      islandAvoidEdge = rmCreateLocMaxDistanceConstraint(cCenterLoc, rmXFractionToMeters(placementRadius) + 0.5 * islandAvoidPlayerDist);
   }
   else
   {
      // rmXMetersToFraction(65.0) translated to a fraction to scale properly to large/giant.
      float edgeRadius = 0.35 / sqrt(cNumberPlayers);
      // float actualEdgeRadius = edgeRadius + (0.5 - edgeRadius) * (1.0 - 1.0 / sqrt(getMapAreaSizeFactor()));
      islandAvoidEdge = createSymmetricBoxConstraint(edgeRadius);
   }

   int avoidIsland = rmCreateClassDistanceConstraint(islandClassID, 0.1);
   int islandAvoidIsland = rmCreateClassDistanceConstraint(islandClassID, islandDist);
   int islandAvoidPlayerCore = createPlayerLocDistanceConstraint(islandAvoidPlayerDist);

   // Set up array for area connections.
   int[] areaIDsToConnect = new int(0, 0);

   for(int i = 0; i < numIslands; i++)
   {
      int islandID = rmAreaCreate("island " + i);
      rmAreaSetSize(islandID, 1.0);
      rmAreaSetMix(islandID, centerMixID);
      if(gameIs1v1() == true)
      {
         rmAreaSetLoc(islandID, cCenterLoc);
      }

      rmAreaSetHeight(islandID, 1.0);
      rmAreaAddHeightBlend(islandID, cBlendAll, cFilter5x5Box, 4, 2);
      rmAreaSetEdgeSmoothDistance(islandID, 12);

      rmAreaAddConstraint(islandID, islandAvoidIsland);
      rmAreaAddConstraint(islandID, islandAvoidEdge);
      rmAreaAddConstraint(islandID, islandAvoidPlayerCore);
      rmAreaAddToClass(islandID, islandClassID);

      areaIDsToConnect.add(islandID);
   }

   rmAreaBuildAll();

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
      rmAreaSetMix(playerIslandID, playerIslandMixID);
      rmAreaSetLocPlayer(playerIslandID, playerID);

      // Higher coherence gives smoother rivers.
      rmAreaSetHeight(playerIslandID, 1.0);
      rmAreaAddHeightBlend(playerIslandID, cBlendAll, cFilter5x5Box, 4, 2);
      rmAreaSetHeightNoise(playerIslandID, cNoiseFractalSum, 3.0, 0.1, 2, 0.5);
      rmAreaSetHeightNoiseBias(playerIslandID, 1.0);

      rmAreaAddConstraint(playerIslandID, playerIslandAvoidIsland);
      rmAreaAddConstraint(playerIslandID, playerIslandAvoidPlayerIsland);
      rmAreaAddToClass(playerIslandID, playerIslandClassID);

      vPlayerLocAreaIDs[playerLocID] = playerIslandID;
   }

   rmAreaBuildAll();

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
   // Connection area def (used for all connections).
   int pathAreaDefID = rmAreaDefCreate("connection area");
   rmAreaDefAddTerrainReplacement(pathAreaDefID, cTerrainMarshShore1, cTerrainMarshGrassWet1);
   rmAreaDefAddTerrainReplacement(pathAreaDefID, cTerrainMarshWet1, cTerrainMarshGrassWet1);
   rmAreaDefSetHeight(pathAreaDefID, 1.0);
   rmAreaDefAddHeightBlend(pathAreaDefID, cBlendAll, cFilter5x5Box, 4, 2);

   // Island connection path definition.
   int pathDefID = rmPathDefCreate("island path");

   // Create default connections.
   createAreaConnections("player connection", pathDefID, pathAreaDefID, areaIDsToConnect, 40.0, 0.0);

   // Extra connections.
   if(gameIs1v1() == true)
   {
      int extraConnectionAvoidPlayerCore = createPlayerLocDistanceConstraint(80.0);

      // We now require our waypoints to avoid the player core, but still spawn in the player areas.
      rmPathDefAddConstraint(pathDefID, extraConnectionAvoidPlayerCore);

      // -1.0 to randomize the position within the area.
      createAreaConnections("extra connection", pathDefID, pathAreaDefID, areaIDsToConnect, 40.0, 0.0, rmGetMapXMeters(), cAreaConnectionTypeWrap);
   }
   else
   {
      // Use both to build ally connections.
      createAllyConnections("ally connection", pathDefID, pathAreaDefID, 40.0);
   }

   rmSetProgress(0.3);

   // KotH.
   placeKotHObjects();

   // Embellishment.
   // Between player islands and islands.
   // Between player islands and islands.
   int beautificationAreaDefID = rmAreaDefCreate("beautification");
   rmAreaDefSetSizeRange(beautificationAreaDefID, rmTilesToAreaFraction(25), rmTilesToAreaFraction(50));
   rmAreaDefSetMix(beautificationAreaDefID, borderMixID);
   rmAreaDefAddConstraint(beautificationAreaDefID, vDefaultAvoidWater4);
   rmAreaDefAddOriginConstraint(beautificationAreaDefID, rmCreateClassDistanceConstraint(islandClassID, 16.0));
   rmAreaDefAddOriginConstraint(beautificationAreaDefID, rmCreateClassMaxDistanceConstraint(islandClassID, 20.0));
   rmAreaDefSetAvoidSelfDistance(beautificationAreaDefID, 1.0);
   rmAreaDefCreateAndBuildAreas(beautificationAreaDefID, 40 * cNumberPlayers * getMapAreaSizeFactor());

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
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidSiegeShipRange);

   int secondSettlementID = rmObjectDefCreate("second settlement");
   rmObjectDefAddItem(secondSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidWater);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidSiegeShipRange);
   rmObjectDefAddConstraint(secondSettlementID, avoidPlayerIsland);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidKotH);

   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(firstSettlementID, false, 1, 60.0, 80.0, cSettlementDist1v1, cBiasBackward, cInAreaDefault, cLocSideOpposite);
      addSimObjectLocsPerPlayerPair(secondSettlementID, false, 1, 60.0, 100.0, cSettlementDist1v1, cBiasAggressive);
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
      int thirdSettlementID = rmObjectDefCreate("third settlement");
      rmObjectDefAddItem(thirdSettlementID, cUnitTypeSettlement, 1);
      rmObjectDefAddConstraint(thirdSettlementID, vDefaultSettlementAvoidEdge);
      rmObjectDefAddConstraint(thirdSettlementID, vDefaultSettlementAvoidWater);
      rmObjectDefAddConstraint(thirdSettlementID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(thirdSettlementID, vDefaultAvoidCorner40);
      rmObjectDefAddConstraint(thirdSettlementID, vDefaultSettlementAvoidSiegeShipRange);
      rmObjectDefAddConstraint(thirdSettlementID, vDefaultAvoidKotH);
      if (insideBool == true)
      {
         rmObjectDefAddConstraint(thirdSettlementID, avoidPlayerIsland);
      }
      else
      {
         rmObjectDefAddConstraint(thirdSettlementID, playerIslandAvoidIsland);
      }
      addObjectLocsPerPlayer(thirdSettlementID, false, 1, 90.0, -1.0, 90.0);

      if (cMapSizeCurrent > cMapSizeLarge)
      {
         int fourthSettlementID = rmObjectDefCreate("fourth settlement");
         rmObjectDefAddItem(fourthSettlementID, cUnitTypeSettlement, 1);
         rmObjectDefAddConstraint(fourthSettlementID, vDefaultSettlementAvoidEdge);
         rmObjectDefAddConstraint(fourthSettlementID, vDefaultSettlementAvoidWater);
         rmObjectDefAddConstraint(fourthSettlementID, vDefaultAvoidTowerLOS);
         rmObjectDefAddConstraint(fourthSettlementID, vDefaultAvoidCorner40);
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
         addObjectLocsPerPlayer(fourthSettlementID, false, 1, 90.0, -1.0, 90.0);
      }
   }

   generateLocs("settlement locs");

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
   rmObjectDefAddItem(startingHuntID, cUnitTypeDeer, 8);
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
   rmObjectDefAddItem(startingHerdID, cUnitTypePig, xsRandInt(3, 4));
   rmObjectDefAddConstraint(startingHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidWater);
   addObjectLocsPerPlayer(startingHerdID, true, 1, cStartingHerdMinDist, cStartingHerdMaxDist);

   generateLocs("starting food locs");

   int resourceAvoidCenter = rmCreateClassDistanceConstraint(islandClassID, 20.0);

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
   rmObjectDefAddConstraint(playerGoldID, resourceAvoidCenter);
   if(gameIs1v1() == true && cMapSizeCurrent == cMapSizeStandard) 
   {
      addMirroredObjectLocsPerPlayerPair(playerGoldID, false, 1, 50.0, 70.0, avoidGoldMeters, cBiasNone, cInAreaPlayer);
      if(xsRandBool(0.5) == true)
      {
         addMirroredObjectLocsPerPlayerPair(playerGoldID, false, 1, 50.0, 90.0, avoidGoldMeters, cBiasNone, cInAreaPlayer);
      }

      addMirroredObjectLocsPerPlayerPair(playerGoldID, false, 1, 70.0, -1.0, avoidGoldMeters, cBiasNone, cInAreaPlayer);

      if(xsRandBool(0.5) == true)
      {
         addMirroredObjectLocsPerPlayerPair(playerGoldID, false, 1, 70.0, -1.0, avoidGoldMeters, cBiasNone, cInAreaPlayer);
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
      addSimObjectLocsPerPlayerPair(bonusGoldID, false, xsRandInt(1, 2) * getMapSizeBonusFactor(), 0.0, -1.0, avoidGoldMeters);
   }
   else
   {
      addObjectLocsPerPlayer(bonusGoldID, false, xsRandInt(1, 2) * getMapSizeBonusFactor(), 0.0, -1.0, avoidGoldMeters);
   }

   generateLocs("gold locs");

   rmSetProgress(0.6);

   // Hunt.
   float avoidPlayerHuntMeters = 30.0;

   // Close hunt.
   int closeHuntID = rmObjectDefCreate("close hunt");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeHippopotamus, xsRandInt(2, 3));
   }
   else
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeWaterBuffalo, xsRandInt(2, 3));
   }
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidWater);
   // rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(closeHuntID, resourceAvoidCenter);
   if(gameIs1v1() == true)
   {
      if(xsRandBool(2.0 / 3.0) == true)
      {
         rmObjectDefAddConstraint(closeHuntID, vDefaultForceInTowerLOS);
         addMirroredObjectLocsPerPlayerPair(closeHuntID, false, 1, 30.0, 50.0, avoidPlayerHuntMeters);
      }
      else
      {
         rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidTowerLOS);
         addMirroredObjectLocsPerPlayerPair(closeHuntID, false, 1, 50.0, 70.0, avoidPlayerHuntMeters);
      }
   }
   else if(xsRandBool(2.0 / 3.0) == true)
   {
      rmObjectDefAddConstraint(closeHuntID, vDefaultForceInTowerLOS);
      addObjectLocsPerPlayer(closeHuntID, false, 1, 30.0, 50.0, avoidPlayerHuntMeters, cBiasNone, cInAreaPlayer);
   }
   else
   {
      rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidTowerLOS);
      addObjectLocsPerPlayer(closeHuntID, false, 1, 50.0, 70.0, avoidPlayerHuntMeters, cBiasNone, cInAreaPlayer);
   }

   // Player hunt 1.
   float playerHunt1Float = xsRandFloat(0.0, 1.0);
   int playerHunt1ID = rmObjectDefCreate("player hunt 1");
   if(playerHunt1Float < 1.0 / 3.0)
   {
      rmObjectDefAddItem(playerHunt1ID, cUnitTypeWaterBuffalo, 2);
   }
   else if(playerHunt1Float < 2.0 / 3.0)
   {
      rmObjectDefAddItem(playerHunt1ID, cUnitTypeDeer, xsRandInt(5, 7));
   }
   else
   {
      rmObjectDefAddItem(playerHunt1ID, cUnitTypeHippopotamus, xsRandInt(3, 5));
   }
   rmObjectDefAddConstraint(playerHunt1ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(playerHunt1ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(playerHunt1ID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(playerHunt1ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(playerHunt1ID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(playerHunt1ID, resourceAvoidCenter);
   if(gameIs1v1() == true)
   {
      addMirroredObjectLocsPerPlayerPair(playerHunt1ID, false, 1 * getMapSizeBonusFactor(), 50.0, -1.0, avoidPlayerHuntMeters, cBiasNone, cInAreaPlayer);
   }
   else
   {
      addObjectLocsPerPlayer(playerHunt1ID, false, 1 * getMapSizeBonusFactor(), 50.0, -1.0, avoidPlayerHuntMeters, cBiasNone, cInAreaPlayer);
   }

   // Player hunt 2.
   float playerHunt2Float = xsRandFloat(0.0, 1.0);
   int playerHunt2ID = rmObjectDefCreate("player hunt 2");
   if(playerHunt2Float < 1.0 / 3.0)
   {
      rmObjectDefAddItem(playerHunt2ID, cUnitTypeWaterBuffalo, xsRandInt(2, 4));
      if(xsRandBool(0.5) == true)
      {
         rmObjectDefAddItem(playerHunt2ID, cUnitTypeDeer, xsRandInt(2, 4));
      }
   }
   else if(playerHunt2Float < 2.0 / 3.0)
   {
      rmObjectDefAddItem(playerHunt2ID, cUnitTypeDeer, xsRandInt(5, 9));
   }
   else
   {
      rmObjectDefAddItem(playerHunt2ID, cUnitTypeHippopotamus, xsRandInt(2, 3));
   }
   rmObjectDefAddConstraint(playerHunt2ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(playerHunt2ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(playerHunt2ID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(playerHunt2ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(playerHunt2ID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(playerHunt2ID, resourceAvoidCenter);
   if(gameIs1v1() == true)
   {
      addMirroredObjectLocsPerPlayerPair(playerHunt2ID, false, 1 * getMapSizeBonusFactor(), 50.0, -1.0, avoidPlayerHuntMeters, cBiasNone, cInAreaPlayer);
   }
   else
   {
      addObjectLocsPerPlayer(playerHunt2ID, false, 1 * getMapSizeBonusFactor(), 50.0, -1.0, avoidPlayerHuntMeters, cBiasNone, cInAreaPlayer);
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
   rmObjectDefAddConstraint(playerHunt3ID, resourceAvoidCenter);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(playerHunt3ID, false, 1 * getMapSizeBonusFactor(), 50.0, -1.0, 0.5 * avoidPlayerHuntMeters, cBiasNone, cInAreaPlayer);
   }
   else
   {
      addObjectLocsPerPlayer(playerHunt3ID, false, 1 * getMapSizeBonusFactor(), 50.0, -1.0, 0.5 * avoidPlayerHuntMeters, cBiasNone, cInAreaPlayer);
   }

   // Bonus hunt.
   float avoidBonusHuntMeters = 30.0;
   int numBonusHuntPerPlayer = 4 * getMapAreaSizeFactor();

   for(int i = 0; i < numBonusHuntPerPlayer; i++)
   {
      float bonusHuntFloat = xsRandFloat(0.0, 1.0);
      int bonusHuntID = rmObjectDefCreate("bonus hunt " + i);
      if(bonusHuntFloat < 1.0 / 3.0)
      {
         rmObjectDefAddItem(bonusHuntID, cUnitTypeBoar, xsRandInt(3, 5));
      }
      else if(bonusHuntFloat < 2.0 / 3.0)
      {
         rmObjectDefAddItem(bonusHuntID, cUnitTypeBoar, xsRandInt(4, 6));
         if(xsRandBool(0.5) == true)
         {
            rmObjectDefAddItem(bonusHuntID, cUnitTypeCrownedCrane, xsRandInt(4, 6));
         }
      }
      else
      {
         rmObjectDefAddItem(bonusHuntID, cUnitTypeWaterBuffalo, xsRandInt(3, 5));
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

   // Herdables.
   float avoidHerdMeters = 50.0;

   int closeHerdID = rmObjectDefCreate("close herd");
   rmObjectDefAddItem(closeHerdID, cUnitTypePig, xsRandInt(2, 3));
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidWater);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHerdID, avoidIsland);
   addObjectLocsPerPlayer(closeHerdID, false, 1, 50.0, 70.0, avoidHerdMeters);

   int bonusHerdID = rmObjectDefCreate("bonus herd");
   rmObjectDefAddItem(bonusHerdID, cUnitTypePig, xsRandInt(1, 2));
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidWater);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHerdID, avoidPlayerIsland);
   addObjectLocsPerPlayer(bonusHerdID, false, xsRandInt(1, 2) * getMapSizeBonusFactor(), 70.0, -1.0, avoidHerdMeters);

   generateLocs("herd locs");

   // Predators.
   float avoidPredatorMeters = 40.0;

   int playerPredatorID = rmObjectDefCreate("player predator");
   rmObjectDefAddItem(playerPredatorID, cUnitTypeCrocodile, 2);
   rmObjectDefAddConstraint(playerPredatorID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(playerPredatorID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(playerPredatorID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(playerPredatorID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(playerPredatorID, avoidIsland);
   rmObjectDefAddConstraint(playerPredatorID, vDefaultAvoidWater, cObjectConstraintBufferNone);
   rmObjectDefAddConstraint(playerPredatorID, rmCreateWaterMaxDistanceConstraint(true, 4.0), cObjectConstraintBufferNone);
   addObjectDefPlayerLocConstraint(bonusHerdID, 70.0);
   addObjectLocsPerPlayer(playerPredatorID, false, 1 * getMapSizeBonusFactor(), 70.0, -1.0, avoidPredatorMeters, cBiasNone, cInAreaNone);

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
   addObjectLocsPerPlayer(bonusPredatorID, false, 1 * getMapSizeBonusFactor(), 70.0, -1.0, avoidPredatorMeters, cBiasNone, cInAreaNone);

   generateLocs("predator locs");

   // Relics.
   float avoidRelicMeters = 50.0;

   int relicNumPerPlayer = 3 * getMapAreaSizeFactor();
   int numRelicsPerPlayer = min(relicNumPerPlayer * cNumberPlayers, cMaxRelics) / cNumberPlayers;

   int relicID = rmObjectDefCreate("relic");
   rmObjectDefAddItem(relicID, cUnitTypeRelic, 1);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidAll);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidWater);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(relicID, resourceAvoidCenter);
   addObjectLocsPerPlayer(relicID, false, numRelicsPerPlayer, 50.0, -1.0, avoidRelicMeters);

   generateLocs("relic locs");

   rmSetProgress(0.8);

   // Forests.
   int playerForestClassID = rmClassCreate();
   float avoidPlayerForestMeters = 30.0;

   int playerForestDefID = rmAreaDefCreate("player forest");
   rmAreaDefSetSizeRange(playerForestDefID, rmTilesToAreaFraction(60), rmTilesToAreaFraction(80));
   rmAreaDefSetForestType(playerForestDefID, cForestGreekOak);
   rmAreaDefSetAvoidSelfDistance(playerForestDefID, avoidPlayerForestMeters);
   rmAreaDefAddConstraint(playerForestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(playerForestDefID, vDefaultAvoidWater4);
   rmAreaDefAddConstraint(playerForestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(playerForestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddConstraint(playerForestDefID, rmCreateClassDistanceConstraint(islandClassID, 30.0));
   rmAreaDefAddToClass(playerForestDefID, playerForestClassID);

   // Starting forests.
   if(gameIs1v1() == true)
   {
      addSimAreaLocsPerPlayerPair(playerForestDefID, 3, cStartingForestMinDist, cStartingForestMaxDist, avoidPlayerForestMeters);
   }
   else
   {
      addAreaLocsPerPlayer(playerForestDefID, 3, cStartingForestMinDist, cStartingForestMaxDist, avoidPlayerForestMeters);
   }

   generateLocs("starting forest locs");

   // Avoid the owner paths to prevent forests from closing off resources.
   rmAreaDefAddConstraint(playerForestDefID, vDefaultAvoidOwnerPaths, 0.0);
   // rmAreaDefSetConstraintBuffer(playerForestDefID, 0.0, 6.0);

   // Build for each player in the team area.
   buildAreaDefInTeamAreas(playerForestDefID, 5 * getMapAreaSizeFactor());

   // Stragglers.
   placeStartingStragglers(cUnitTypeTreeOak);

   // Center forest.
   float avoidCenterForestMeters = 25.0;

   int centerForestDefID = rmAreaDefCreate("center forest");
   rmAreaDefSetSizeRange(centerForestDefID, rmTilesToAreaFraction(50), rmTilesToAreaFraction(70));
   rmAreaDefSetForestType(centerForestDefID, cForestMarsh);
   rmAreaDefSetAvoidSelfDistance(centerForestDefID, avoidCenterForestMeters);
   rmAreaDefAddConstraint(centerForestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(centerForestDefID, vDefaultAvoidWater6);
   rmAreaDefAddConstraint(centerForestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(centerForestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddConstraint(centerForestDefID, avoidPlayerIsland);
   rmAreaDefAddConstraint(centerForestDefID, rmCreateClassDistanceConstraint(playerForestClassID, avoidCenterForestMeters));

   // Avoid the owner paths to prevent forests from closing off resources.
   rmAreaDefAddConstraint(centerForestDefID, vDefaultAvoidOwnerPaths, 0.0);
   // rmAreaDefSetConstraintBuffer(centerForestDefID, 0.0, 6.0);
   
   buildAreaDefInTeamAreas(centerForestDefID, 8 * getMapAreaSizeFactor());

   rmSetProgress(0.9);

   // Gold areas.
   buildAreaUnderObjectDef(startingGoldID, cTerrainMarshGrassRocks2, cTerrainMarshGrassRocks1, 6.0);
   buildAreaUnderObjectDef(playerGoldID, cTerrainMarshGrassRocks2, cTerrainMarshGrassRocks1, 6.0);
   buildAreaUnderObjectDef(bonusGoldID, cTerrainMarshGrassRocks1, cTerrainMarshGrassWet1, 6.0);

   // Berries areas.
   buildAreaUnderObjectDef(startingBerriesID, cTerrainMarshGrass2, cTerrainMarshGrass1, 10.0);
   // buildAreaUnderObjectDef(berriesID, cTerrainMarshGrass2, cTerrainMarshGrass1, 10.0);

   // Random trees.
   int randomTree1ID = rmObjectDefCreate("random tree 1");
   rmObjectDefAddItem(randomTree1ID, cUnitTypeTreeOak, 1);
   rmObjectDefAddConstraint(randomTree1ID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTree1ID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTree1ID, vDefaultTreeAvoidWater);
   rmObjectDefAddConstraint(randomTree1ID, vDefaultTreeAvoidTree);
   rmObjectDefAddConstraint(randomTree1ID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefAddConstraint(randomTree1ID, avoidIsland);
   rmObjectDefPlaceAnywhere(randomTree1ID, 0, 5 * cNumberPlayers * getMapAreaSizeFactor());

   int randomTree2ID = rmObjectDefCreate("random tree 2");
   rmObjectDefAddItem(randomTree2ID, cUnitTypeTreeMarsh, 1);
   rmObjectDefAddConstraint(randomTree2ID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTree2ID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTree2ID, vDefaultTreeAvoidWater);
   rmObjectDefAddConstraint(randomTree2ID, vDefaultTreeAvoidTree);
   rmObjectDefAddConstraint(randomTree2ID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefAddConstraint(randomTree2ID, avoidPlayerIsland);
   rmObjectDefPlaceAnywhere(randomTree2ID, 0, 5 * cNumberPlayers * getMapAreaSizeFactor());

   // Rocks.
   int rockTinyID = rmObjectDefCreate("rock tiny");
   rmObjectDefAddItem(rockTinyID, cUnitTypeRockGreekTiny, 1);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefPlaceAnywhere(rockTinyID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());

   int rockSmallID = rmObjectDefCreate("rock small");
   rmObjectDefAddItem(rockSmallID, cUnitTypeRockGreekSmall, 1);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefPlaceAnywhere(rockSmallID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());

   // Logs.
   int logID = rmObjectDefCreate("log");
   rmObjectDefAddItem(logID, cUnitTypeRottingLog, 1);
   rmObjectDefAddConstraint(logID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(logID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefAddConstraint(logID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(logID, avoidPlayerIsland);
   rmObjectDefPlaceAnywhere(logID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   // Plants.
   int plantGrassID = rmObjectDefCreate("plant grass");
   rmObjectDefAddItem(plantGrassID, cUnitTypePlantMarshGrass, 1);
   rmObjectDefAddConstraint(plantGrassID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantGrassID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(plantGrassID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefAddConstraint(plantGrassID, avoidIsland);
   rmObjectDefPlaceAnywhere(plantGrassID, 0, 30 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantFernID = rmObjectDefCreate("plant fern");
   rmObjectDefAddItemRange(plantFernID, cUnitTypePlantMarshFern, 1, 2, 0.0, 4.0);
   rmObjectDefAddConstraint(plantFernID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantFernID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefPlaceAnywhere(plantFernID, 0, 20 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantWeedsID = rmObjectDefCreate("plant weeds");
   rmObjectDefAddItemRange(plantWeedsID, cUnitTypePlantMarshWeeds, 1, 3, 0.0, 4.0);
   rmObjectDefAddConstraint(plantWeedsID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantWeedsID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefPlaceAnywhere(plantWeedsID, 0, 20 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantBushID = rmObjectDefCreate("plant bush");
   rmObjectDefAddItem(plantBushID, cUnitTypePlantMarshBush, 1);
   rmObjectDefAddConstraint(plantBushID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantBushID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefPlaceAnywhere(plantBushID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantShrubID = rmObjectDefCreate("plant shrub");
   rmObjectDefAddItem(plantShrubID, cUnitTypePlantMarshShrub, 1);
   rmObjectDefAddConstraint(plantShrubID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantShrubID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefPlaceAnywhere(plantShrubID, 0, 30 * cNumberPlayers * getMapAreaSizeFactor());
   
   int mistID = rmObjectDefCreate("mist");
   rmObjectDefAddItem(mistID, cUnitTypeVFXMist, 1);
   rmObjectDefAddConstraint(mistID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(mistID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefAddConstraint(mistID, avoidPlayerIsland);
   rmObjectDefPlaceAnywhere(mistID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   // Water lilies.
   int lilyAvoidLand = rmCreateWaterDistanceConstraint(false, 2.0);
   int forceLilyNearLand = rmCreateWaterMaxDistanceConstraint(false, 6.0);

   int waterLilyID = rmObjectDefCreate("lily");
   rmObjectDefAddItem(waterLilyID, cUnitTypeWaterLily, 1);
   rmObjectDefAddConstraint(waterLilyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(waterLilyID, lilyAvoidLand, cObjectConstraintBufferNone);
   rmObjectDefAddConstraint(waterLilyID, forceLilyNearLand, cObjectConstraintBufferNone);
   rmObjectDefPlaceAnywhere(waterLilyID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   int waterLilyGroupID = rmObjectDefCreate("lily group");
   rmObjectDefAddItem(waterLilyGroupID, cUnitTypeWaterLily, xsRandInt(2, 4), 4.0);
   rmObjectDefAddConstraint(waterLilyGroupID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(waterLilyGroupID, lilyAvoidLand, cObjectConstraintBufferNone);
   rmObjectDefAddConstraint(waterLilyGroupID, forceLilyNearLand, cObjectConstraintBufferNone);
   rmObjectDefPlaceAnywhere(waterLilyGroupID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   // Reeds.
   int reedAvoidLand = rmCreateWaterDistanceConstraint(false, 2.0);
   int forceReedNearLand = rmCreateWaterMaxDistanceConstraint(false, 4.0);

   int waterReedID = rmObjectDefCreate("reed");
   rmObjectDefAddItem(waterReedID, cUnitTypeWaterReeds, 1);
   rmObjectDefAddConstraint(waterReedID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(waterReedID, reedAvoidLand, cObjectConstraintBufferNone);
   rmObjectDefAddConstraint(waterReedID, forceReedNearLand, cObjectConstraintBufferNone);
   rmObjectDefPlaceAnywhere(waterReedID, 0, 15 * cNumberPlayers * getMapAreaSizeFactor());

   int waterReedGroupID = rmObjectDefCreate("reed group");
   rmObjectDefAddItem(waterReedGroupID, cUnitTypeWaterReeds, xsRandInt(2, 4), 4.0);
   rmObjectDefAddConstraint(waterReedGroupID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(waterReedGroupID, reedAvoidLand, cObjectConstraintBufferNone);
   rmObjectDefAddConstraint(waterReedGroupID, forceReedNearLand, cObjectConstraintBufferNone);
   rmObjectDefPlaceAnywhere(waterReedGroupID, 0, 15 * cNumberPlayers * getMapAreaSizeFactor());

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeHawk, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   rmSetProgress(1.0);
}
