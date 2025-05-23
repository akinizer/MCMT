include "lib2/rm_core.xs";
include "lib2/rm_connections.xs";

void generate()
{
   rmSetProgress(0.0);

   // Define mixes.
   int baseMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.15, 5, 0.5);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseGrass2, 4.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseGrass1, 4.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseGrassRocks1, 1.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseGrassDirt1, 5.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseGrassDirt2, 5.0);

 // Set size.
   float sclr=1.5;
   if(cMapSizeCurrent == 1)
   {
      sclr=3;
   }
   
   rmSetMapSize(getScaledAxisTiles(144)*sclr);
   rmInitializeMix(baseMixID);

   // Player placement.
   rmSetTeamSpacingModifier(0.9);
   if (cNumberPlayers < 8)
   {
      rmPlacePlayersOnCircle(xsRandFloat(0.375, 0.4));
   }
   else
   {
      rmPlacePlayersOnCircle(xsRandFloat(0.4, 0.425));
   }

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCivFromCulture(cCultureNorse);

   // KotH.
   placeKotHObjects();

   // Lighting.
   rmSetLighting(cLightingSetRmMirkwood01);

   // Global elevation.
   rmAddGlobalHeightNoise(cNoiseFractalSum, 5.0, 0.1, 5, 0.3);
   
   rmSetProgress(0.1);
   
   // Player areas.
   int pathFindClassID = rmClassCreate();
   
   float playerAreaSize = rmTilesToAreaFraction(900);
   
   for(int i = 1; i <= cNumberPlayers; i++)
   {
      int p = vDefaultTeamPlayerOrder[i];

      int playerAreaID = rmAreaCreate("player area " + p);
      rmAreaSetSize(playerAreaID, playerAreaSize);
      rmAreaSetLocPlayer(playerAreaID, p);

      rmAreaSetCoherence(playerAreaID, 0.5);
      rmAreaSetBlobs(playerAreaID, 1, 5);
      rmAreaSetBlobDistance(playerAreaID, 10.0, 25.0);
      rmAreaSetEdgeSmoothDistance(playerAreaID, 2);

      rmAreaAddToClass(playerAreaID, pathFindClassID);
   }

   rmAreaBuildAll();
   
   int startingTownCenterID = placeStartingTownCenters();
   rmObjectDefAddToClass(startingTownCenterID, pathFindClassID);
   
   int avoidTownCenter = rmCreateTypeDistanceConstraint(cUnitTypeTownCenter, 30.0);

   // Player roads.
   int pathClassID = rmClassCreate();
   
   int avoidCenterConstraint = rmCreateLocDistanceConstraint(vectorXZ(xsRandFloat(0.45, 0.55), xsRandFloat(0.45, 0.55)), rmXFractionToMeters(xsRandFloat(0.1, 0.15)));
   int avoidCenterConstraintBonus = rmCreateLocDistanceConstraint(vectorXZ(xsRandFloat(0.45, 0.55), xsRandFloat(0.45, 0.55)), rmXFractionToMeters(xsRandFloat(0.275, 0.325)));
   
   // Bonus path in 1v1, avoiding the center.
   if(gameIs1v1() == true)
   {
      // Bonus path definition.
      int bonusPathDefID = rmPathDefCreate("player bonus connection path");
      rmPathDefAddConstraint(bonusPathDefID, avoidCenterConstraintBonus);
      rmPathDefAddConstraint(bonusPathDefID, rmCreateClassDistanceConstraint(pathClassID, 40.0), 20.0);
      rmPathDefSetCostNoise(bonusPathDefID, 0.0, 10.0);
      rmPathDefAddToClass(bonusPathDefID, pathClassID);
      
      // Bonus path areas built on the connections.
      int bonusPathAreaDefID = rmAreaDefCreate("player bonus connection area");
      rmAreaDefAddToClass(bonusPathAreaDefID, pathFindClassID);
      
      createPlayerConnections("player bonus connection 1", bonusPathDefID, bonusPathAreaDefID, 0.0);
      // createPlayerConnections("player bonus connection 2", bonusPathDefID, bonusPathAreaDefID, 0.0);
      // createPlayerConnections("player bonus connection 3", bonusPathDefID, bonusPathAreaDefID, 0.0);
   }

   // Player path definition.
   int pathDefID = rmPathDefCreate("player connection path def");
   rmPathDefSetCostNoise(pathDefID, 0.0, 10.0);
   rmPathDefSetAllTerrainCosts(pathDefID, 1000.0);
   if (xsRandInt(0, 3) == 0)
   {
      rmPathDefAddConstraint(pathDefID, avoidCenterConstraint);
   }
   rmPathDefAddToClass(pathDefID, pathClassID);

   // Player path areas built on the connections.
   int pathAreaDefID = rmAreaDefCreate("player connection area def");
   rmAreaDefSetTerrainType(pathAreaDefID, cTerrainNorseRoad);
   rmAreaDefAddToClass(pathAreaDefID, pathFindClassID);

   createPlayerConnections("player connection", pathDefID, pathAreaDefID, 0.0);

   // Starting towers.
   int startingTowerID = rmObjectDefCreate("starting tower");
   rmObjectDefAddItem(startingTowerID, cUnitTypeSentryTower, 1);
   rmObjectDefAddToClass(startingTowerID, pathFindClassID);
   addObjectLocsPerPlayer(startingTowerID, true, 4, cStartingTowerMinDist + 2, cStartingTowerMaxDist + 2, cStartingTowerAvoidanceMeters);
   generateLocs("starting tower locs");

   // Settlements.
   int stayNearPathConstraint50 = rmCreateClassMaxDistanceConstraint(pathFindClassID, 50.0);
   
   int firstSettlementID = rmObjectDefCreate("first settlement");
   rmObjectDefAddItem(firstSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(firstSettlementID, stayNearPathConstraint50);

   int secondSettlementID = rmObjectDefCreate("second settlement");
   rmObjectDefAddItem(secondSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(secondSettlementID, stayNearPathConstraint50);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidKotH);

   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(firstSettlementID, false, 1, 55.0, 80.0, cCloseSettlementDist, cBiasBackward);
      addSimObjectLocsPerPlayerPair(secondSettlementID, false, 1, 75.0, 95.0, cFarSettlementDist, cBiasAggressive);
   }
   else
   {
      addObjectLocsPerPlayer(firstSettlementID, false, 1, 55.0, 80.0, cCloseSettlementDist, cBiasBackward | cBiasAllyInside);
      addObjectLocsPerPlayer(secondSettlementID, false, 1, 80.0, 100.0, cFarSettlementDist, cBiasForward | cBiasAllyOutside);
   }

   // Other map sizes settlements.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int bonusSettlementID = rmObjectDefCreate("bonus settlement");
      rmObjectDefAddItem(bonusSettlementID, cUnitTypeSettlement, 1);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidEdge);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidCorner40);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidKotH, 5.0);
      addObjectLocsPerPlayer(bonusSettlementID, false, 1 * getMapAreaSizeFactor(), 90.0, -1.0, 100.0);
   }

   generateLocs("settlement locs", true, false, false, false);

   rmSetProgress(0.2);
   
   float settlementAreaMinSize = rmTilesToAreaFraction(250);
   float settlementAreaMaxSize = rmTilesToAreaFraction(300);

   // Build small areas around the settlements for stuff to spawn nearby.
   for(int i = 0; i < rmLocGenGetNumberLocs(); i++)
   {
      vector loc = rmLocGenGetLoc(i);
      int owner = rmLocGenGetLocOwner(i);
   
      int settlementAreaID = rmAreaCreate("settlement area" + i);
      rmAreaSetLoc(settlementAreaID, loc);
      rmAreaSetSize(settlementAreaID, xsRandFloat(settlementAreaMinSize, settlementAreaMaxSize));
      rmAreaSetCoherence(settlementAreaID, 0.25);
      rmAreaSetEdgeSmoothDistance(settlementAreaID, 2);
      rmAreaAddToClass(settlementAreaID, pathFindClassID);
      //rmAreaSetTerrainType(settlementAreaID, cTerrainDefaultBlack);
      
      rmAreaBuild(settlementAreaID);
   }
   
   // Connect first settlement to starting town center.
   for(int i = 1; i <= cNumberPlayers; i++)
   {
      int p = vDefaultTeamPlayerOrder[i];
      
      int settlementPathID = rmPathCreate("settlement path " + p);
      rmPathSetCostNoise(settlementPathID, 5.0, 10.0);
      rmPathSetAllTerrainCosts(settlementPathID, 100.0);
      rmPathSetTerrainCost(settlementPathID, cTerrainNorseRoad, 0.0);

      int locCount = 0;
      int numLocs = rmLocGenGetNumberLocs();
      // Find all settlement locations owned by this player.
      for(int j = 0; j < numLocs; j++)
      {
         int owner = rmLocGenGetLocOwner(j);
         if(owner != p)
         {
            continue;
         }

         vector loc = rmLocGenGetLoc(j);

         // Add the location to the path.
         rmPathAddWaypoint(settlementPathID, loc);

         // Also add the main TC after the first loc.
         if(locCount == 0)
         {
            rmPathAddWaypoint(settlementPathID, rmGetPlayerLoc(p));
         }

         locCount++;
      }

      rmPathBuild(settlementPathID);

      int connectionID = rmAreaCreate("settlement connection " + p);
      rmAreaSetCoherence(connectionID, 0.5);
      rmAreaSetPath(connectionID, settlementPathID, 0.0);
      rmAreaSetTerrainType(connectionID, cTerrainNorseRoad);
      rmAreaAddToClass(connectionID, pathFindClassID);
      rmAreaBuild(connectionID);
   }

   applyGeneratedLocs();
   resetLocGen();

   rmSetProgress(0.3);

   // Starting objects.
   int avoidRoad = rmCreateTerrainTypeDistanceConstraint(cTerrainNorseRoad, 1.0);
   
   // Starting gold.
   int startingGoldID = rmObjectDefCreate("starting gold");
   rmObjectDefAddItem(startingGoldID, cUnitTypeMineGoldMedium, 1);
   rmObjectDefAddConstraint(startingGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(startingGoldID, vDefaultStartingGoldAvoidTower);
   rmObjectDefAddConstraint(startingGoldID, vDefaultForceStartingGoldNearTower);
   rmObjectDefAddConstraint(startingGoldID, avoidRoad);
   rmObjectDefAddToClass(startingGoldID, pathFindClassID);
   addObjectLocsPerPlayer(startingGoldID, false, 1, cStartingGoldMinDist, cStartingGoldMaxDist, cStartingObjectAvoidanceMeters);

   generateLocs("starting gold locs");

   // Starting hunt.
   int startingHuntID = rmObjectDefCreate("starting hunt");
   rmObjectDefAddItem(startingHuntID, cUnitTypeElk, xsRandInt(8, 9));
   rmObjectDefAddConstraint(startingHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHuntID, vDefaultForceInTowerLOS);
   rmObjectDefAddToClass(startingHuntID, pathFindClassID);
   addObjectLocsPerPlayer(startingHuntID, false, 1, cStartingHuntMinDist, cStartingHuntMaxDist, cStartingObjectAvoidanceMeters);

   // Berries.
   int startingBerriesID = rmObjectDefCreate("starting berries");
   rmObjectDefAddItem(startingBerriesID, cUnitTypeBerryBush, xsRandInt(6, 9), cBerryClusterRadius);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(startingBerriesID, avoidRoad);
   rmObjectDefAddToClass(startingBerriesID, pathFindClassID);
   addObjectLocsPerPlayer(startingBerriesID, false, 1, cStartingBerriesMinDist, cStartingBerriesMaxDist, cStartingObjectAvoidanceMeters);

   // Chicken.
   int startingChickenID = rmObjectDefCreate("starting chicken");
   rmObjectDefAddItem(startingChickenID, cUnitTypeChicken, xsRandInt(5, 7));
   rmObjectDefAddConstraint(startingChickenID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidAll);
   rmObjectDefAddToClass(startingChickenID, pathFindClassID);
   addObjectLocsPerPlayer(startingChickenID, false, 1, cStartingChickenMinDist, cStartingChickenMaxDist, cStartingObjectAvoidanceMeters);

   // Herdables.
   int startingHerdID = rmObjectDefCreate("starting herd");
   rmObjectDefAddItem(startingHerdID, cUnitTypeCow, xsRandInt(2, 4));
   rmObjectDefAddConstraint(startingHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddToClass(startingHerdID, pathFindClassID);
   addObjectLocsPerPlayer(startingHerdID, true, 1, cStartingHerdMinDist, cStartingHerdMaxDist);

   generateLocs("starting food locs");

   rmSetProgress(0.4);
   
   int stayNearPathConstraint20 = rmCreateClassMaxDistanceConstraint(pathFindClassID, 20.0);

   // Gold.
   float avoidGoldMeters = 50.0;

   // Medium gold.
   int closeGoldID = rmObjectDefCreate("close gold");
   rmObjectDefAddItem(closeGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(closeGoldID, stayNearPathConstraint20, cObjectConstraintBufferNone);
   rmObjectDefAddConstraint(closeGoldID, avoidRoad);
   addObjectDefPlayerLocConstraint(closeGoldID, 55.0);
   rmObjectDefAddToClass(closeGoldID, pathFindClassID);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeGoldID, false, 1, 55.0, 65.0, avoidGoldMeters, cBiasForward);
      if(xsRandBool(0.5) == true)
      {
         addObjectLocsPerPlayer(closeGoldID, false, 1, 55.0, 70.0, avoidGoldMeters, cBiasForward);
      }
   }
   else
   {
      addObjectLocsPerPlayer(closeGoldID, false, 1, 50.0, 80.0, avoidGoldMeters);
   }

   // Bonus gold.
   int bonusGoldID = rmObjectDefCreate("bonus gold");
   rmObjectDefAddItem(bonusGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(bonusGoldID, stayNearPathConstraint20, cObjectConstraintBufferNone);
   rmObjectDefAddConstraint(bonusGoldID, avoidRoad);
   addObjectDefPlayerLocConstraint(bonusGoldID, 70.0);
   rmObjectDefAddToClass(bonusGoldID, pathFindClassID);

   if(gameIs1v1() == true)
   {
      addObjectLocsPerPlayer(bonusGoldID, false, xsRandInt(2, 3) * getMapAreaSizeFactor(), 70.0, -1.0, avoidGoldMeters);
   }
   else
   {
      addObjectLocsPerPlayer(bonusGoldID, false, xsRandInt(2, 3) * getMapAreaSizeFactor(), 70.0, -1.0, avoidGoldMeters);
   }

   generateLocs("gold locs");

   rmSetProgress(0.5);

   // Hunt.
   float avoidHuntMeters = 40.0;

   // Close hunt.
   int closeHuntID = rmObjectDefCreate("close hunt");
   rmObjectDefAddItem(closeHuntID, cUnitTypeDeer, xsRandInt(6, 9));
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(closeHuntID, stayNearPathConstraint20, cObjectConstraintBufferNone);
   rmObjectDefAddConstraint(closeHuntID, avoidRoad);
   addObjectDefPlayerLocConstraint(closeHuntID, 55.0);
   rmObjectDefAddToClass(closeHuntID, pathFindClassID);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeHuntID, false, 1, 55.0, 80.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(closeHuntID, false, 1, 55.0, 80.0, avoidHuntMeters);
   }
   
   generateLocs("close hunt locs");

   // Far hunt.
   float farHuntFloat = xsRandFloat(0.0, 1.0);
   int farHuntID = rmObjectDefCreate("far hunt");
   if(farHuntFloat < 1.0 / 3.0)
   {
      rmObjectDefAddItem(farHuntID, cUnitTypeElk, xsRandInt(5, 9));
   }
   else if(farHuntFloat < 2.0 / 3.0)
   {
      rmObjectDefAddItem(farHuntID, cUnitTypeCaribou, xsRandInt(5, 9));
   }
   else
   {
      rmObjectDefAddItem(farHuntID, cUnitTypeAurochs, xsRandInt(2, 3));
   }
   rmObjectDefAddConstraint(farHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(farHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(farHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(farHuntID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(farHuntID, stayNearPathConstraint20, cObjectConstraintBufferNone);
   rmObjectDefAddConstraint(farHuntID, avoidRoad);
   addObjectDefPlayerLocConstraint(farHuntID, 70.0);
   rmObjectDefAddToClass(farHuntID, pathFindClassID);
   if(gameIs1v1() == true)
   {
      addObjectLocsPerPlayer(farHuntID, false, 1, 70.0, -1.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(farHuntID, false, 1, 70.0, -1.0, avoidHuntMeters);
   }

   // Other map sizes hunt.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int numLargeMapHunt = 2 * getMapSizeBonusFactor();
      for(int i = 0; i < numLargeMapHunt; i++)
      {
         float largeMapHuntFloat = xsRandFloat(0.0, 1.0);
         int largeMapHuntID = rmObjectDefCreate("large map hunt" + i);
         if(largeMapHuntFloat < 1.0 / 3.0)
         {
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeAurochs, xsRandInt(2, 4));
         }
         else if(largeMapHuntFloat < 2.0 / 3.0)
         {
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeDeer, xsRandInt(7, 11));
         }
         else
         {
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeElk, xsRandInt(4, 8));
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeCaribou, xsRandInt(3, 7));
         }

         rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidEdge);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidAll);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidTowerLOS);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidSettlementRange);
         rmObjectDefAddConstraint(largeMapHuntID, stayNearPathConstraint20, cObjectConstraintBufferNone);
         rmObjectDefAddConstraint(largeMapHuntID, avoidRoad);
         addObjectDefPlayerLocConstraint(largeMapHuntID, 100.0);
         rmObjectDefAddToClass(largeMapHuntID, pathFindClassID);
         addObjectLocsPerPlayer(largeMapHuntID, false, 1, 100.0, -1.0, avoidHuntMeters);
      }
   }

   generateLocs("far hunt locs");

   rmSetProgress(0.6);

   // Berries.
   int berriesID = rmObjectDefCreate("berries");
   rmObjectDefAddItem(berriesID, cUnitTypeBerryBush, xsRandInt(7, 10), cBerryClusterRadius);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(berriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(berriesID, stayNearPathConstraint20, cObjectConstraintBufferNone);
   rmObjectDefAddConstraint(berriesID, avoidRoad);
   rmObjectDefAddToClass(berriesID, pathFindClassID);
   addObjectDefPlayerLocConstraint(berriesID, 80.0);
   addObjectLocsPerPlayer(berriesID, false, 1 * getMapSizeBonusFactor(), 80.0, -1.0, 40.0);

   generateLocs("berries locs");

   // Herdables.
   float avoidHerdMeters = 50.0;

   int closeHerdID = rmObjectDefCreate("close herd");
   rmObjectDefAddItem(closeHerdID, cUnitTypeCow, xsRandInt(2, 3));
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHerdID, stayNearPathConstraint20, cObjectConstraintBufferNone);
   rmObjectDefAddToClass(closeHerdID, pathFindClassID);
   addObjectLocsPerPlayer(closeHerdID, false, xsRandInt(1, 2), 50.0, 70.0, avoidHerdMeters);

   int bonusHerdID = rmObjectDefCreate("bonus herd");
   rmObjectDefAddItem(bonusHerdID, cUnitTypeCow, xsRandInt(1, 2));
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHerdID, stayNearPathConstraint20, cObjectConstraintBufferNone);
   rmObjectDefAddToClass(bonusHerdID, pathFindClassID);
   addObjectLocsPerPlayer(bonusHerdID, false, xsRandInt(1, 3) * getMapSizeBonusFactor(), 70.0, -1.0, avoidHerdMeters);

   generateLocs("herd locs");

   // Predators.
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
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(predatorID, stayNearPathConstraint20, cObjectConstraintBufferNone);
   addObjectDefPlayerLocConstraint(predatorID, 80.0);
   rmObjectDefAddToClass(predatorID, pathFindClassID);
   addObjectLocsPerPlayer(predatorID, false, xsRandInt(1, 2) * getMapAreaSizeFactor(), 80.0, -1.0, 50.0);

   generateLocs("predator locs");

   // Relics.
   int relicID = rmObjectDefCreate("relic");
   rmObjectDefAddItem(relicID, cUnitTypeRelic, 1);
   rmObjectDefAddItem(relicID, cUnitTypeColumns, xsRandInt(2, 3), 4.0);
   rmObjectDefAddItem(relicID, cUnitTypeColumnsBroken, xsRandInt(2, 3), 4.0);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidAll);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(relicID, stayNearPathConstraint20, cObjectConstraintBufferNone);
   addObjectDefPlayerLocConstraint(relicID, 70.0);
   rmObjectDefAddToClass(relicID, pathFindClassID);
   addObjectLocsPerPlayer(relicID, false, 2 * getMapAreaSizeFactor(), 70.0, -1.0, 80.0);

   generateLocs("relic locs");

   // Stragglers.
   int startingStragglerID = rmObjectDefCreate("starting straggler");
   rmObjectDefAddItem(startingStragglerID, cUnitTypeTreeOakAutumn, 1);
   rmObjectDefAddConstraint(startingStragglerID, vDefaultAvoidAll);
   rmObjectDefAddConstraint(startingStragglerID, rmCreateTerrainTypeDistanceConstraint(cTerrainNorseRoad, 2.0));
   addObjectLocsPerPlayer(startingStragglerID, false, xsRandInt(2, 4), 14.0, 18.0, 6.0);

   generateLocs("straggler locs");

   rmSetProgress(0.7);
   
   // Edge forests.
   int classOuterForestID = rmClassCreate();
   int classForestID = rmClassCreate();
   int avoidOuterForest = rmCreateClassDistanceConstraint(classOuterForestID, 1.0);
   int avoidPathClass10 = rmCreateClassDistanceConstraint(pathFindClassID, 10.0);

   for(int i = 0; i < 4; i++)
   {
      int outerForestID = rmAreaCreate("outer forest area " + i);
      rmAreaSetForestType(outerForestID, cForestNorseOakLateAutumn);
      rmAreaSetForestUnderbrushDensity(outerForestID, 1.0);
      rmAreaSetSize(outerForestID, 1.0);
      rmAreaSetCoherence(outerForestID, 1.0);
      rmAreaAddToClass(outerForestID, classOuterForestID);
      rmAreaAddToClass(outerForestID, classForestID);
      rmAreaSetForestUnderbrushDensity(outerForestID, 0.25);

      if (i == 0)
      {
         rmAreaSetLoc(outerForestID, cLocCornerNorth);
      }
      else if(i == 1)
      {
         rmAreaSetLoc(outerForestID, cLocCornerEast);
      }
      else if(i == 2)
      {
         rmAreaSetLoc(outerForestID, cLocCornerSouth);
      }
      else if(i == 3)
      {
         rmAreaSetLoc(outerForestID, cLocCornerWest);
      }

      rmAreaAddConstraint(outerForestID, avoidOuterForest);
      rmAreaAddConstraint(outerForestID, avoidPathClass10);
      rmAreaAddConstraint(outerForestID, vDefaultAvoidKotH);
   }

   rmAreaBuildAll();
   
   float forestMinSize = rmTilesToAreaFraction(1250);
   float forestMaxSize = rmTilesToAreaFraction(1500);
   
   for(int i = 1; i < 10 * cNumberPlayers * getMapAreaSizeFactor(); i++)
   {
      int forestID = rmAreaCreate("forest " + i);

      rmAreaSetSize(forestID, xsRandFloat(forestMinSize, forestMaxSize));
      rmAreaSetForestType(forestID, cForestNorseOakLateAutumn);
      rmAreaSetCoherence(forestID, 0.25);
      rmAreaSetForestUnderbrushDensity(forestID, 0.0);

      rmAreaAddConstraint(forestID, avoidPathClass10);
      rmAreaAddConstraint(forestID, rmCreateTypeDistanceConstraint(cUnitTypeTree, 12.0), 4.0);
      rmAreaAddConstraint(forestID, vDefaultAvoidSettlementRange);
      rmAreaAddConstraint(forestID, vDefaultAvoidKotH);
      rmAreaAddToClass(forestID, classForestID);
      
      rmAreaBuild(forestID);
      
      if(rmAreaGetTileCount(forestID) == 0)
      {
         break;
      }
   }

   rmSetProgress(0.8);

   // Embellishment.
   // Relic decoration.
   float relicAreaMinFraction = rmTilesToAreaFraction(10);
   float relicAreaMaxFraction = rmTilesToAreaFraction(20);

   int numRelics = rmObjectDefGetNumberCreatedObjects(relicID);

   for(int i = 0; i < numRelics; i++)
   {
      int objectID = rmObjectDefGetCreatedObject(relicID, i);
      vector objectLoc = rmObjectGetLoc(objectID);

      if(objectLoc == cInvalidVector)
      {
         continue;
      }

      int relicAreaID = rmAreaCreate("relic area " + i);
      rmAreaSetLoc(relicAreaID, objectLoc);
      rmAreaSetTerrainType(relicAreaID, cTerrainNorseRoad);
      rmAreaSetSize(relicAreaID, xsRandFloat(relicAreaMinFraction, relicAreaMaxFraction));

      rmAreaAddConstraint(relicAreaID, vDefaultAvoidImpassableLand4);

      rmAreaBuild(relicAreaID);
   }

   // Gold areas.
   buildAreaUnderObjectDef(startingGoldID, cTerrainNorseGrassRocks2, cTerrainNorseGrassRocks1, 6.0);
   buildAreaUnderObjectDef(closeGoldID, cTerrainNorseGrassRocks2, cTerrainNorseGrassRocks1, 6.0);
   buildAreaUnderObjectDef(bonusGoldID, cTerrainNorseGrassRocks2, cTerrainNorseGrassRocks1, 6.0);

   // Berries areas.
   buildAreaUnderObjectDef(startingBerriesID, cTerrainNorseGrass2, cTerrainNorseGrass1, 10.0);
   buildAreaUnderObjectDef(berriesID, cTerrainNorseGrass2, cTerrainNorseGrass1, 10.0);

   rmSetProgress(0.9);

   // Random trees.
   int randomTreeID = rmObjectDefCreate("random tree");
   rmObjectDefAddItem(randomTreeID, cUnitTypeTreeOakAutumn, 1);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidImpassableLand);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidTree);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefAddConstraint(randomTreeID, rmCreateTerrainTypeDistanceConstraint(cTerrainNorseRoad, 2.0));
   rmObjectDefPlaceAnywhere(randomTreeID, 0, 5 * cNumberPlayers * getMapAreaSizeFactor());

   // Rocks.
   int rockTinyID = rmObjectDefCreate("rock tiny");
   rmObjectDefAddItem(rockTinyID, cUnitTypeRockNorseTiny, 1);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefPlaceAnywhere(rockTinyID, 0, 35 * cNumberPlayers * getMapAreaSizeFactor());

   int rockSmallID = rmObjectDefCreate("rock small");
   rmObjectDefAddItem(rockSmallID, cUnitTypeRockNorseSmall, 1);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefPlaceAnywhere(rockSmallID, 0, 35 * cNumberPlayers * getMapAreaSizeFactor());

   // Plants.
   int avoidNorseRoad = rmCreateTerrainTypeDistanceConstraint(cTerrainNorseRoad, 1.0);

   int grassID = rmObjectDefCreate("grass");
   rmObjectDefAddItem(grassID, cUnitTypePlantNorseGrass, 1);
   rmObjectDefAddConstraint(grassID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(grassID, avoidNorseRoad);
   rmObjectDefPlaceAnywhere(grassID, 0, 35 * cNumberPlayers * getMapAreaSizeFactor());

   int bushID = rmObjectDefCreate("bush");
   rmObjectDefAddItem(bushID, cUnitTypePlantNorseBush, 1);
   rmObjectDefAddConstraint(bushID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(bushID, avoidNorseRoad);
   rmObjectDefPlaceAnywhere(bushID, 0, 15 * cNumberPlayers * getMapAreaSizeFactor());

   int shrubID = rmObjectDefCreate("shrub");
   rmObjectDefAddItem(shrubID, cUnitTypePlantNorseShrub, 1);
   rmObjectDefAddConstraint(shrubID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(shrubID, avoidNorseRoad);
   rmObjectDefPlaceAnywhere(shrubID, 0, 15 * cNumberPlayers * getMapAreaSizeFactor());

   int weedsID = rmObjectDefCreate("weeds");
   rmObjectDefAddItem(weedsID, cUnitTypePlantNorseWeeds, 1);
   rmObjectDefAddConstraint(weedsID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(weedsID, avoidNorseRoad);
   rmObjectDefPlaceAnywhere(weedsID, 0, 20 * cNumberPlayers * getMapAreaSizeFactor());

   // Logs
   int logID = rmObjectDefCreate("log");
   rmObjectDefAddItem(logID, cUnitTypeRottingLog, 1);
   rmObjectDefAddConstraint(logID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(logID, avoidNorseRoad);
   rmObjectDefPlaceAnywhere(logID, 0, 4 * cNumberPlayers * getMapAreaSizeFactor());

   int logGroupID = rmObjectDefCreate("log group");
   rmObjectDefAddItem(logGroupID, cUnitTypeRottingLog, 2, 2.0);
   rmObjectDefAddConstraint(logGroupID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(logGroupID, avoidNorseRoad);
   rmObjectDefPlaceAnywhere(logGroupID, 0, 3 * cNumberPlayers * getMapAreaSizeFactor());

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeHawk, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   rmSetProgress(1.0);
}
