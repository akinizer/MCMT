include "lib2/rm_core.xs";

void generate()
{
   rmSetProgress(0.0);

   // Define mixes.
   int baseMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.1, 5, 0.5);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseSnow2, 3.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseSnow1, 3.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseSnowGrass1, 2.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseSnowGrass2, 2.0);

 // Set size.
   int playerTiles=20000;
   int cNumberNonGaiaPlayers = 10;
   if(cMapSizeCurrent == 1)
   {
      playerTiles = 30000;
   }
   int size=2.0*sqrt(cNumberNonGaiaPlayers*playerTiles/0.9);
   rmSetMapSize(size, size);
   rmInitializeWater(cWaterNorseSeaSnow);

   float continentFraction = 0.5;
   float playerContinentEdgeDistMeters = 40.0;
   float placementRadiusMeters = rmFractionToAreaRadius(continentFraction) - playerContinentEdgeDistMeters;
   float placementFraction = smallerMetersToFraction(placementRadiusMeters);

   // Player placement.
   rmSetTeamSpacingModifier(0.9);
   rmPlacePlayersOnCircle(placementFraction);

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCivFromCulture(cCultureNorse);

   // Lighting.
   rmSetLighting(cLightingSetRmMidgard01);

   rmSetProgress(0.1);

   // Player base areas.
   float playerBaseAreaSize = rmRadiusToAreaFraction(45.0);

   for(int i = 1; i <= cNumberPlayers; i++)
   {
      int p = vDefaultTeamPlayerOrder[i];

      int playerBaseAreaID = rmAreaCreate("player base area " + p);
      rmAreaSetLocPlayer(playerBaseAreaID, p);
      rmAreaSetSize(playerBaseAreaID, playerBaseAreaSize);
      rmAreaSetMix(playerBaseAreaID, baseMixID);

      rmAreaSetCoherence(playerBaseAreaID, 1.0);
      rmAreaSetHeight(playerBaseAreaID, 0.5);
      rmAreaAddHeightBlend(playerBaseAreaID, cBlendAll, cFilter5x5Gaussian, 2);
   }

   rmAreaBuildAll();

   // Continent.
   int continentID = rmAreaCreate("continent");
   rmAreaSetSize(continentID, continentFraction);
   rmAreaSetLoc(continentID, cCenterLoc);
   rmAreaSetMix(continentID, baseMixID);

   rmAreaSetHeightNoise(continentID, cNoiseFractalSum, 5.0, 0.1, 2, 0.5);
   rmAreaSetHeightNoiseBias(continentID, 1.0); // Only grow upwards to not get below water height.
   rmAreaSetHeightNoiseEdgeFalloffDist(continentID, 20.0);

   rmAreaSetHeight(continentID, 0.25);
   rmAreaAddHeightBlend(continentID, cBlendEdge, cFilter5x5Gaussian, 10, 10);

   rmAreaSetBlobDistance(continentID, 5.0, 20.0);
   rmAreaSetBlobs(continentID, 1 * cNumberPlayers, 2 * cNumberPlayers);

   rmAreaSetEdgeSmoothDistance(continentID, 15);

   rmAreaAddConstraint(continentID, createSymmetricBoxConstraint(0.075), 0.0, 10.0);

   rmAreaBuild(continentID);

   // KotH.
   placeKotHObjects();

   rmSetProgress(0.2);

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
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidSiegeShipRange);

   int secondSettlementID = rmObjectDefCreate("second settlement");
   rmObjectDefAddItem(secondSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidSiegeShipRange);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidKotH);

   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(firstSettlementID, false, 1, 60.0, 80.0, cSettlementDist1v1, cBiasBackward);
      addSimObjectLocsPerPlayerPair(secondSettlementID, false, 1, 70.0, 90.0, cSettlementDist1v1, cBiasAggressive);
   }
   else
   {
      addObjectLocsPerPlayer(firstSettlementID, false, 1, 60.0, 80.0, cCloseSettlementDist, cBiasBackward | cBiasAllyInside);
      addObjectLocsPerPlayer(secondSettlementID, false, 1, 80.0, 100.0, cFarSettlementDist, cBiasAggressive | getRandomAllyBias());
   }

   // Other map sizes settlements.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int bonusSettlementID = rmObjectDefCreate("bonus settlement");
      rmObjectDefAddItem(bonusSettlementID, cUnitTypeSettlement, 1);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidEdge);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidSiegeShipRange);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidKotH);
      addObjectLocsPerPlayer(bonusSettlementID, false, 1 * getMapAreaSizeFactor(), 90.0, -1.0, 100.0);
   }

   generateLocs("settlement locs");


   rmSetProgress(0.3);

   // Starting objects.
   // Starting gold.
   int startingGoldID = rmObjectDefCreate("starting gold");
   rmObjectDefAddItem(startingGoldID, cUnitTypeMineGoldMedium, 1);
   rmObjectDefAddConstraint(startingGoldID, vDefaultGoldAvoidWater);
   rmObjectDefAddConstraint(startingGoldID, vDefaultStartingGoldAvoidTower);
   rmObjectDefAddConstraint(startingGoldID, vDefaultForceStartingGoldNearTower);
   addObjectLocsPerPlayer(startingGoldID, false, 1, cStartingGoldMinDist, cStartingGoldMaxDist, cStartingObjectAvoidanceMeters);

   generateLocs("starting gold locs");

   // Berries.
   int startingBerriesID = rmObjectDefCreate("starting berries");
   rmObjectDefAddItem(startingBerriesID, cUnitTypeBerryBush, xsRandInt(6, 9), cBerryClusterRadius);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidWater);
   addObjectLocsPerPlayer(startingBerriesID, false, 1, cStartingBerriesMinDist, cStartingBerriesMaxDist, cStartingObjectAvoidanceMeters);

   // Starting hunt.
   int startingHuntID = rmObjectDefCreate("starting hunt");
   rmObjectDefAddItem(startingHuntID, cUnitTypeBoar, 4);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(startingHuntID, vDefaultForceInTowerLOS);
   addObjectLocsPerPlayer(startingHuntID, false, 1, cStartingHuntMinDist, cStartingHuntMaxDist, cStartingObjectAvoidanceMeters);

   // Chicken.
   int startingChickenID = rmObjectDefCreate("starting chicken");

   int chickenNum = xsRandInt(5, 7);

   // Set chicken variation, excluding whites, as they are hard to see on snow maps.
   for (int i = 0; i < chickenNum; i++)
   {
      rmObjectDefAddItem(startingChickenID, cUnitTypeChicken, 1);
      rmObjectDefSetItemVariation(startingChickenID, i, xsRandInt(cChickenVariationBrown, cChickenVariationBlack));
   }
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidWater);
   addObjectLocsPerPlayer(startingChickenID, false, 1, cStartingChickenMinDist, cStartingChickenMaxDist, cStartingObjectAvoidanceMeters);

   // Herdables.
   int startingHerdID = rmObjectDefCreate("starting herd");
   rmObjectDefAddItem(startingHerdID, cUnitTypeCow, xsRandInt(1, 3));
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
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidWater16);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeGoldID, 55.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeGoldID, false, 1, 55.0, 70.0, avoidGoldMeters, cBiasForward);
   }
   else
   {
      addObjectLocsPerPlayer(closeGoldID, false, 1, 55.0, 70.0, avoidGoldMeters);
   }

   // Bonus gold.
   int bonusGoldID = rmObjectDefCreate("bonus gold");
   rmObjectDefAddItem(bonusGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidWater16);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(bonusGoldID, 70.0);

   if(gameIs1v1() == true)
   {
      addObjectLocsPerPlayer(bonusGoldID, false, xsRandInt(1, 3) * getMapSizeBonusFactor(), 70.0, -1.0, avoidGoldMeters, cBiasForward);
   }
   else
   {
      addObjectLocsPerPlayer(bonusGoldID, false, xsRandInt(2, 3) * getMapSizeBonusFactor(), 70.0, -1.0, avoidGoldMeters);
   }

   generateLocs("gold locs");

   rmSetProgress(0.5);

   // Hunt.
   float avoidHuntMeters = 50.0;
   int shoreHuntMinDist = rmCreatePassabilityDistanceConstraint(cPassabilityLand, false, 4.0);
   int shoreHuntMaxDist = rmCreatePassabilityMaxDistanceConstraint(cPassabilityLand, false, 16.0);

   // Shore hunt.
   if(gameIs1v1() == true)
   {
      // Currently only place this for 1v1.
      int shoreHuntID = rmObjectDefCreate("shore hunt");
      rmObjectDefAddItem(shoreHuntID, cUnitTypeWalrus, xsRandInt(3, 6));
      rmObjectDefAddConstraint(shoreHuntID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(shoreHuntID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(shoreHuntID, vDefaultAvoidSettlementRange);
      // Don't use the buffer for the "range band" here, makes it less complicated.
      rmObjectDefAddConstraint(shoreHuntID, shoreHuntMinDist, cObjectConstraintBufferNone);
      rmObjectDefAddConstraint(shoreHuntID, shoreHuntMaxDist, cObjectConstraintBufferNone);
      addObjectDefPlayerLocConstraint(shoreHuntID, 60.0);
      // Probably doesn't need a sim loc since it can only be on the shore for either side.
      addObjectLocsPerPlayer(shoreHuntID, false, 1, 60.0, 90.0, avoidHuntMeters);
   }

   // Close hunt.
   int closeHuntID = rmObjectDefCreate("close hunt");
   rmObjectDefAddItem(closeHuntID, cUnitTypeDeer, xsRandInt(4, 9));
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidWater16);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeHuntID, 60.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeHuntID, false, 1, 60.0, 70.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(closeHuntID, false, 1, 60.0, 80.0, avoidHuntMeters);
   }

   // Bonus shore hunt.
   int bonusShoreHuntID = rmObjectDefCreate("bonus shore hunt");
   rmObjectDefAddItem(bonusShoreHuntID, cUnitTypeWalrus, xsRandInt(4, 7));
   rmObjectDefAddConstraint(bonusShoreHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(bonusShoreHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusShoreHuntID, vDefaultAvoidSettlementRange);
   // Same as above.
   rmObjectDefAddConstraint(bonusShoreHuntID, shoreHuntMinDist, cObjectConstraintBufferNone);
   rmObjectDefAddConstraint(bonusShoreHuntID, shoreHuntMaxDist, cObjectConstraintBufferNone);
   if(gameIs1v1() == true)
   {
      rmObjectDefAddConstraint(bonusShoreHuntID, createPlayerLocDistanceConstraint(80.0));
      addObjectLocsPerPlayer(bonusShoreHuntID, false, 1 * getMapSizeBonusFactor(), 80.0, -1.0, avoidHuntMeters);
   }
   else
   {
      rmObjectDefAddConstraint(bonusShoreHuntID, createPlayerLocDistanceConstraint(60.0));
      addObjectLocsPerPlayer(bonusShoreHuntID, false, 1 * getMapSizeBonusFactor(), 60.0, -1.0, avoidHuntMeters);
   }

   // Bonus hunt.
   int bonusHuntID = rmObjectDefCreate("bonus hunt");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(bonusHuntID, cUnitTypeElk, xsRandInt(4, 9));
   }
   else
   {
      rmObjectDefAddItem(bonusHuntID, cUnitTypeCaribou, xsRandInt(4, 9));
   }
   rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidWater16);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(bonusHuntID, 60.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusHuntID, false, 1 * getMapSizeBonusFactor(), 70.0, -1.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(bonusHuntID, false, 1 * getMapSizeBonusFactor(), 70.0, -1.0, avoidHuntMeters);
   }

   generateLocs("hunt locs");

   rmSetProgress(0.6);

   // Ice patches.
   int iceClassID = rmClassCreate();

   int icePatchDefID = rmAreaDefCreate("ice patch");
   rmAreaDefSetSizeRange(icePatchDefID, rmTilesToAreaFraction(100), rmTilesToAreaFraction(150));
   rmAreaDefAddTerrainLayer(icePatchDefID, cTerrainNorseShore1, 0, 1);
   rmAreaDefAddTerrainLayer(icePatchDefID, cTerrainDefaultIce1, 1, 2);
   rmAreaDefSetTerrainType(icePatchDefID, cTerrainDefaultIce2);

   rmAreaDefSetHeightRelative(icePatchDefID, -1.0);
   rmAreaDefAddHeightBlend(icePatchDefID, cBlendAll, cFilter3x3Gaussian);

   rmAreaDefAddConstraint(icePatchDefID, vDefaultAvoidAll12);
   rmAreaDefAddConstraint(icePatchDefID, vDefaultAvoidWater16);
   rmAreaDefAddConstraint(icePatchDefID, vDefaultAvoidSettlementRange);
   rmAreaDefAddConstraint(icePatchDefID, createPlayerLocDistanceConstraint(60.0));
   rmAreaDefSetAvoidSelfDistance(icePatchDefID, 40.0);
   rmAreaDefSetOriginConstraintBuffer(icePatchDefID, 10.0);
   rmAreaDefAddToClass(icePatchDefID, iceClassID);

   rmAreaDefCreateAndBuildAreas(icePatchDefID, 1 * cNumberPlayers * getMapAreaSizeFactor());

   // Herdables.
   float avoidHerdMeters = 50.0;

   int bonusHerdID = rmObjectDefCreate("bonus herd");
   rmObjectDefAddItem(bonusHerdID, cUnitTypeCow, xsRandInt(1, 2));
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidWater);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidTowerLOS);
   addObjectLocsPerPlayer(bonusHerdID, false, xsRandInt(1, 2) * getMapAreaSizeFactor(), 50.0, -1.0, avoidHerdMeters);

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
   rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidWater8);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(predatorID, 70.0);
   addObjectLocsPerPlayer(predatorID, false, xsRandInt(1, 2) * getMapAreaSizeFactor(), 70.0, -1.0, avoidPredatorMeters);

   generateLocs("predator locs");

   // Relics.
   float avoidRelicMeters = 80.0;

   int relicID = rmObjectDefCreate("relic");
   rmObjectDefAddItem(relicID, cUnitTypeRelic, 1);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidAll);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidWater16);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(relicID, 60.0);
   addObjectLocsPerPlayer(relicID, false, 2 * getMapAreaSizeFactor(), 60.0, -1.0, avoidRelicMeters);

   generateLocs("relic locs");

   // Stragglers.
   placeStartingStragglers(cUnitTypeTreePineSnow);

   rmSetProgress(0.7);

   int avoidIce = rmCreateClassDistanceConstraint(iceClassID, 1.0);

   // Forests.
   float avoidForestMeters = 25.0;

   int forestDefID = rmAreaDefCreate("forest");
   rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(70), rmTilesToAreaFraction(90));
   rmAreaDefSetForestType(forestDefID, cForestNorsePineSnow);
   rmAreaDefSetAvoidSelfDistance(forestDefID, avoidForestMeters);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidWater16);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddConstraint(forestDefID, avoidIce);

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

   rmSetProgress(0.8);

   // Fish.
   // Player fish (straight behind the base from the center).
   for(int i = 1; i <= cNumberPlayers; i++)
   {
      // Go in the order we placed the players.
      int p = vDefaultTeamPlayerOrder[i];

      // Get the player starting loc ID.
      int playerLocID = rmGetPlayerLocID(p);
      // Get the player's starting pos.
      vector playerLoc = rmGetPlayerLoc(p);

      // Get the angle of the player loc.
      float minAngle = 0.95 * cPi + vPlayerLocForwardAnglesByPlayer[playerLocID];
      float maxAngle = 1.05 * cPi + vPlayerLocForwardAnglesByPlayer[playerLocID];

      int playerAngleConstraint = rmCreateCircularConstraint(playerLoc, cMaxFloat, minAngle, maxAngle);

      int playerFishID = rmObjectDefCreate("player fish " + p);
      rmObjectDefAddItem(playerFishID, cUnitTypeSalmon, 3, 5.0);
      rmObjectDefAddConstraint(playerFishID, rmCreatePassabilityDistanceConstraint(cPassabilityLand, true, 10.0), cObjectConstraintBufferNone);
      rmObjectDefAddConstraint(playerFishID, rmCreatePassabilityMaxDistanceConstraint(cPassabilityLand, true, 13.0), cObjectConstraintBufferNone);
      rmObjectDefAddConstraint(playerFishID, playerAngleConstraint, cObjectConstraintBufferNone);
      // We could check tile by tile towards the edge, but this is also okay.
      rmObjectDefPlaceNearLoc(playerFishID, 0, playerLoc);
   }

   // Additional fish (more random).
   float fishDistMeters = 30.0;
   int avoidFish = rmCreateTypeDistanceConstraint(cUnitTypeFishResource, fishDistMeters);

   int fishID = rmObjectDefCreate("global fish");
   rmObjectDefAddItem(fishID, cUnitTypeSalmon, 3, 6.0);
   rmObjectDefAddConstraint(fishID, rmCreatePassabilityDistanceConstraint(cPassabilityLand, true, 10.0));
   rmObjectDefAddConstraint(fishID, createSymmetricBoxConstraint(0.02));
   rmObjectDefAddConstraint(fishID, avoidFish);
   if(gameIs1v1() == true)
   {
      rmObjectDefAddConstraint(fishID, rmCreatePassabilityMaxDistanceConstraint(cPassabilityLand, true, 30.0));
      addMirroredObjectLocsPerPlayerPair(fishID, false, xsRandInt(5, 6) * getMapAreaSizeFactor(), 60.0, rmXFractionToMeters(0.75), fishDistMeters, cInAreaPlayer);
   }
   else
   {
      rmObjectDefAddConstraint(fishID, rmCreatePassabilityMaxDistanceConstraint(cPassabilityLand, true, 50.0));
      addObjectLocsPerPlayer(fishID, false, xsRandInt(5, 6) * getMapAreaSizeFactor(), 80.0, -1.0, fishDistMeters, cInAreaPlayer);
   }

   generateLocs("fish locs");

   // Bonus fish.
   int decoFishID = rmObjectDefCreate("bonus fish");
   rmObjectDefAddItem(decoFishID, cUnitTypeHerring, 1);
   rmObjectDefAddConstraint(decoFishID, rmCreatePassabilityDistanceConstraint(cPassabilityLand, true, 30.0));
   rmObjectDefAddConstraint(decoFishID, avoidFish);
   rmObjectDefAddConstraint(decoFishID, vDefaultAvoidEdge);
   // Unchecked.
   rmObjectDefPlaceAnywhere(decoFishID, 0, 4 * cNumberPlayers * getMapAreaSizeFactor());

   rmSetProgress(0.9);

   // Embellishment.
   // Gold areas.
   buildAreaUnderObjectDef(startingGoldID, cTerrainNorseSnowRocks2, cTerrainNorseSnowRocks1, 6.0);
   buildAreaUnderObjectDef(closeGoldID, cTerrainNorseSnowRocks2, cTerrainNorseSnowRocks1, 6.0);
   buildAreaUnderObjectDef(bonusGoldID, cTerrainNorseSnowRocks2, cTerrainNorseSnowRocks1, 6.0);

   // Berries areas.
   buildAreaUnderObjectDef(startingBerriesID, cTerrainNorseSnowGrass2, cTerrainNorseSnowGrass1, 9.0);
   
   // Random trees.
   int randomTreeID = rmObjectDefCreate("random tree");
   rmObjectDefAddItem(randomTreeID, cUnitTypeTreePineSnow, 1);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidWater);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidTree);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefAddConstraint(randomTreeID, avoidIce);
   rmObjectDefPlaceAnywhere(randomTreeID, 0, 5 * cNumberPlayers * getMapAreaSizeFactor());

   // Rocks.
   int runestoneID = rmObjectDefCreate("runestone");
   rmObjectDefAddItem(runestoneID, cUnitTypeRunestone, 1);
   rmObjectDefAddConstraint(runestoneID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(runestoneID, vDefaultAvoidWater4);
   rmObjectDefAddConstraint(runestoneID, avoidIce);
   rmObjectDefPlaceAnywhere(runestoneID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   int rockTinyID = rmObjectDefCreate("rock tiny");
   rmObjectDefAddItem(rockTinyID, cUnitTypeRockNorseTiny, 1);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockTinyID, vDefaultAvoidWater8);
   rmObjectDefAddConstraint(rockTinyID, avoidIce);
   rmObjectDefPlaceAnywhere(rockTinyID, 0, 15 * cNumberPlayers * getMapAreaSizeFactor());

   int rockSmallID = rmObjectDefCreate("rock small");
   rmObjectDefAddItem(rockSmallID, cUnitTypeRockNorseSmall, 1);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockSmallID, vDefaultAvoidWater8);
   rmObjectDefAddConstraint(rockSmallID, avoidIce);
   rmObjectDefPlaceAnywhere(rockSmallID, 0, 15 * cNumberPlayers * getMapAreaSizeFactor());

   // Plants.
   int plantGrassID = rmObjectDefCreate("plant shrub");
   rmObjectDefAddItem(plantGrassID, cUnitTypePlantSnowGrass, 1);
   rmObjectDefAddConstraint(plantGrassID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantGrassID, vDefaultAvoidWater8);
   rmObjectDefAddConstraint(plantGrassID, avoidIce);
   rmObjectDefPlaceAnywhere(plantGrassID, 0, 40 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantFernID = rmObjectDefCreate("plant fern");
   rmObjectDefAddItemRange(plantFernID, cUnitTypePlantSnowFern, 1);
   rmObjectDefAddConstraint(plantFernID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantFernID, vDefaultAvoidWater8);
   rmObjectDefAddConstraint(plantFernID, avoidIce);
   rmObjectDefPlaceAnywhere(plantFernID, 0, 20 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantWeedsID = rmObjectDefCreate("plant weeds");
   rmObjectDefAddItemRange(plantWeedsID, cUnitTypePlantSnowWeeds, 1);
   rmObjectDefAddConstraint(plantWeedsID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantWeedsID, vDefaultAvoidWater8);
   rmObjectDefAddConstraint(plantWeedsID, avoidIce);
   rmObjectDefPlaceAnywhere(plantWeedsID, 0, 20 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantBushID = rmObjectDefCreate("plant bush");
   rmObjectDefAddItem(plantBushID, cUnitTypePlantSnowBush, 1);
   rmObjectDefAddConstraint(plantBushID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantBushID, vDefaultAvoidWater8);
   rmObjectDefAddConstraint(plantBushID, avoidIce);
   rmObjectDefPlaceAnywhere(plantBushID, 0, 40 * cNumberPlayers * getMapAreaSizeFactor());

   // Orcas.
   int orcaID = rmObjectDefCreate("orca");
   rmObjectDefAddItem(orcaID, cUnitTypeOrca, 1);
   rmObjectDefAddConstraint(orcaID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(orcaID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(orcaID, rmCreatePassabilityDistanceConstraint(cPassabilityLand, true, 20.0));
   rmObjectDefAddConstraint(orcaID, rmCreateTypeDistanceConstraint(cUnitTypeOrca, 40.0));
   rmObjectDefPlaceAnywhere(orcaID, 0, 4 * cNumberPlayers * getMapAreaSizeFactor());

   // Seaweed.
   int seaweedID = rmObjectDefCreate("seaweed");
   rmObjectDefAddItem(seaweedID, cUnitTypeSeaweed, 1);
   rmObjectDefAddConstraint(seaweedID, rmCreatePassabilityDistanceConstraint(cPassabilityLand, true, 6.0));
   rmObjectDefAddConstraint(seaweedID, rmCreatePassabilityMaxDistanceConstraint(cPassabilityLand, true, 8.0));
   rmObjectDefPlaceAnywhere(seaweedID, 0, 100.0 * sqrt(cNumberPlayers) * getMapAreaSizeFactor());

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeHawk, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   rmSetProgress(1.0);
}
