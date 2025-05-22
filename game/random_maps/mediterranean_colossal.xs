include "lib2/rm_core.xs";

void generate()
{
   rmSetProgress(0.0);

   // Define mixes.
   int baseMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.2, 5, 0.5);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainGreekGrass2, 2.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainGreekGrass1, 3.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainGreekGrassDirt1, 3.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainGreekGrassDirt2, 3.0);

   // Water overrides.
   rmWaterTypeAddBeachLayer(cWaterGreekSeaAegean, cTerrainGreekBeach1, 2.0, 0.0);
   rmWaterTypeAddBeachLayer(cWaterGreekSeaAegean, cTerrainGreekGrassDirt3, 4.0, 0.0);
   rmWaterTypeAddBeachLayer(cWaterGreekSeaAegean, cTerrainGreekGrassDirt2, 6.0, 0.0);
   rmWaterTypeAddBeachLayer(cWaterGreekSeaAegean, cTerrainGreekGrassDirt1, 8.0, 0.0);

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
   // rmInitializeLand(cTerrainDefaultBlack);

   // Player placement.
   if(gameIs1v1() == true)
   {
      rmPlacePlayersOnCircle(0.375);
   }
   else
   {
      rmSetTeamSpacingModifier(xsRandFloat(0.8, 0.85));
      rmPlacePlayersOnCircle(0.35);
   }

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCivFromCulture(cCultureGreek);

   // Lighting.
   rmSetLighting(cLightingSetRmMediterranean01);

   rmSetProgress(0.1);

   // Global elevation.
   rmAddGlobalHeightNoise(cNoiseFractalSum, 5.0, 0.05, 2, 0.25);

   // Player base areas.
   int playerAreaClassID = rmClassCreate();
   float playerBaseAreaSize = rmRadiusToAreaFraction(52.5);

   for(int i = 1; i <= cNumberPlayers; i++)
   {
      int p = vDefaultTeamPlayerOrder[i];

      int playerBaseAreaID = rmAreaCreate("player base area " + p);
      rmAreaSetLocPlayer(playerBaseAreaID, p);
      rmAreaSetSize(playerBaseAreaID, playerBaseAreaSize);

      rmAreaSetCoherence(playerBaseAreaID, 0.25);
      rmAreaSetEdgeSmoothDistance(playerBaseAreaID, 3);
      rmAreaAddToClass(playerBaseAreaID, playerAreaClassID);
   }

   rmAreaBuildAll();

   // Sea.
   int seaAreaID = rmAreaCreate("sea");
   rmAreaSetWaterType(seaAreaID, cWaterGreekSeaAegean);
   rmAreaSetLoc(seaAreaID, cCenterLoc);
   if(gameIs1v1() == true)
   {
      rmAreaSetSize(seaAreaID, 0.15);
   }
   else
   {
      rmAreaSetSize(seaAreaID, 0.18);
   }

   if (gameIs1v1() == false)
   {
      rmAreaSetBlobDistance(seaAreaID, 1.0 * rmGetMapXTiles() / 10.0, 1.0 * rmGetMapZTiles() / 5.0);
      rmAreaSetBlobs(seaAreaID, 8, 10);
   }

   rmAreaSetCoherence(seaAreaID, 0.25);
   rmAreaSetEdgeSmoothDistance(seaAreaID, 5);
   rmAreaSetWaterHeightBlend(seaAreaID, cFilter5x5Gaussian, 25, 10);
   rmAreaAddConstraint(seaAreaID, rmCreateClassDistanceConstraint(playerAreaClassID, 1.0));

   rmAreaBuild(seaAreaID);

   // KotH.
   if (gameIsKotH() == true)
   {
      int islandKotHID = rmAreaCreate("koth island");
      rmAreaSetSize(islandKotHID, rmRadiusToAreaFraction(15.0 * sqrt(cNumberPlayers)));
      rmAreaSetLoc(islandKotHID, cCenterLoc);
      //rmAreaSetMix(islandKotHID, baseMixID);

      rmAreaSetCoherence(islandKotHID, 0.25);
      rmAreaSetEdgeSmoothDistance(islandKotHID, 5);
      rmAreaSetHeight(islandKotHID, 0.0);
      rmAreaSetHeightNoise(islandKotHID, cNoiseFractalSum, 5.0, 0.05, 2, 0.25);
      rmAreaSetHeightNoiseBias(islandKotHID, 1.0); // Only grow upwards.
      rmAreaSetHeightNoiseEdgeFalloffDist(islandKotHID, 20.0);
      rmAreaAddHeightBlend(islandKotHID, cBlendEdge, cFilter5x5Box, 10.0, 5.0);
      
      rmAreaAddToClass(islandKotHID, vKotHClassID);

      rmAreaBuild(islandKotHID);
   }

   placeKotHObjects();

   rmSetProgress(0.2);

   // Settlements and towers.
   placeStartingTownCenters();

   // Starting towers.
   int startingTowerID = rmObjectDefCreate("starting tower");
   rmObjectDefAddItem(startingTowerID, cUnitTypeSentryTower, 1);
   addObjectLocsPerPlayer(startingTowerID, true, 4, cStartingTowerMinDist, cStartingTowerMaxDist, cStartingTowerAvoidanceMeters);
   generateLocs("starting tower locs");

   // Settlements.
   int firstSettlementID = rmObjectDefCreate("first settlement");
   rmObjectDefAddItem(firstSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidSiegeShipRange);

   int secondSettlementID = rmObjectDefCreate("second settlement");
   rmObjectDefAddItem(secondSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidSiegeShipRange);

   // TODO More variations.
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(firstSettlementID, false, 1, 60.0, 80.0, cSettlementDist1v1, cBiasBackward,
                          cInAreaDefault, cLocSideOpposite);

      addSimObjectLocsPerPlayerPair(secondSettlementID, false, 1, 80.0, 120.0, cSettlementDist1v1, cBiasAggressive);
   }
   else
   {
      // TODO Be smarter here for team games, using different parameters for inner and outer players.
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
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidSiegeShipRange);
      addObjectLocsPerPlayer(bonusSettlementID, false, 1 * getMapAreaSizeFactor(), 90.0, -1.0, 100.0);
   }

   generateLocs("settlement locs");

   rmSetProgress(0.3);

   // Starting objects.
   // Starting gold.
   int startingGoldID = rmObjectDefCreate("starting gold");
   rmObjectDefAddItem(startingGoldID, cUnitTypeMineGoldMedium, 1);
   rmObjectDefAddConstraint(startingGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingGoldID, vDefaultAvoidImpassableLand20);
   rmObjectDefAddConstraint(startingGoldID, vDefaultStartingGoldAvoidTower);
   rmObjectDefAddConstraint(startingGoldID, vDefaultForceStartingGoldNearTower);
   addObjectLocsPerPlayer(startingGoldID, false, 1, cStartingGoldMinDist, cStartingGoldMaxDist, cStartingObjectAvoidanceMeters);

   generateLocs("starting gold locs");

   // Berries.
   int startingBerriesID = rmObjectDefCreate("starting berries");
   rmObjectDefAddItem(startingBerriesID, cUnitTypeBerryBush, xsRandInt(6, 9), cBerryClusterRadius);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultAvoidImpassableLand20);
   addObjectLocsPerPlayer(startingBerriesID, false, 1, cStartingBerriesMinDist, cStartingBerriesMaxDist, cStartingObjectAvoidanceMeters);

   // Starting hunt.
   int startingHuntID = rmObjectDefCreate("starting hunt");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeBoar, 4);
   }
   else
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeAurochs, 3);
   }
   rmObjectDefAddConstraint(startingHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHuntID, vDefaultAvoidImpassableLand20);
   addObjectLocsPerPlayer(startingHuntID, false, 1, cStartingHuntMinDist, cStartingHuntMaxDist, cStartingObjectAvoidanceMeters);
   
   // Chicken.
   int startingChickenID = rmObjectDefCreate("starting chicken");
   rmObjectDefAddItem(startingChickenID, cUnitTypeChicken, xsRandInt(6, 9));
   rmObjectDefAddConstraint(startingChickenID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingChickenID, vDefaultAvoidImpassableLand20);
   addObjectLocsPerPlayer(startingChickenID, false, 1, cStartingChickenMinDist, cStartingChickenMaxDist, cStartingObjectAvoidanceMeters);

   // Herdables.
   int startingHerdID = rmObjectDefCreate("starting herd");
   rmObjectDefAddItem(startingHerdID, cUnitTypePig, xsRandInt(2, 3));
   rmObjectDefAddConstraint(startingHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidWater);
   addObjectLocsPerPlayer(startingHerdID, true, 1, cStartingHerdMinDist, cStartingHerdMaxDist);

   generateLocs("starting food locs");

   rmSetProgress(0.4);

   // Gold.
   float avoidGoldMeters = 50.0;

   // Close gold.
   int closeGoldID = rmObjectDefCreate("close gold");
   rmObjectDefAddItem(closeGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidImpassableLand20);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeGoldID, 65.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeGoldID, false, 1, 65.0, 75.0, avoidGoldMeters);
   }
   else
   {
      addObjectLocsPerPlayer(closeGoldID, false, 1, 65.0, 75.0, avoidGoldMeters);
   }

   // Far gold.
   int farGoldID = rmObjectDefCreate("far gold");
   rmObjectDefAddItem(farGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(farGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(farGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(farGoldID, vDefaultAvoidImpassableLand20);
   rmObjectDefAddConstraint(farGoldID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(farGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(farGoldID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(farGoldID, 80.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(farGoldID, false, 1, 80.0, 100.0, avoidGoldMeters);
   }
   else
   {
      addObjectLocsPerPlayer(farGoldID, false, 1, 80.0, 100.0, avoidGoldMeters);
   }

   // Bonus gold.
   int bonusGoldID = rmObjectDefCreate("bonus gold");
   rmObjectDefAddItem(bonusGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidImpassableLand20);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(bonusGoldID, 100.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusGoldID, false, xsRandInt(1, 2) * getMapSizeBonusFactor(), 100.0, -1.0, avoidGoldMeters);
   }
   else
   {
      addObjectLocsPerPlayer(bonusGoldID, false, 1 * getMapSizeBonusFactor(), 100.0, -1.0, avoidGoldMeters);
   }

   generateLocs("gold locs");

   rmSetProgress(0.5);

   // Hunt.
   float avoidHuntMeters = 50.0;

   // Close hunt.
   float closeHuntFloat = xsRandFloat(0.0, 1.0);
   int closeHuntID = rmObjectDefCreate("close hunt");
   if(closeHuntFloat < 1.0 / 3.0)
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeBoar, xsRandInt(3, 4));
   }
   else if(closeHuntFloat < 2.0 / 3.0)
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeDeer, xsRandInt(6, 8));
   }
   else
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeAurochs, xsRandInt(3, 4));
   }
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidImpassableLand20);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeHuntID, 55.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeHuntID, false, 1, 55.0, 80.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(closeHuntID, false, 1, 55.0, -1.0, avoidHuntMeters);
   }

   // Far hunt.
   float farHuntFloat = xsRandFloat(0.0, 1.0);
   int farHunt1ID = rmObjectDefCreate("far hunt 1");
   if(farHuntFloat < 1.0 / 3.0)
   {
      rmObjectDefAddItem(farHunt1ID, cUnitTypeBoar, xsRandInt(3, 5));
   }
   else if(farHuntFloat < 2.0 / 3.0)
   {
      rmObjectDefAddItem(farHunt1ID, cUnitTypeDeer, xsRandInt(6, 9));
   }
   else
   {
      rmObjectDefAddItem(farHunt1ID, cUnitTypeAurochs, xsRandInt(3, 5));
   }
   rmObjectDefAddConstraint(farHunt1ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(farHunt1ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(farHunt1ID, vDefaultAvoidImpassableLand20);
   rmObjectDefAddConstraint(farHunt1ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(farHunt1ID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(farHunt1ID, 70.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(farHunt1ID, false, 1, 70.0, 100.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(farHunt1ID, false, 1, 70.0, -1.0, avoidHuntMeters);
   }
   
   int farHunt2ID = rmObjectDefCreate("far hunt 2");
   rmObjectDefAddItem(farHunt2ID, cUnitTypeAurochs, xsRandInt(2, 3));
   rmObjectDefAddItem(farHunt2ID, cUnitTypeDeer, xsRandInt(0, 4));
   rmObjectDefAddConstraint(farHunt2ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(farHunt2ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(farHunt2ID, vDefaultAvoidImpassableLand20);
   rmObjectDefAddConstraint(farHunt2ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(farHunt2ID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(farHunt2ID, 70.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(farHunt2ID, false, 1, 70.0, 100.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(farHunt2ID, false, 1, 70.0, -1.0, avoidHuntMeters);
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
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeAurochs, xsRandInt(3, 5));
         }
         else
         {
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeBoar, xsRandInt(1, 3));
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeDeer, xsRandInt(3, 7));
         }

         rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidEdge);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidAll);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidImpassableLand20);
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

   int berriesID = rmObjectDefCreate("berries");
   rmObjectDefAddItem(berriesID, cUnitTypeBerryBush, xsRandInt(5, 9), cBerryClusterRadius);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(berriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidImpassableLand20);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(berriesID, 70.0);
   addObjectLocsPerPlayer(berriesID, false, 1 * getMapSizeBonusFactor(), 70.0, -1.0, avoidBerriesMeters);

   generateLocs("berries locs");

   // Herdables.
   float avoidHerdMeters = 50.0;

   int closeHerdID = rmObjectDefCreate("close herd");
   rmObjectDefAddItem(closeHerdID, cUnitTypePig, 2);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidWater);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidTowerLOS);
   addObjectLocsPerPlayer(closeHerdID, false, 2, 50.0, 70.0, avoidHerdMeters);

   int bonusHerdID = rmObjectDefCreate("bonus herd");
   rmObjectDefAddItem(bonusHerdID, cUnitTypePig, 2);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidWater);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidTowerLOS);
   addObjectLocsPerPlayer(bonusHerdID, false, 3 * getMapSizeBonusFactor(), 70.0, -1.0, avoidHerdMeters);

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
   addObjectDefPlayerLocConstraint(predatorID, 80.0);
   addObjectLocsPerPlayer(predatorID, false, xsRandInt(1, 2) * getMapAreaSizeFactor(), 70.0, -1.0, avoidPredatorMeters);

   generateLocs("predator locs");

   // Relics.
   float avoidRelicMeters = 80.0;

   int relicID = rmObjectDefCreate("relic");
   rmObjectDefAddItem(relicID, cUnitTypeRelic, 1);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidAll);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidImpassableLand20);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(relicID, 70.0);
   addObjectLocsPerPlayer(relicID, false, 2 * getMapAreaSizeFactor(), 70.0, -1.0, avoidRelicMeters);

   generateLocs("relic locs");

   rmSetProgress(0.7);

   // Player fish (dead ahead).
   for(int i = 1; i <= cNumberPlayers; i++)
   {
      // Go in the order we placed the players.
      int p = vDefaultTeamPlayerOrder[i];

      // Get the player starting loc ID.
      int playerLocID = rmGetPlayerLocID(p);
      // Get the player's starting pos.
      vector playerLoc = rmGetPlayerLoc(p);

      // Get the angle of the player loc.
      float minAngle = -0.025 * cPi + vPlayerLocForwardAnglesByPlayer[playerLocID];
      float maxAngle = 0.025 * cPi + vPlayerLocForwardAnglesByPlayer[playerLocID];
      int playerAngleConstraint = rmCreateCircularConstraint(playerLoc, cMaxFloat, minAngle, maxAngle);

      int playerFishID = rmObjectDefCreate("player fish " + p);
      rmObjectDefAddItem(playerFishID, cUnitTypePerch, 3, 5.0);
      // Disable the buffer here and treat the object as 1 tile to make things easier.
      rmObjectDefAddConstraint(playerFishID, rmCreatePassabilityDistanceConstraint(cPassabilityLand, true, 10.0), cObjectConstraintBufferNone);
      rmObjectDefAddConstraint(playerFishID, rmCreatePassabilityMaxDistanceConstraint(cPassabilityLand, true, 13.0), cObjectConstraintBufferNone);
      rmObjectDefAddConstraint(playerFishID, playerAngleConstraint, cObjectConstraintBufferNone);
      // We could check tile by tile towards the center instead of the circular constraint, but this is also okay.
      rmObjectDefPlaceNearLoc(playerFishID, 0, playerLoc);
   }

   int bonusIslandID = cInvalidID;
   
   if (gameIsKotH() == false)
   {
      // Center island (after player fish so we can omit the constraint for the fish to avoid the island).
      if(cNumberPlayers >= 5)
      {
         bonusIslandID = rmAreaCreate("bonus island");
         rmAreaSetLoc(bonusIslandID, cCenterLoc);
         rmAreaSetSize(bonusIslandID, rmRadiusToAreaFraction(20.0));
         rmAreaSetTerrainType(bonusIslandID, cTerrainGreekGrass1);

         rmAreaSetHeight(bonusIslandID, 0.5);
         rmAreaAddHeightBlend(bonusIslandID, cBlendAll, cFilter5x5Gaussian, 10, 5);

         rmAreaBuild(bonusIslandID);

         int islandObjectsID = rmObjectDefCreate("island gold");
         rmObjectDefAddItem(islandObjectsID, cUnitTypeMineGoldLarge, 1, 0.0, 2.0);
         rmObjectDefAddItem(islandObjectsID, cUnitTypeBaboon, xsRandInt(1, 3), 2.0);
         rmObjectDefAddItem(islandObjectsID, cUnitTypeTreePalm, xsRandInt(1, 3), 4.0);
         rmObjectDefAddItem(islandObjectsID, cUnitTypeMonkeyRaft, xsRandInt(1, 2), 20.0);
         rmObjectDefPlaceAtLoc(islandObjectsID, 0, cCenterLoc);
      }
   }

   // Global fish.
   if(gameIs1v1() == true && cMapSizeCurrent == cMapSizeStandard)
   {
      float fishDistMeters = 20.0;

      int fishID = rmObjectDefCreate("1v1 fish");
      rmObjectDefAddItem(fishID, cUnitTypeHerring, 3, 6.0);
      rmObjectDefAddConstraint(fishID, rmCreatePassabilityDistanceConstraint(cPassabilityLand, true, 10.0), cObjectConstraintBufferNone);
      rmObjectDefAddConstraint(fishID, rmCreateTypeDistanceConstraint(cUnitTypeFishResource, fishDistMeters), cObjectConstraintBufferNone);
      // Don't force in any area so we get a more random pattern.
      addMirroredObjectLocsPerPlayerPair(fishID, false, 3, 20.0, rmXFractionToMeters(0.5), fishDistMeters);

      generateLocs("fish locs");
   }
   else
   {
      float fishDistMeters = 25.0;

      int fishID = rmObjectDefCreate("global fish");
      rmObjectDefAddItem(fishID, cUnitTypeHerring, 3, 6.0);
      rmObjectDefAddConstraint(fishID, rmCreatePassabilityDistanceConstraint(cPassabilityLand, true, 10.0), cObjectConstraintBufferNone);
      rmObjectDefAddConstraint(fishID, rmCreateTypeDistanceConstraint(cUnitTypeFishResource, fishDistMeters), cObjectConstraintBufferNone);
      rmObjectDefPlaceAnywhere(fishID, 0, 4 * cNumberPlayers * getMapAreaSizeFactor());
   }

   rmSetProgress(0.8);

   // Forests.
   float avoidForestMeters = 22.5;

   int forestDefID = rmAreaDefCreate("forest");
   rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(60), rmTilesToAreaFraction(80));
   rmAreaDefSetForestType(forestDefID, cForestGreekMediterraneanLush);
   rmAreaDefSetAvoidSelfDistance(forestDefID, avoidForestMeters);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidImpassableLand16);
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
   buildAreaDefInTeamAreas(forestDefID, 9 * getMapAreaSizeFactor());

   // Stragglers.
   placeStartingStragglers(cUnitTypeTreeCypress);

   rmSetProgress(0.9);

   // Embellishment.
   int embellishmentAvoidBonusIsland = cInvalidID;
   if(bonusIslandID != cInvalidID)
   {
      embellishmentAvoidBonusIsland = rmCreateAreaDistanceConstraint(bonusIslandID, 0.1);
   }

   // Random trees.
   int randomTreeID = rmObjectDefCreate("random tree");
   rmObjectDefAddItem(randomTreeID, cUnitTypeTreeCypress, 1);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidTree);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidImpassableLand16);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidSettlementWithFarm);
   if(bonusIslandID != cInvalidID)
   {
      rmObjectDefAddConstraint(randomTreeID, embellishmentAvoidBonusIsland);
   }
   rmObjectDefPlaceAnywhere(randomTreeID, 0, 4 * cNumberPlayers * getMapAreaSizeFactor());

   // Gold.
   buildAreaUnderObjectDef(startingGoldID, cTerrainGreekGrassRocks2, cTerrainGreekGrassRocks1, 6.0);
   buildAreaUnderObjectDef(closeGoldID, cTerrainGreekGrassRocks2, cTerrainGreekGrassRocks1, 6.0);
   buildAreaUnderObjectDef(farGoldID, cTerrainGreekGrassRocks2, cTerrainGreekGrassRocks1, 6.0);
   buildAreaUnderObjectDef(bonusGoldID, cTerrainGreekGrassRocks2, cTerrainGreekGrassRocks1, 6.0);

   // Berries.
   buildAreaUnderObjectDef(startingBerriesID, cTerrainGreekGrass2, cTerrainGreekGrass1, 10.0);
   buildAreaUnderObjectDef(berriesID, cTerrainGreekGrass2, cTerrainGreekGrass1, 10.0);

   // Flowers.
   int insideEmbellishmentID = rmObjectDefCreate("flowers");
   rmObjectDefAddItem(insideEmbellishmentID, cUnitTypeFlowers, 2, 4.0);
   rmObjectDefAddConstraint(insideEmbellishmentID, vDefaultAvoidImpassableLand16);
   rmObjectDefAddConstraint(insideEmbellishmentID, vDefaultAvoidCollideable4);
   rmObjectDefAddConstraint(insideEmbellishmentID, rmCreateTypeDistanceConstraint(cUnitTypeGoldResource, 10.0));
   rmObjectDefAddConstraint(insideEmbellishmentID, rmCreateTerrainTypeMaxDistanceConstraint(cTerrainGreekGrass2, 0.1));
   rmObjectDefPlaceAnywhere(insideEmbellishmentID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   // Rocks.
   int rockTinyID = rmObjectDefCreate("rock tiny");
   rmObjectDefAddItem(rockTinyID, cUnitTypeRockGreekTiny, 1);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockTinyID, vDefaultAvoidImpassableLand8);
   rmObjectDefPlaceAnywhere(rockTinyID, 0, 15 * cNumberPlayers * getMapAreaSizeFactor());

   int rockSmallID = rmObjectDefCreate("rock small");
   rmObjectDefAddItem(rockSmallID, cUnitTypeRockGreekSmall, 1);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockSmallID, vDefaultAvoidImpassableLand8);
   rmObjectDefPlaceAnywhere(rockSmallID, 0, 15 * cNumberPlayers * getMapAreaSizeFactor());

   // Plants.
   int plantBushID = rmObjectDefCreate("plant bush");
   rmObjectDefAddItem(plantBushID, cUnitTypePlantGreekBush, 1);
   rmObjectDefAddConstraint(plantBushID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantBushID, vDefaultAvoidWater4);
   rmObjectDefPlaceAnywhere(plantBushID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantShrubID = rmObjectDefCreate("plant shrub");
   rmObjectDefAddItem(plantShrubID, cUnitTypePlantGreekShrub, 1);
   rmObjectDefAddConstraint(plantShrubID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantShrubID, vDefaultAvoidWater4);
   rmObjectDefPlaceAnywhere(plantShrubID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantGrassID = rmObjectDefCreate("plant grass");
   rmObjectDefAddItem(plantGrassID, cUnitTypePlantGreekGrass, 1);
   rmObjectDefAddConstraint(plantGrassID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantGrassID, vDefaultAvoidWater4);
   rmObjectDefAddConstraint(plantGrassID, vDefaultAvoidEdge);
   rmObjectDefPlaceAnywhere(plantGrassID, 0, 50 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantFernID = rmObjectDefCreate("plant fern");
   rmObjectDefAddItemRange(plantFernID, cUnitTypePlantGreekFern, 1);
   rmObjectDefAddItem(plantFernID, cUnitTypePlantGreekFern, 1);
   rmObjectDefAddConstraint(plantFernID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantFernID, vDefaultAvoidWater4);
   rmObjectDefPlaceAnywhere(plantFernID, 0, 50 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantWeedsID = rmObjectDefCreate("plant weeds");
   rmObjectDefAddItem(plantWeedsID, cUnitTypePlantGreekWeeds, 1);
   rmObjectDefAddConstraint(plantWeedsID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantWeedsID, vDefaultAvoidWater4);
   rmObjectDefPlaceAnywhere(plantWeedsID, 0, 15 * cNumberPlayers * getMapAreaSizeFactor());

   // Seaweed.
   int seaweedID = rmObjectDefCreate("seaweed");
   rmObjectDefAddItem(seaweedID, cUnitTypeSeaweed, 1);
   rmObjectDefAddConstraint(seaweedID, rmCreatePassabilityDistanceConstraint(cPassabilityLand, true, 2.0));
   rmObjectDefAddConstraint(seaweedID, rmCreatePassabilityMaxDistanceConstraint(cPassabilityLand, true, 6.0));
   rmObjectDefPlaceAnywhere(seaweedID, 0, 100.0 * sqrt(cNumberPlayers) * getMapAreaSizeFactor());

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeHawk, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   rmSetProgress(1.0);
}
