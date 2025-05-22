include "lib2/rm_core.xs";
include "lib2/rm_connections.xs";

void generate()
{
   rmSetProgress(0.0);

   // Define mixes.
   int baseMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.15, 5, 0.5);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseSnow2, 4.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseSnow1, 3.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseSnowDirt1, 2.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseSnowDirt2, 1.0);

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
   if (gameIs1v1() == true)
   {
      placePlayersOnLine(vectorXZ(0.15, 0.5), vectorXZ(0.85, 0.5));
   }
   else if(cNumberTeams == 2)
   {
      if(rmGetNumberPlayersOnTeam(1) == 1)
      {
         int p = rmGetPlayerOnTeam(1, 0);
         rmPlacePlayer(p, vectorXZ(0.2, 0.5));
      }
      else if(rmGetNumberPlayersOnTeam(1) >= 8)
      {
         rmSetPlacementTeam(1);
         rmPlacePlayersOnCircle(0.175, 0.0, 0.0, 0.0, 1.0, vectorXZ(0.3, 0.5));
      }
      else 
      {
         rmSetPlacementTeam(1);
         rmPlacePlayersOnCircle(0.125, 0.0, 0.0, 0.0, 1.0, vectorXZ(0.2, 0.5));
      }

      if(rmGetNumberPlayersOnTeam(2) == 1)
      {
         int p = rmGetPlayerOnTeam(2, 0);
         rmPlacePlayer(p, vectorXZ(0.8, 0.5));
      }
      else if(rmGetNumberPlayersOnTeam(2) >= 8)
      {
         rmSetPlacementTeam(2);
         rmPlacePlayersOnCircle(0.175, 0.0, 0.0, 0.0, 1.0, vectorXZ(0.7, 0.5));
      }
      else
      {
         rmSetPlacementTeam(2);
         rmPlacePlayersOnCircle(0.125, 0.0, 0.0, cPi, 1.0, vectorXZ(0.8, 0.5));
      }
   }
   else
   {
      rmPlacePlayersOnCircle(0.35);
   }

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCiv(cCivThor);

   // KotH.
   placeKotHObjects();

   // Lighting.
   rmSetLighting(cLightingSetRmKerlaugar01);

   rmSetProgress(0.1);

   // Global elevation.
   rmAddGlobalHeightNoise(cNoiseFractalSum, 5.0, 0.1, 5, 0.3);

   // Settlements and towers.
   placeStartingTownCenters();

   // Starting towers.
   int startingTowerID = rmObjectDefCreate("starting tower");
   rmObjectDefAddItem(startingTowerID, cUnitTypeSentryTower, 1);
   addObjectLocsPerPlayer(startingTowerID, true, 4, cStartingTowerMinDist, cStartingTowerMaxDist, cStartingTowerAvoidanceMeters);
   generateLocs("starting tower locs");

   int pathDefID = rmPathDefCreate("river connection path");
   rmPathDefSetCostNoise(pathDefID, 0.0, 5.0);
   rmPathDefAddConstraint(pathDefID, createPlayerLocDistanceConstraint(50.0), 1000.0); // Fail softly in case we can't avoid this for some reason.
   rmPathDefAddConstraint(pathDefID, rmCreateBoxDistanceConstraint(cLocCornerWest, cLocCornerNorth, 50.0));
   rmPathDefAddConstraint(pathDefID, rmCreateBoxDistanceConstraint(cLocCornerSouth, cLocCornerEast, 50.0));

   // Rivers built on the path.
   int pathAreaDefID = rmAreaDefCreate("river connection area");
   rmAreaDefSetWaterType(pathAreaDefID, cWaterNorseHybrid);

   float riverWidth = 18.0 + (cNumberPlayers * getMapAreaSizeFactor());

   // TODO Consider mirroring the paths for 1v1.
   createLocConnection("lower river", pathDefID, pathAreaDefID, vectorXZ(0.0, 0.25), vectorXZ(1.0, 0.25), riverWidth, 5.0);
   createLocConnection("upper river", pathDefID, pathAreaDefID, vectorXZ(0.0, 0.75), vectorXZ(1.0, 0.75), riverWidth, 5.0);

   // Fake center area for constraints.
   int innerAreaID = rmAreaCreate("inner area");
   rmAreaSetLoc(innerAreaID, cCenterLoc);
   rmAreaSetSize(innerAreaID, 1.0);
   rmAreaSetCoherence(innerAreaID, 1.0);
   rmAreaAddConstraint(innerAreaID, vDefaultAvoidWater);
   rmAreaBuild(innerAreaID);

   int avoidInnerArea = rmCreateAreaDistanceConstraint(innerAreaID, 1.0);
   int forceInInnerArea = rmCreateAreaConstraint(innerAreaID);

   rmSetProgress(0.2);

   // Settlements.
   int firstSettlementID = rmObjectDefCreate("first settlement");
   rmObjectDefAddItem(firstSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidSiegeShipRange);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidKotH);
   addObjectDefPlayerLocConstraint(firstSettlementID, 60.0);

   int secondSettlementID = rmObjectDefCreate("second settlement");
   rmObjectDefAddItem(secondSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidSiegeShipRange);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidKotH);
   addObjectDefPlayerLocConstraint(secondSettlementID, 60.0);

   if(gameIs1v1() == true && cMapSizeCurrent == cMapSizeStandard)
   {
      rmObjectDefAddConstraint(firstSettlementID, forceInInnerArea);
      rmObjectDefAddConstraint(secondSettlementID, avoidInnerArea);
      addSimObjectLocsPerPlayerPair(firstSettlementID, false, 1, 60.0, 90.0, cSettlementDist1v1, cBiasForward);
      addSimObjectLocsPerPlayerPair(secondSettlementID, false, 1, 100.0, 130.0, cSettlementDist1v1, cBiasNotAggressive,
                                    cInAreaDefault, cLocSideOpposite);
   }
   else if (gameIsFair() == true)
   {
      rmObjectDefAddConstraint(firstSettlementID, forceInInnerArea);
      rmObjectDefAddConstraint(secondSettlementID, avoidInnerArea);
      addObjectLocsPerPlayer(firstSettlementID, false, 1, 60.0, 90.0, cCloseSettlementDist, cBiasForward);
      addObjectLocsPerPlayer(secondSettlementID, false, 1, 100.0, -1.0, cFarSettlementDist, cBiasForwardNotAggressive);
   }
   else
   {
      addObjectLocsPerPlayer(firstSettlementID, false, 1, 60.0, 90.0, cCloseSettlementDist, cBiasForward);
      addObjectLocsPerPlayer(secondSettlementID, false, 1, 80.0, -1.0, cFarSettlementDist, cBiasForward);   
   }
   
   // Other map sizes settlements.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int thirdSettlementID = rmObjectDefCreate("third settlement");
      rmObjectDefAddItem(thirdSettlementID, cUnitTypeSettlement, 1);
      rmObjectDefAddConstraint(thirdSettlementID, forceInInnerArea);
      rmObjectDefAddConstraint(thirdSettlementID, vDefaultSettlementAvoidEdge);
      rmObjectDefAddConstraint(thirdSettlementID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(thirdSettlementID, vDefaultSettlementAvoidSiegeShipRange);
      rmObjectDefAddConstraint(thirdSettlementID, vDefaultAvoidKotH);
      addObjectDefPlayerLocConstraint(thirdSettlementID, 60.0);

      if (cMapSizeCurrent > cMapSizeLarge)
      {
         int fourthSettlementID = rmObjectDefCreate("fourth settlement");
         rmObjectDefAddItem(fourthSettlementID, cUnitTypeSettlement, 1);
         rmObjectDefAddConstraint(fourthSettlementID, avoidInnerArea);
         rmObjectDefAddConstraint(fourthSettlementID, vDefaultSettlementAvoidEdge);
         rmObjectDefAddConstraint(fourthSettlementID, vDefaultAvoidTowerLOS);
         rmObjectDefAddConstraint(fourthSettlementID, vDefaultSettlementAvoidSiegeShipRange);
         rmObjectDefAddConstraint(fourthSettlementID, vDefaultAvoidKotH);
         addObjectDefPlayerLocConstraint(fourthSettlementID, 60.0);
      }
   }

   generateLocs("settlement locs");

   rmSetProgress(0.3);
   
   // Starting objects.
   // Starting gold.
   int startingGoldID = rmObjectDefCreate("starting gold");
   rmObjectDefAddItem(startingGoldID, cUnitTypeMineGoldMedium, 1);
   rmObjectDefAddConstraint(startingGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(startingGoldID, vDefaultGoldAvoidWater);
   rmObjectDefAddConstraint(startingGoldID, vDefaultStartingGoldAvoidTower);
   rmObjectDefAddConstraint(startingGoldID, vDefaultForceStartingGoldNearTower);
   addObjectLocsPerPlayer(startingGoldID, false, 1, cStartingGoldMinDist, cStartingGoldMaxDist, cStartingObjectAvoidanceMeters);

   generateLocs("starting gold locs");

   // Starting hunt.
   int startingHuntID = rmObjectDefCreate("starting hunt");
   rmObjectDefAddItem(startingHuntID, cUnitTypeCaribou, xsRandInt(8, 9));
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
   addObjectLocsPerPlayer(startingBerriesID, false, 1, 2 + cStartingBerriesMinDist, 2 + cStartingBerriesMaxDist, cStartingObjectAvoidanceMeters);
   
   // Chicken.
   int startingChickenID = rmObjectDefCreate("starting chicken");
   // Set chicken variation, excluding whites, as they are hard to see on snow maps.
   int chickenNum = xsRandInt(5, 7);
   for (int i = 0; i < chickenNum; i++)
   {
      rmObjectDefAddItem(startingChickenID, cUnitTypeChicken, 1);
      rmObjectDefSetItemVariation(startingChickenID, i, xsRandInt(cChickenVariationBrown, cChickenVariationBlack));
   }
   rmObjectDefAddConstraint(startingChickenID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidWater);
   addObjectLocsPerPlayer(startingChickenID, false, 1, cStartingChickenMinDist, cStartingChickenMaxDist, cStartingObjectAvoidanceMeters);

   // Herdables.
   int startingHerdID = rmObjectDefCreate("starting herd");
   rmObjectDefAddItem(startingHerdID, cUnitTypeCow, xsRandInt(2, 4));
   rmObjectDefAddConstraint(startingHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidWater);
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
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidPassableWater20);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeGoldID, 50.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeGoldID, false, 1, 50.0, 75.0, avoidGoldMeters, cBiasNone,
                          cInAreaDefault, cLocSideOpposite);
   }
   else
   {
      addObjectLocsPerPlayer(closeGoldID, false, 1, 55.0, 70.0, avoidGoldMeters);
   }

   // Bonus gold.
   int bonusGoldID = rmObjectDefCreate("bonus gold");
   rmObjectDefAddItem(bonusGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidPassableWater20);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(bonusGoldID, 75.0);

   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusGoldID, false, xsRandInt(2, 3) * getMapAreaSizeFactor(), 75.0, -1.0, avoidGoldMeters,
                                    cBiasNone, cInAreaDefault, cLocSideOpposite);
   }
   else
   {
      addObjectLocsPerPlayer(bonusGoldID, false, xsRandInt(2, 3) * getMapAreaSizeFactor(), 75.0, -1.0, avoidGoldMeters);
   }

   generateLocs("gold locs");

   rmSetProgress(0.5);

   // Hunt.
   float avoidHuntMeters = 40.0;

   // Close hunt.
   int closeHuntID = rmObjectDefCreate("close hunt");
   rmObjectDefAddItem(closeHuntID, cUnitTypeCaribou, xsRandInt(3, 5));
   rmObjectDefAddItem(closeHuntID, cUnitTypeElk, xsRandInt(3, 5));
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidSettlementRange);
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
   rmObjectDefAddConstraint(farHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(farHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(farHuntID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(farHuntID, 90.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(farHuntID, false, xsRandInt(1, 2), 90.0, 130.0, avoidHuntMeters, cBiasNone,
                          cInAreaDefault, cLocSideOpposite);
   }
   else
   {
      addObjectLocsPerPlayer(farHuntID, false, xsRandInt(1, 2), 90.0, -1.0, avoidHuntMeters);
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
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeBoar, xsRandInt(3, 6));
         }
         else if(largeMapHuntFloat < 2.0 / 3.0)
         {
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeCaribou, xsRandInt(6, 9));
         }
         else
         {
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeAurochs, xsRandInt(2, 5));
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeElk, xsRandInt(3, 6));
         }

         rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidEdge);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidAll);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidWater);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidTowerLOS);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidSettlementRange);
         addObjectDefPlayerLocConstraint(largeMapHuntID, 100.0);
         addObjectLocsPerPlayer(largeMapHuntID, false, 1, 100.0, -1.0, avoidHuntMeters);
      }
   }

   generateLocs("hunt locs");

   rmSetProgress(0.6);

   // Berries.
   float avoidBerriesMeters = 50.0;

   int farBerries1ID = rmObjectDefCreate("far berries 1");
   rmObjectDefAddItem(farBerries1ID, cUnitTypeBerryBush, xsRandInt(7, 10), cBerryClusterRadius);
   rmObjectDefAddConstraint(farBerries1ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(farBerries1ID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(farBerries1ID, vDefaultBerriesAvoidWater);
   rmObjectDefAddConstraint(farBerries1ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(farBerries1ID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(farBerries1ID, 70.0);
   addObjectLocsPerPlayer(farBerries1ID, false, 1 * getMapAreaSizeFactor(), 70.0, 120.0, avoidBerriesMeters);

   int farBerries2ID = rmObjectDefCreate("far berries 2");
   rmObjectDefAddItem(farBerries2ID, cUnitTypeBerryBush, xsRandInt(6, 10), cBerryClusterRadius);
   rmObjectDefAddConstraint(farBerries2ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(farBerries2ID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(farBerries2ID, vDefaultBerriesAvoidWater);
   rmObjectDefAddConstraint(farBerries2ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(farBerries2ID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(farBerries2ID, 70.0);
   addObjectLocsPerPlayer(farBerries2ID, false, 1 * getMapSizeBonusFactor(), 75.0, -1.0, avoidBerriesMeters);

   generateLocs("berries locs");

   // Herdables.
   float avoidHerdMeters = 40.0;

   int closeHerdID = rmObjectDefCreate("close herd");
   rmObjectDefAddItem(closeHerdID, cUnitTypeCow, xsRandInt(2, 3));
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidWater);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidTowerLOS);
   addObjectDefPlayerLocConstraint(closeHerdID, 50.0);
   addObjectLocsPerPlayer(closeHerdID, false, 1, 50.0, 70.0, avoidHerdMeters);

   int bonusHerdID = rmObjectDefCreate("bonus herd");
   rmObjectDefAddItem(bonusHerdID, cUnitTypeCow, xsRandInt(1, 2));
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidWater);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidTowerLOS);
   addObjectDefPlayerLocConstraint(bonusHerdID, 70.0);
   addObjectLocsPerPlayer(bonusHerdID, false, xsRandInt(1, 2) * getMapSizeBonusFactor(), 70.0, -1.0, avoidHerdMeters);

   generateLocs("herd locs");

   // Predators.
   float avoidPredatorMeters = 50.0;

   int predatorID = rmObjectDefCreate("predator");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(predatorID, cUnitTypeArcticWolf, xsRandInt(2, 3));
   }
   else
   {
      rmObjectDefAddItem(predatorID, cUnitTypePolarBear, xsRandInt(1, 2));
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

   // Fish.
   int fishID = rmObjectDefCreate("global fish");
   rmObjectDefAddItem(fishID, cUnitTypePerch, 3, 6.0);

   if(gameIs1v1() == true)
   {
      int numFishPerRiver = 6 * getMapSizeBonusFactor();
      int numEdgeBufferTiles = 5 * xsRandInt(2, 4);
      int tileVariance = min(2, numEdgeBufferTiles);

      // Go along the path and place like that.
      int numPaths = rmPathDefGetNumberCreatedPaths(pathDefID);
      for(int i = 0; i < numPaths; i++)
      {
         int pathID = rmPathDefGetCreatedPath(pathDefID, i);
         vector[] pathTiles = rmPathGetTiles(pathID);
         int numPathTiles = pathTiles.size();

         int placementInterval = (numPathTiles - 2 * numEdgeBufferTiles) / max(1, numFishPerRiver - 1);
         placementInterval = max(1, placementInterval);

         int nextTileIndex = numEdgeBufferTiles;

         for(int j = 0; j < numFishPerRiver; j++)
         {
            int tileIdx = nextTileIndex + xsRandInt(-tileVariance, tileVariance);
            vector tileLoc = rmTileIndexToFraction(pathTiles[tileIdx]);
            rmObjectDefPlaceAtLoc(fishID, 0, tileLoc);
            nextTileIndex += placementInterval;
         }
      }
   }
   else
   {
      float fishDistMeters = 25.0;

      rmObjectDefAddConstraint(fishID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(fishID, rmCreatePassabilityDistanceConstraint(cPassabilityWater, false, 1.0));
      rmObjectDefAddConstraint(fishID, rmCreateTypeDistanceConstraint(cUnitTypeFishResource, fishDistMeters));

      rmObjectDefPlaceAnywhere(fishID, 0, 4 * cNumberPlayers * getMapAreaSizeFactor());
   }
   
   rmSetProgress(0.8);

   // Forests.
   float avoidForestMeters = 25.0;

   int forestDefID = rmAreaDefCreate("forest");
   rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(70), rmTilesToAreaFraction(100));
   if(xsRandBool(0.5) == true)
   {
      rmAreaDefSetForestType(forestDefID, cForestNorsePineSnowMix);
   }
   else
   {
      rmAreaDefSetForestType(forestDefID, cForestNorsePineSnow);
   }
   rmAreaDefSetAvoidSelfDistance(forestDefID, avoidForestMeters);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidWater8);
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
   buildAreaDefInTeamAreas(forestDefID, 10 * getMapAreaSizeFactor());

   // Stragglers.
   placeStartingStragglers(cUnitTypeTreePineSnow);

   rmSetProgress(0.9);

   // Gold areas.
   buildAreaUnderObjectDef(startingGoldID, cTerrainNorseSnowRocks2, cTerrainNorseSnowRocks1, 6.0);
   buildAreaUnderObjectDef(closeGoldID, cTerrainNorseSnowRocks2, cTerrainNorseSnowRocks1, 6.0);
   buildAreaUnderObjectDef(bonusGoldID, cTerrainNorseSnowRocks2, cTerrainNorseSnowRocks1, 6.0);

   // Berries areas.
   buildAreaUnderObjectDef(startingBerriesID, cTerrainNorseSnowGrass3, cTerrainNorseSnowGrass2, 10.0);
   buildAreaUnderObjectDef(farBerries1ID, cTerrainNorseSnowGrass3, cTerrainNorseSnowGrass2, 10.0);
   buildAreaUnderObjectDef(farBerries2ID, cTerrainNorseSnowGrass3, cTerrainNorseSnowGrass2, 10.0);

   // Random trees.
   int randomTreeID = rmObjectDefCreate("random tree");
   rmObjectDefAddItem(randomTreeID, cUnitTypeTreePineSnow, 1);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidWater);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidTree);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefPlaceAnywhere(randomTreeID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   // Rocks.
   int rockTinyID = rmObjectDefCreate("rock tiny");
   rmObjectDefAddItem(rockTinyID, cUnitTypeRockNorseTiny, 1);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefPlaceAnywhere(rockTinyID, 0, 35 * cNumberPlayers * getMapAreaSizeFactor());

   int rockSmallID = rmObjectDefCreate("rock small");
   rmObjectDefAddItem(rockSmallID, cUnitTypeRockNorseSmall, 1);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefPlaceAnywhere(rockSmallID, 0, 35 * cNumberPlayers * getMapAreaSizeFactor());

   // Reeds.
   int reedAvoidLand = rmCreateWaterDistanceConstraint(false, 4.0);
   int reedForceNearLand = rmCreateWaterMaxDistanceConstraint(false, 7.0);

   int waterReedID = rmObjectDefCreate("reed");
   rmObjectDefAddItem(waterReedID, cUnitTypeWaterReeds, 1);
   rmObjectDefAddConstraint(waterReedID, vDefaultAvoidAll2);
   rmObjectDefAddConstraint(waterReedID, reedAvoidLand);
   rmObjectDefAddConstraint(waterReedID, reedForceNearLand);
   rmObjectDefPlaceAnywhere(waterReedID, 0, 40 * cNumberPlayers * getMapAreaSizeFactor());

   // Plants.
   int plantBushID = rmObjectDefCreate("plant bush");
   rmObjectDefAddItem(plantBushID, cUnitTypePlantSnowBush, 1);
   rmObjectDefAddConstraint(plantBushID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantBushID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefPlaceAnywhere(plantBushID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantShrubID = rmObjectDefCreate("plant shrub");
   rmObjectDefAddItem(plantShrubID, cUnitTypePlantSnowShrub, 1);
   rmObjectDefAddConstraint(plantShrubID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantShrubID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefPlaceAnywhere(plantShrubID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantGrassID = rmObjectDefCreate("plant grass");
   rmObjectDefAddItem(plantGrassID, cUnitTypePlantSnowGrass, 1);
   rmObjectDefAddConstraint(plantGrassID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantGrassID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefAddConstraint(plantGrassID, vDefaultAvoidEdge);
   rmObjectDefPlaceAnywhere(plantGrassID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantFernID = rmObjectDefCreate("plant fern");
   rmObjectDefAddItem(plantFernID, cUnitTypePlantSnowFern, 1);
   rmObjectDefAddConstraint(plantFernID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantFernID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefPlaceAnywhere(plantFernID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantWeedsID = rmObjectDefCreate("plant weeds");
   rmObjectDefAddItem(plantWeedsID, cUnitTypePlantSnowWeeds, 1);
   rmObjectDefAddConstraint(plantWeedsID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantWeedsID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefPlaceAnywhere(plantWeedsID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeHawk, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   rmSetProgress(1.0);
}
