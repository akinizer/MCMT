include "lib2/rm_core.xs";
include "lib2/rm_connections.xs";

void generate()
{
   rmSetProgress(0.0);

   // Define mixes.
   int baseMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.1, 5, 0.5);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainHadesDirt1, 3.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainHadesDirt2, 2.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainHadesDirtRocks1, 2.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainHadesDirtRocks2, 2.0);

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
   rmPlacePlayersOnCircle(0.35);

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCiv(cCivHades);

   // KotH.
   placeKotHObjects();

   // Lighting.
   rmSetLighting(cLightingSetRmErebus01);

   rmSetProgress(0.1);

   // Global elevation.
   rmAddGlobalHeightNoise(cNoiseFractalSum, 5.0, 0.075, 5, 0.5);

   // Pits will avoid all of these areas.
   int pitAvoidAreaClass = rmClassCreate();
   float islandDist = 25.0  * getMapAreaSizeFactor();

   // Player areas.
   int playerIslandClassID = rmClassCreate();
   int avoidPlayerIsland = rmCreateClassDistanceConstraint(playerIslandClassID, 0.1);
   int playerIslandAvoidPlayerIsland = rmCreateClassDistanceConstraint(playerIslandClassID, islandDist);

   for(int i = 1; i <= cNumberPlayers; i++)
   {
      int p = vDefaultTeamPlayerLocOrder[i];

      int playerIslandID = rmAreaCreate("player island " + p);
      rmAreaSetSize(playerIslandID, 1.0);
      rmAreaSetLocPlayer(playerIslandID, p);

      rmAreaSetCoherence(playerIslandID, 0.5);

      rmAreaAddConstraint(playerIslandID, playerIslandAvoidPlayerIsland);
      rmAreaAddToClass(playerIslandID, playerIslandClassID);
   }

   rmAreaBuildAll();

   // Team areas.
   int teamIslandClassID = rmClassCreate();
   int avoidTeamIsland = rmCreateClassDistanceConstraint(teamIslandClassID, 0.1);
   int teamIslandAvoidTeamIsland = rmCreateClassDistanceConstraint(teamIslandClassID, islandDist);

   for(int i = 1; i <= cNumberTeams; i++)
   {
      int teamIslandID = rmAreaCreate("team island " + i);
      rmAreaSetSize(teamIslandID, (xsIntToFloat(rmGetNumberPlayersOnTeam(i))) / cNumberPlayers);
      rmAreaSetLocTeam(teamIslandID, i);

      for(int j = 1; j <= cNumberPlayers; j++)
      {
         if(rmGetPlayerTeam(j) != i)
         {
            // Avoid player areas that don't belong to our team.
            rmAreaAddConstraint(teamIslandID, rmCreateAreaDistanceConstraint(rmAreaGetID("player island " + j), islandDist));
         }
      }
      rmAreaAddConstraint(teamIslandID, teamIslandAvoidTeamIsland);
      rmAreaAddToClass(teamIslandID, teamIslandClassID);
      rmAreaAddToClass(teamIslandID, pitAvoidAreaClass);
   }

   rmAreaBuildAll();

   rmSetProgress(0.2);

   // Clear out center.
   int centerAreaID = rmAreaCreate("center area");
   if(gameIs1v1() == true)
   {
      rmAreaSetSize(centerAreaID, 0.05);
   }
   else
   {
      rmAreaSetSize(centerAreaID, 0.075);
   }
   rmAreaSetLoc(centerAreaID, cCenterLoc);
   rmAreaSetCoherence(centerAreaID, 0.5);
   rmAreaAddToClass(centerAreaID, pitAvoidAreaClass);
   rmAreaBuild(centerAreaID);

   int avoidCenter = rmCreateAreaDistanceConstraint(centerAreaID, 0.1);

   // Connections.
   // Player road areas built on the connections.
   int pathAreaDefID = rmAreaDefCreate("player connection area");
   rmAreaDefAddToClass(pathAreaDefID, pitAvoidAreaClass);

   if(gameIs1v1() == true)
   {
      float pathAvoidCenterDist = 30.0 + (20.0 * getMapAreaSizeFactor());
      // 1v1: Have either 1 or 2 connections.
      int pathClass = rmClassCreate();

      int pathDefID = rmPathDefCreate("player connection path");
      // Add a penalty for the second path to get close to the first path so it goes the other way.
      rmPathDefAddConstraint(pathDefID, rmCreateClassDistanceConstraint(pathClass, 10.0), 100.0);
      rmPathDefAddConstraint(pathDefID, rmCreateAreaDistanceConstraint(centerAreaID, pathAvoidCenterDist));
      rmPathDefAddToClass(pathDefID, pathClass);

      // 50% chance for both connections.
      float connectionWidth = xsRandFloat(25.0, 30.0) * getMapAreaSizeFactor();
      createPlayerConnection("player connection 1", pathDefID, pathAreaDefID, connectionWidth, 5.0, 1, 2);
      // Currently always do this.
      if(xsRandBool(1.0) == true)
      {
         createPlayerConnection("player connection 2", pathDefID, pathAreaDefID, connectionWidth, 5.0, 2, 1);
      }
   }
   else
   {
      // Teamgames: Connect players as usual.
      int pathDefID = rmPathDefCreate("player connection path");
      rmPathDefAddConstraint(pathDefID, rmCreateAreaDistanceConstraint(centerAreaID, xsRandFloat(45.0, 60.0)));

      // Use both to build player connections.
      float connectionWidth = xsRandFloat(30.0, 40.0) * getMapAreaSizeFactor();
      createPlayerConnections("player connection", pathDefID, pathAreaDefID, connectionWidth, 5.0);
   }

   // Build lava stuff.
   int numPits = 3 * cNumberPlayers;
   int pitClassID = rmClassCreate();
   int pitAvoidOtherAreas = rmCreateClassDistanceConstraint(pitAvoidAreaClass, 0.1);

   for(int i = 0; i < numPits; i++)
   {
      int pitID = rmAreaCreate("separator pit " + i);      
      rmAreaSetSize(pitID, 1.0);
      // Add some buffer to make the pits look more random.
      rmAreaAddConstraint(pitID, pitAvoidOtherAreas, 0.0, 5.0);
      rmAreaAddToClass(pitID, pitAvoidAreaClass);
      rmAreaAddToClass(pitID, pitClassID);

      rmAreaSetHeightRelative(pitID, -8.0);

      rmAreaSetCliffType(pitID, cCliffHadesLava);
      rmAreaSetCliffSideRadius(pitID, 0, 3);
      // We only want lava inside, do not paint inner side.
      rmAreaSetCliffLayerPaint(pitID, cCliffLayerInnerSideClose, false);
      rmAreaSetCliffLayerPaint(pitID, cCliffLayerInnerSideFar, false);
      // Inside is fire, outside are rocks.
      rmAreaSetCliffLayerEmbellishmentDensity(pitID, cCliffLayerInside, 0.5);
      rmAreaSetCliffLayerEmbellishmentDensity(pitID, cCliffLayerOuterSideClose, 0.2);
      rmAreaSetCliffLayerEmbellishmentDensity(pitID, cCliffLayerOuterSideFar, 0.2);

      rmAreaBuild(pitID);
   }

   rmSetProgress(0.3);

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
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidImpassableLand);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidCorner40);

   int secondSettlementID = rmObjectDefCreate("second settlement");
   rmObjectDefAddItem(secondSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidImpassableLand);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidKotH);

   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(firstSettlementID, false, 1, 60.0, 80.0, cSettlementDist1v1, cBiasBackward);
      addSimObjectLocsPerPlayerPair(secondSettlementID, false, 1, 80.0, 120.0, cSettlementDist1v1, cBiasAggressive);
   }
   else
   {
      int allyBias = getRandomAllyBias();
      addObjectLocsPerPlayer(firstSettlementID, false, 1, 60.0, 80.0, cCloseSettlementDist, cBiasBackward | cBiasAllyInside);
      addObjectLocsPerPlayer(secondSettlementID, false, 1, 70.0, 100.0, cFarSettlementDist, cBiasAggressive | allyBias);
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
      addObjectLocsPerPlayer(bonusSettlementID, false, 1 * getMapAreaSizeFactor(), 90.0, -1.0, 100.0);
   }

   generateLocs("settlement locs");

   rmSetProgress(0.4);

   // Cliffs.
   int numCliffsPerPlayer = 2;
   int cliffClassID = rmClassCreate();
   float cliffMinSize = rmTilesToAreaFraction(300 * getMapAreaSizeFactor());
   float cliffMaxSize = rmTilesToAreaFraction(350 * getMapAreaSizeFactor());

   int cliffAvoidCliff = rmCreateClassDistanceConstraint(cliffClassID, 25.0);
   int cliffAvoidBuildings = rmCreateTypeDistanceConstraint(cUnitTypeBuilding, 15.0);
   int cliffAvoidEdge = createSymmetricBoxConstraint(rmXMetersToFraction(15.0), rmZMetersToFraction(15.0));

   for(int i = 1; i <= cNumberPlayers; i++)
   {
      int p = vDefaultTeamPlayerOrder[i];

      int parentAreaID = vPlayerLocAreaIDs[p];

      for(int j = 0; j < numCliffsPerPlayer; j++)
      {
         int cliffID = rmAreaCreate("cliff " + i + " " + j);
         rmAreaSetParent(cliffID, parentAreaID);

         rmAreaSetSize(cliffID, xsRandFloat(cliffMinSize, cliffMaxSize));
         rmAreaSetCliffType(cliffID, cCliffHadesDirt);
         // TODO More variance here.
         rmAreaSetCliffRamps(cliffID, 2, 0.25, 0.0, 1.0);
         rmAreaSetCliffRampSteepness(cliffID, 1.25);
         // rmAreaSetCliffEmbellishmentDensity(cliffID, 0.25);

         rmAreaSetCoherence(cliffID, 0.0);
         rmAreaSetHeightRelative(cliffID, 6.0);
         rmAreaAddHeightBlend(cliffID, cBlendAll, cFilter5x5Gaussian);
         rmAreaSetEdgeSmoothDistance(cliffID, 2);

         rmAreaSetOriginConstraintBuffer(cliffID, 15.0);
         rmAreaAddConstraint(cliffID, avoidCenter);
         rmAreaAddConstraint(cliffID, vDefaultAvoidImpassableLand8);
         rmAreaAddConstraint(cliffID, cliffAvoidCliff);
         rmAreaAddConstraint(cliffID, cliffAvoidBuildings);
         rmAreaAddConstraint(cliffID, cliffAvoidEdge);
         rmAreaSetConstraintBuffer(cliffID, 0.0, 10.0);
         rmAreaAddToClass(cliffID, cliffClassID);

         rmAreaBuild(cliffID);
      }
   }

   rmSetProgress(0.5);

   // Pits.
   int numPitsPerPlayer = 3;
   float pitMinSize = rmTilesToAreaFraction(75  * getMapAreaSizeFactor());
   float pitMaxSize = rmTilesToAreaFraction(125  * getMapAreaSizeFactor());

   int pitAvoidBuildings = rmCreateTypeDistanceConstraint(cUnitTypeBuilding, 18.0);

   for(int i = 1; i <= cNumberPlayers; i++)
   {
      int p = vDefaultTeamPlayerOrder[i];

      int parentAreaID = vPlayerLocAreaIDs[p];

      for(int j = 0; j < numPitsPerPlayer; j++)
      {
         int pitID = rmAreaCreate("player pit " + i + " " + j);
         rmAreaSetParent(pitID, parentAreaID);

         rmAreaSetSize(pitID, xsRandFloat(pitMinSize, pitMaxSize));
         // Add some buffer to make the pits look more random.

         rmAreaSetCliffType(pitID, cCliffHadesLava);
         rmAreaSetCliffSideRadius(pitID, 0, 2);
         // We only want lava inside, do not paint inner side.
         rmAreaSetCliffLayerPaint(pitID, cCliffLayerInnerSideClose, false);
         rmAreaSetCliffLayerPaint(pitID, cCliffLayerInnerSideFar, false);
         // Inside is fire, outside are rocks.
         rmAreaSetCliffLayerEmbellishmentDensity(pitID, cCliffLayerInside, 0.5);
         rmAreaSetCliffLayerEmbellishmentDensity(pitID, cCliffLayerOuterSideClose, 0.2);
         rmAreaSetCliffLayerEmbellishmentDensity(pitID, cCliffLayerOuterSideFar, 0.2);

         rmAreaSetHeightRelative(pitID, -6.0);

         rmAreaSetOriginConstraintBuffer(pitID, 10.0);
         rmAreaAddConstraint(pitID, avoidCenter);
         rmAreaAddConstraint(pitID, pitAvoidBuildings);
         rmAreaAddConstraint(pitID, vDefaultAvoidImpassableLand12);

         rmAreaBuild(pitID);
      }
   }

   rmSetProgress(0.6);

   // Create team road connections.
   // Team road path definition.
   int teamPathDef = rmPathDefCreate("team connection path");
   rmPathDefSetCostNoise(teamPathDef, 0.0, 1.0);
   rmPathDefAddConstraint(teamPathDef, vDefaultAvoidImpassableLand4);
   rmPathDefAddConstraint(teamPathDef, rmCreateTypeDistanceConstraint(cUnitTypeSentryTower, 5.0));
   // TODO Add random noise for the terrains we use for bonus randomness?

   // Player road areas built on the connections.
   int teamPathAreaDef = rmAreaDefCreate("team connection area");
   rmAreaDefSetTerrainType(teamPathAreaDef, cTerrainHadesRoad1);
   rmAreaDefAddConstraint(teamPathAreaDef, vDefaultAvoidImpassableLand4);

   // Use both to build ally connections.
   createAllyConnections("ally connection", teamPathDef, teamPathAreaDef, 2.0);

   rmSetProgress(0.7);

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

   // Starting hunt.
   int startingHuntID = rmObjectDefCreate("starting hunt");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeAurochs, xsRandInt(3, 4));
   }
   else
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeBoar, xsRandInt(4, 5));
   }
   rmObjectDefAddConstraint(startingHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(startingHuntID, vDefaultForceInTowerLOS);
   addObjectLocsPerPlayer(startingHuntID, false, 1, cStartingHuntMinDist, cStartingHuntMaxDist, cStartingObjectAvoidanceMeters);

   // No berries on this map.

   // Chicken.
   int startingChickenID = rmObjectDefCreate("starting chicken");
   rmObjectDefAddItem(startingChickenID, cUnitTypeChickenEvil, xsRandInt(9, 13));
   rmObjectDefAddConstraint(startingChickenID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidImpassableLand);
   addObjectLocsPerPlayer(startingChickenID, false, 1, cStartingChickenMinDist, cStartingChickenMaxDist, cStartingObjectAvoidanceMeters);

   // Herdables.
   int startingHerdID = rmObjectDefCreate("starting herd");
   rmObjectDefAddItem(startingHerdID, cUnitTypeGoat, xsRandInt(2, 3));
   rmObjectDefAddConstraint(startingHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidImpassableLand);
   addObjectLocsPerPlayer(startingHerdID, true, 1, cStartingHerdMinDist, cStartingHerdMaxDist);

   generateLocs("starting food locs");

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
   addObjectDefPlayerLocConstraint(closeGoldID, 50.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeGoldID, false, 1, 50.0, 60.0, avoidGoldMeters, cBiasForward);
   }
   else
   {
      addObjectLocsPerPlayer(closeGoldID, false, 1, 50.0, 60.0, avoidGoldMeters);
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
      addSimObjectLocsPerPlayerPair(bonusGoldID, false, xsRandInt(2, 3) * getMapAreaSizeFactor(), 70.0, -1.0, avoidGoldMeters);
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
   rmObjectDefAddItem(closeHunt1ID, cUnitTypeDeer, xsRandInt(4, 8));
   rmObjectDefAddConstraint(closeHunt1ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHunt1ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHunt1ID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHunt1ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHunt1ID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeHunt1ID, 50.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeHunt1ID, false, 1, 50.0, 80.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(closeHunt1ID, false, 1, 50.0, 80.0, avoidHuntMeters);
   }

   // Close hunt 2.
   int closeHunt2ID = rmObjectDefCreate("close hunt 2");
   rmObjectDefAddItem(closeHunt2ID, cUnitTypeBoar, xsRandInt(2, 5));
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(closeHunt2ID, cUnitTypeAurochs, xsRandInt(2, 4));
   }
   rmObjectDefAddConstraint(closeHunt2ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHunt2ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHunt2ID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHunt2ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHunt2ID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeHunt2ID, 50.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeHunt2ID, false, 1, 50.0, 80.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(closeHunt2ID, false, 1, 50.0, 80.0, avoidHuntMeters);
   }

   // Bonus hunt.
   int bonusHuntID = rmObjectDefCreate("bonus hunt");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(bonusHuntID, cUnitTypeAurochs, xsRandInt(2, 4));
   }
   else
   {
      rmObjectDefAddItem(bonusHuntID, cUnitTypeBoar, xsRandInt(2, 5));
   }
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(bonusHuntID, 80.0);
   addObjectLocsPerPlayer(bonusHuntID, false, 1, 80.0, -1.0, avoidHuntMeters);

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
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeBoar, xsRandInt(2, 5));
      }

      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidImpassableLand);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidSettlementRange);
      addObjectDefPlayerLocConstraint(largeMapHuntID, 80.0);
      addObjectLocsPerPlayer(largeMapHuntID, false, 2 * getMapAreaSizeFactor(), 100.0, -1.0, avoidHuntMeters);
   }

   generateLocs("hunt locs");

   // No berries on this map.

   // Herdables.
   float avoidHerdMeters = 50.0;

   int closeHerdID = rmObjectDefCreate("close herd");
   rmObjectDefAddItem(closeHerdID, cUnitTypeGoat, xsRandInt(1, 2));
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidTowerLOS);
   addObjectLocsPerPlayer(closeHerdID, false, 1, 50.0, 70.0, avoidHerdMeters);

   int bonusHerdID = rmObjectDefCreate("bonus herd");
   rmObjectDefAddItem(bonusHerdID, cUnitTypeGoat, xsRandInt(1, 3));
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidTowerLOS);
   addObjectLocsPerPlayer(bonusHerdID, false, xsRandInt(2, 3) * getMapAreaSizeFactor(), 70.0, -1.0, avoidHerdMeters);

   generateLocs("herd locs");

   // Predators.
   float avoidPredatorMeters = 50.0;

   int predatorID = rmObjectDefCreate("predator");
   rmObjectDefAddItem(predatorID, cUnitTypeShadePredator, 2);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(predatorID, 80.0);
   addObjectLocsPerPlayer(predatorID, false, 2 * getMapAreaSizeFactor(), 80.0, -1.0, avoidPredatorMeters);

   generateLocs("predator locs");

   // Relics.
   float avoidRelicMeters = 80.0;

   int relicID = rmObjectDefCreate("relic");
   rmObjectDefAddItem(relicID, cUnitTypeRelic, 1);
   rmObjectDefAddItem(relicID, cUnitTypeStatueMajorGod, 1);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidAll);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidImpassableLand4); // Map can get pretty cramped, so allow these to get close to cliffs etc.
   rmObjectDefAddConstraint(relicID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(relicID, 70.0);
   addObjectLocsPerPlayer(relicID, false, 2 * getMapAreaSizeFactor(), 70.0, -1.0, avoidRelicMeters);

   generateLocs("relic locs");

   rmSetProgress(0.8);

   // Forests.
   float avoidForestMeters = 25.0;

   int forestDefID = rmAreaDefCreate("forest");
   rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(60), rmTilesToAreaFraction(80));
   rmAreaDefSetForestType(forestDefID, cForestHades);
   rmAreaDefSetAvoidSelfDistance(forestDefID, avoidForestMeters);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidImpassableLand8);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddConstraint(forestDefID, rmCreateTerrainTypeDistanceConstraint(cTerrainHadesRoad1, 0.1));

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
   buildAreaDefInTeamAreas(forestDefID, 10 * getMapAreaSizeFactor());

   rmSetProgress(0.9);

   // Embellishment.
   buildAreaUnderObjectDef(startingGoldID, cTerrainHadesDirtRocks2, cTerrainHadesDirtRocks1, 6.0);
   buildAreaUnderObjectDef(closeGoldID, cTerrainHadesDirtRocks2, cTerrainHadesDirtRocks1, 6.0);
   buildAreaUnderObjectDef(bonusGoldID, cTerrainHadesDirtRocks2, cTerrainHadesDirtRocks1, 6.0);

   // Random trees.
   int randomTreeID = rmObjectDefCreate("random tree");
   rmObjectDefAddItem(randomTreeID, cUnitTypeTreeHades, 1);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidImpassableLand);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidTree);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefAddConstraint(randomTreeID, avoidCenter);
   rmObjectDefPlaceAnywhere(randomTreeID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   // Stalagmites.
   int stalagmiteAvoidBuilding = rmCreateTypeDistanceConstraint(cUnitTypeBuilding, 18.0);

   int stalagmiteID = rmObjectDefCreate("stalagmite");
   rmObjectDefAddItem(stalagmiteID, cUnitTypeStalagmite, 1);
   rmObjectDefAddConstraint(stalagmiteID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(stalagmiteID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(stalagmiteID, stalagmiteAvoidBuilding);
   rmObjectDefPlaceAnywhere(stalagmiteID, 0, 20 * cNumberPlayers * getMapAreaSizeFactor());

   int bushID = rmObjectDefCreate("bush");
   rmObjectDefAddItem(bushID, cUnitTypePlantHadesBush, 1);
   rmObjectDefAddConstraint(bushID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(bushID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefPlaceAnywhere(bushID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());

   int shrubID = rmObjectDefCreate("shrub");
   rmObjectDefAddItem(shrubID, cUnitTypePlantHadesShrub, 1);
   rmObjectDefAddConstraint(shrubID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(shrubID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefPlaceAnywhere(shrubID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());

   int fernID = rmObjectDefCreate("fern");
   rmObjectDefAddItem(fernID, cUnitTypePlantHadesFern, 1);
   rmObjectDefAddConstraint(fernID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(fernID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefPlaceAnywhere(fernID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   int weedsID = rmObjectDefCreate("weeds");
   rmObjectDefAddItem(weedsID, cUnitTypePlantHadesWeeds, 1);
   rmObjectDefAddConstraint(weedsID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(weedsID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefPlaceAnywhere(weedsID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeHarpy, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   rmSetProgress(1.0);
}
