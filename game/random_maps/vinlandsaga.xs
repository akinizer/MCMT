include "lib2/rm_core.xs";

void generate()
{
   rmSetProgress(0.0);

   // Define mixes.
   int continentMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(continentMixID, cNoiseFractalSum, 0.15, 5, 0.5);
   rmCustomMixAddPaintEntry(continentMixID, cTerrainNorseGrass1, 1.0);
   rmCustomMixAddPaintEntry(continentMixID, cTerrainNorseGrass2, 1.0);
   rmCustomMixAddPaintEntry(continentMixID, cTerrainNorseGrassDirt1, 1.0);
   rmCustomMixAddPaintEntry(continentMixID, cTerrainNorseGrassDirt2, 1.0);

   // Define mixes.
   int islandMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(islandMixID, cNoiseFractalSum, 0.3, 5, 0.5);
   rmCustomMixAddPaintEntry(islandMixID, cTerrainNorseSnow2, 1.0);
   rmCustomMixAddPaintEntry(islandMixID, cTerrainNorseSnow1, 1.0);

   // Water overrides.
   rmWaterTypeAddBeachLayer(cWaterNorseSeaSnow, cTerrainNorseSnowRocks1, 1.0, 2.0);
   rmWaterTypeAddBeachLayer(cWaterNorseSeaSnow, cTerrainNorseSnow1, 5.0, 2.0);

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

   // Player placement.
   float rangeStart = 0.625 - 0.01 * cNumberPlayers;
   float range = 1.0 - (rangeStart - 0.5) - rangeStart;

   if(gameIs1v1() == true)
   {
      rmAddWaypointLinePlacementLoc(vectorXZ(0.1, 0.1));
      rmAddWaypointLinePlacementLoc(vectorXZ(0.9, 0.1));
      rmPlacePlayersOnWaypointLine(false);
   }
   else
   {
      rmPlacePlayersOnEllipse(0.45, 0.425, 0.0, 0.0, 0.0, rangeStart * cTwoPi, range);
   }

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Override the forward angle to always be towards the continent.
   for(int i = 1; i <= cNumberPlayers; i++)
   {
      // The players are facing the continent along the 
      vDefaultPlayerLocForwardAngles[i] = 0.5 * cPi;
   }

   // Mother Nature's civ.
   rmSetNatureCivFromCulture(cCultureNorse);

   // Lighting.
   rmSetLighting(cLightingSetRmVinlandsaga01);

   rmSetProgress(0.1);

   // Build continent.
   vector continentLoc = vectorXZ(0.5, 0.75);
   float continentArea = 0.475;

   int continentID = rmAreaCreate("continent");
   rmAreaSetSize(continentID, continentArea);
   rmAreaSetLoc(continentID, continentLoc);
   rmAreaAddTerrainLayer(continentID, cTerrainNorseSnow1, 0, 6);
   rmAreaAddTerrainLayer(continentID, cTerrainNorseSnowGrass1, 4, 10);
   rmAreaAddTerrainLayer(continentID, cTerrainNorseSnowGrass2, 8, 14);
   rmAreaAddTerrainLayer(continentID, cTerrainNorseSnowGrass3, 12, 20);
   rmAreaAddTerrainLayer(continentID, cTerrainNorseGrass1, 20, 22);
   rmAreaSetMix(continentID, continentMixID);

   rmAreaSetCoherence(continentID, 0.5);
   rmAreaSetHeight(continentID, 0.5);
   rmAreaAddHeightBlend(continentID, cBlendEdge, cFilter5x5Gaussian, 16.0, 10);
   rmAreaSetEdgeSmoothDistance(continentID, 15, false);

   // TODO This can be unfair, but doesn't really matter too much on this map.
   rmAreaSetBlobs(continentID, 5, 10);
   rmAreaSetBlobDistance(continentID, smallerFractionToMeters(0.15));

   rmAreaAddInfluencePoint(continentID, vectorXZ(0.5, 1.0));
   rmAreaAddInfluencePoint(continentID, vectorXZ(0.25, 1.0));
   rmAreaAddInfluencePoint(continentID, vectorXZ(0.75, 1.0));

   rmAreaAddConstraint(continentID, createPlayerLocDistanceConstraint(100.0));

   rmAreaSetHeightNoise(continentID, cNoiseFractalSum, 4.0, 0.1, 2, 0.2);
   rmAreaSetHeightNoiseBias(continentID, 1.0);
   rmAreaSetHeightNoiseEdgeFalloffDist(continentID, 20.0);

   rmAreaBuild(continentID);

   int avoidContinent = rmCreateAreaDistanceConstraint(continentID, 1.0);

   rmSetProgress(0.2);

   // KotH.
   placeKotHObjects();

   vector cornerLoc = vectorXZ(1.0, 1.0);
   float continentRadiusMeters = rmXFractionToMeters(cornerLoc.distance(continentLoc));

   // Unlike most other maps, this one places stuff randomly on the continent.
   // Settlements.
   int settlementID = rmObjectDefCreate("settlement");
   rmObjectDefAddItem(settlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(settlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(settlementID, vDefaultSettlementAvoidSiegeShipRange);
   rmObjectDefAddConstraint(settlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(settlementID, vDefaultAvoidKotH);

   addObjectLocsAtOrigin(settlementID, 2 * cNumberPlayers * getMapAreaSizeFactor(), continentLoc,
                         0.0, continentRadiusMeters, cFarSettlementDist);

   generateLocs("settlement locs");

   rmSetProgress(0.3);

   // Continent cliffs.
   int cliffClassID = rmClassCreate();
   int numCliffs = xsRandInt(1, 2) * cNumberPlayers * getMapAreaSizeFactor();

   float cliffMinSize = rmTilesToAreaFraction(200);
   float cliffMaxSize = rmTilesToAreaFraction(400);

   int avoidCliff = rmCreateClassDistanceConstraint(cliffClassID, 1.0);
   int cliffAvoidCliff = rmCreateClassDistanceConstraint(cliffClassID, 35.0);
   int cliffAvoidWater = rmCreateWaterDistanceConstraint(true, 40.0);
   int cliffAvoidBuilding = rmCreateTypeDistanceConstraint(cUnitTypeBuilding, 20.0);

   for(int i = 0; i < numCliffs; i++)   {
      int cliffID = rmAreaCreate("cliff " + i);
      rmAreaSetParent(cliffID, continentID);

      rmAreaSetSize(cliffID, xsRandFloat(cliffMinSize, cliffMaxSize));
      rmAreaSetHeightRelative(cliffID, 5.0);

      rmAreaSetCoherence(cliffID, 0.5);
      rmAreaSetEdgeSmoothDistance(cliffID, 2);

      rmAreaAddHeightBlend(cliffID, cBlendCliffInside, cFilter5x5Gaussian);

      rmAreaSetCliffType(cliffID, cCliffNorseGrass);
      if (xsRandBool(0.5) == true)
      {
         rmAreaSetCliffRamps(cliffID, 1, 0.45, 0.1, 1.0);
      }
      else
      {
         rmAreaSetCliffRamps(cliffID, 2, 0.25, 0.1, 1.0);
      }
      rmAreaSetCliffSideRadius(cliffID, 1, 2);
      rmAreaSetCliffRampSteepness(cliffID, 2.0);
      rmAreaSetCliffEmbellishmentDensity(cliffID, 0.25);

      rmAreaAddConstraint(cliffID, cliffAvoidCliff);
      rmAreaAddConstraint(cliffID, cliffAvoidWater);
      rmAreaAddConstraint(cliffID, cliffAvoidBuilding);
      rmAreaSetOriginConstraintBuffer(cliffID, 8.0);
      rmAreaAddToClass(cliffID, cliffClassID);

      rmAreaBuild(cliffID);
   }

   // Embellishment areas.
   int beautificationDefID = rmAreaDefCreate("beautification area");
   rmAreaDefSetSizeRange(beautificationDefID, rmTilesToAreaFraction(75), rmTilesToAreaFraction(150));
   rmAreaDefAddTerrainLayer(beautificationDefID, cTerrainNorseSnowGrass3, 0);
   rmAreaDefAddTerrainLayer(beautificationDefID, cTerrainNorseSnowGrass2, 1);
   rmAreaDefAddTerrainLayer(beautificationDefID, cTerrainNorseSnowGrass1, 2);
   rmAreaDefSetTerrainType(beautificationDefID, cTerrainNorseSnow1);
   rmAreaDefAddConstraint(beautificationDefID, rmCreateWaterDistanceConstraint(true, 40.0));
   rmAreaDefAddConstraint(beautificationDefID, vDefaultAvoidImpassableLand8);
   rmAreaDefAddConstraint(beautificationDefID, vDefaultAvoidAll8);
   rmAreaDefSetAvoidSelfDistance(beautificationDefID, 8.0);
   rmAreaDefCreateAndBuildAreas(beautificationDefID, 5 * cNumberPlayers * getMapAreaSizeFactor());

   // Player areas.
   int playerIslandClassID = rmClassCreate();

   int avoidPlayerIsland = rmCreateClassDistanceConstraint(playerIslandClassID, 0.1);
   int playerIslandAvoidPlayerIsland = rmCreateClassDistanceConstraint(playerIslandClassID, 40.0);

   float playerIslandSize = rmTilesToAreaFraction(1200);

   for(int i = 1; i <= cNumberPlayers; i++)
   {
      int p = vDefaultTeamPlayerOrder[i];

      int playerIslandID = rmAreaCreate("player island " + p);
      rmAreaSetSize(playerIslandID, playerIslandSize);
      rmAreaSetMix(playerIslandID, islandMixID);
      rmAreaSetLocPlayer(playerIslandID, p);

      rmAreaSetCoherence(playerIslandID, 0.5);
      rmAreaSetHeight(playerIslandID, 0.5);
      rmAreaAddHeightBlend(playerIslandID, cBlendAll, cFilter5x5Gaussian, 10, 2.0);

      rmAreaAddConstraint(playerIslandID, playerIslandAvoidPlayerIsland);
      rmAreaAddToClass(playerIslandID, playerIslandClassID);
   }

   rmAreaBuildAll();

   rmSetProgress(0.4);

   // Settlements and towers.
   placeStartingTownCenters();

   // Starting objects.
   // Everything on the starting islands is super tight, so place stuff closer.
   float startingObjectMinDist = 18.0;
   float startingObjectMaxDist = 20.0;

   // Starting towers.
   int startingTowerID = rmObjectDefCreate("starting tower");
   rmObjectDefAddItem(startingTowerID, cUnitTypeSentryTower, 1);
   rmObjectDefAddConstraint(startingTowerID, vDefaultAvoidImpassableLand8);
   addObjectLocsPerPlayer(startingTowerID, true, 4, startingObjectMinDist, startingObjectMaxDist, 20.0);
   generateLocs("starting tower locs");

   // Starting gold.
   int startingGoldID = rmObjectDefCreate("starting gold");
   rmObjectDefAddItem(startingGoldID, cUnitTypeMineGoldMedium, 1);
   rmObjectDefAddConstraint(startingGoldID, vDefaultGoldAvoidWater);
   rmObjectDefAddConstraint(startingGoldID, vDefaultStartingGoldAvoidTower);
   rmObjectDefAddConstraint(startingGoldID, vDefaultForceStartingGoldNearTower);
   addObjectLocsPerPlayer(startingGoldID, false, 1, startingObjectMinDist, startingObjectMaxDist, cStartingObjectAvoidanceMeters);

   generateLocs("starting gold locs");

   // Starting hunt.
   int startingHuntID = rmObjectDefCreate("starting hunt");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeBoar, xsRandInt(2, 3));
   }
   else
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeAurochs, xsRandInt(2, 3));
   }
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHuntID, vDefaultAvoidWater4);
   rmObjectDefAddConstraint(startingHuntID, vDefaultForceInTowerLOS);
   addObjectLocsPerPlayer(startingHuntID, false, 1, startingObjectMinDist, startingObjectMaxDist, cStartingObjectAvoidanceMeters);

   // Chicken.
   int startingChickenID = rmObjectDefCreate("starting chicken");
   rmObjectDefAddItem(startingChickenID, cUnitTypeChicken, xsRandInt(6, 10));
   rmObjectDefSetItemVariation(startingChickenID, 0, cChickenVariationBrown);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingChickenID, vDefaultAvoidWater4);
   addObjectLocsPerPlayer(startingChickenID, false, 1, startingObjectMinDist, startingObjectMaxDist, cStartingObjectAvoidanceMeters);

   generateLocs("starting food locs");

   // Fish.
   int startingFishID = rmObjectDefCreate("starting fish");
   rmObjectDefAddItem(startingFishID, cUnitTypeSalmon, 3, 5.0);
   rmObjectDefAddConstraint(startingFishID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingFishID, rmCreatePassabilityDistanceConstraint(cPassabilityLand, true, 8.0), cObjectConstraintBufferNone);
   rmObjectDefAddConstraint(startingFishID, rmCreatePassabilityMaxDistanceConstraint(cPassabilityLand, true, 12.0), cObjectConstraintBufferNone);
   // TODO Use rmObjectDefPlaceNearLoc instead (make lib fun).
   addObjectLocsPerPlayer(startingFishID, false, 2, 40.0, 60.0, 25.0);

   generateLocs("starting fish locs");

   rmSetProgress(0.5);

   // Gold.
   float avoidGoldMeters = 50.0;

   int goldID = rmObjectDefCreate("gold");
   rmObjectDefAddItem(goldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(goldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(goldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(goldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(goldID, vDefaultAvoidWater24);
   rmObjectDefAddConstraint(goldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(goldID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(goldID, avoidPlayerIsland);
   rmObjectDefAddConstraint(goldID, avoidCliff);
   addObjectLocsAtOrigin(goldID, xsRandInt(3, 4) * cNumberPlayers * getMapAreaSizeFactor(), continentLoc,
                         0.0, continentRadiusMeters, avoidGoldMeters);

   generateLocs("gold locs");

   // Hunt.
   float avoidHuntMeters = 30.0;
   int numHunt = xsRandInt(2, 3) * getMapAreaSizeFactor();

   for(int i = 0; i < numHunt; i++)
   {
      float huntFloat = xsRandFloat(0.0, 1.0);
      int huntID = rmObjectDefCreate("hunt " + i);
      if(huntFloat < 1.0 / 3.0)
      {
         rmObjectDefAddItem(huntID, cUnitTypeCaribou, xsRandInt(4, 8));
      }
      else if(huntFloat < 2.0 / 3.0)
      {
         rmObjectDefAddItem(huntID, cUnitTypeElk, xsRandInt(4, 8));
      }
      else
      {
         rmObjectDefAddItem(huntID, cUnitTypeDeer, xsRandInt(4, 8));
      }
      
      rmObjectDefAddConstraint(huntID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(huntID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(huntID, vDefaultFoodAvoidImpassableLand);
      rmObjectDefAddConstraint(huntID, vDefaultAvoidWater16);
      rmObjectDefAddConstraint(huntID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(huntID, vDefaultAvoidSettlementRange);
      rmObjectDefAddConstraint(huntID, avoidPlayerIsland);
      addObjectLocsAtOrigin(huntID, cNumberPlayers, continentLoc,
                        0.0, continentRadiusMeters, avoidHuntMeters);
   }

   generateLocs("hunt locs");

   rmSetProgress(0.6);

   // Berries.
   float avoidBerriesMeters = 50.0;

   int berriesID = rmObjectDefCreate("berries");
   rmObjectDefAddItem(berriesID, cUnitTypeBerryBush, xsRandInt(5, 9), cBerryClusterRadius);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(berriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(berriesID, vDefaultBerriesAvoidImpassableLand);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidWater24);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(berriesID, avoidPlayerIsland);
   rmObjectDefAddConstraint(berriesID, avoidCliff);
   addObjectLocsAtOrigin(berriesID, cNumberPlayers * getMapSizeBonusFactor(), continentLoc,
                         0.0, continentRadiusMeters, avoidBerriesMeters);

   generateLocs("berry locs");

   // Herdables.
   float avoidHerdMeters = 20.0;
   int numHerd = 2 * getMapAreaSizeFactor();

   for(int i = 0; i < numHerd; i++)
   {
      int herdID = rmObjectDefCreate("herd " + i);
      rmObjectDefAddItem(herdID, cUnitTypeCow, xsRandInt(1, 3));
      rmObjectDefAddConstraint(herdID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(herdID, vDefaultHerdAvoidAll);
      rmObjectDefAddConstraint(herdID, vDefaultHerdAvoidImpassableLand);
      rmObjectDefAddConstraint(herdID, vDefaultAvoidWater16);
      rmObjectDefAddConstraint(herdID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(herdID, avoidPlayerIsland);
      addObjectLocsAtOrigin(herdID, cNumberPlayers, continentLoc,
                         0.0, continentRadiusMeters, avoidHerdMeters);
   }

   generateLocs("herd locs");

   // Predators.
   float avoidPredatorMeters = 50.0;
   int numPred = xsRandInt(1, 2) * getMapAreaSizeFactor();

   for(int i = 0; i < numPred; i++)
   {
      int predatorID = rmObjectDefCreate("pred " + i);
      if(xsRandBool(0.5) == true)
      {
         rmObjectDefAddItem(predatorID, cUnitTypeWolf, xsRandInt(1, 2));
      }
      else
      {
         rmObjectDefAddItem(predatorID, cUnitTypeBear, xsRandInt(1, 2));
      }
      rmObjectDefAddConstraint(predatorID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidImpassableLand);
      rmObjectDefAddConstraint(predatorID, vDefaultAvoidWater16);
      rmObjectDefAddConstraint(predatorID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(predatorID, vDefaultAvoidSettlementRange);
      addObjectLocsAtOrigin(predatorID, cNumberPlayers, continentLoc,
                            0.0, continentRadiusMeters, avoidPredatorMeters);
   }

   generateLocs("pred locs");

   // Relics.
   float avoidRelicMeters = 80.0;

   int relicID = rmObjectDefCreate("relic");
   rmObjectDefAddItem(relicID, cUnitTypeRelic, 1);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidAll);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidImpassableLand);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidWater16);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(relicID, avoidPlayerIsland);
   addObjectLocsAtOrigin(relicID, 2 * cNumberPlayers * getMapAreaSizeFactor(), continentLoc,
                         0.0, continentRadiusMeters, avoidRelicMeters);

   generateLocs("relic locs");

   rmSetProgress(0.7);

   // Forests.
   float avoidPlayerForestMeters = 20.0;
   float startingForestMinDist = 18.0;
   float startingForestMaxDist = 30.0;

   int playerForestDefID = rmAreaDefCreate("player forest");
   rmAreaDefSetSizeRange(playerForestDefID, rmTilesToAreaFraction(25), rmTilesToAreaFraction(30));
   rmAreaDefSetForestType(playerForestDefID, cForestNorsePineSnow);
   rmAreaDefSetAvoidSelfDistance(playerForestDefID, avoidPlayerForestMeters);
   rmAreaDefAddConstraint(playerForestDefID, vDefaultAvoidAll8);
   rmAreaDefAddConstraint(playerForestDefID, vDefaultAvoidWater4);
   rmAreaDefAddConstraint(playerForestDefID, vDefaultForestAvoidTownCenter);

   // Starting forests.
   if(gameIs1v1() == true)
   {
      addSimAreaLocsPerPlayerPair(playerForestDefID, 3, startingForestMinDist, startingForestMaxDist, avoidPlayerForestMeters);
   }
   else
   {
      addAreaLocsPerPlayer(playerForestDefID, 3, startingForestMinDist, startingForestMaxDist, avoidPlayerForestMeters);
   }

   generateLocs("starting forest locs");

   // Global forests.
   float avoidForestMeters = 30.0;

   int forestDefID = rmAreaDefCreate("forest");
   rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(75), rmTilesToAreaFraction(150));
   rmAreaDefSetForestType(forestDefID, cForestNorsePine);
   rmAreaDefSetAvoidSelfDistance(forestDefID, avoidForestMeters);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidImpassableLand8);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidWater16);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddConstraint(forestDefID, avoidPlayerIsland);
   rmAreaDefAddConstraint(forestDefID, avoidCliff);
   // rmAreaDefSetConstraintBuffer(playerForestDefID, 0.0, 6.0);

   rmAreaDefCreateAndBuildAreas(forestDefID, 6 * cNumberPlayers * getMapAreaSizeFactor());

   // Stragglers.
   placeStartingStragglers(cUnitTypeTreePineSnow);

   rmSetProgress(0.8);

   // Global fish.
   float avoidFishMeters = 25.0;

   int globalFishID = rmObjectDefCreate("global fish");
   rmObjectDefAddItem(globalFishID, cUnitTypeSalmon, 3, 5.0);
   rmObjectDefAddConstraint(globalFishID, vDefaultAvoidEdge);
   // Avoid players.
   rmObjectDefAddConstraint(globalFishID, rmCreateClassDistanceConstraint(playerIslandClassID, 30.0));
   // Avoid other fish.
   rmObjectDefAddConstraint(globalFishID, rmCreateTypeDistanceConstraint(cUnitTypeFishResource, avoidFishMeters));
      // Avoid other passable land.
   rmObjectDefAddConstraint(globalFishID, rmCreatePassabilityDistanceConstraint(cPassabilityLand, true, 15.0), cObjectConstraintBufferNone);
   rmObjectDefAddConstraint(globalFishID, rmCreatePassabilityMaxDistanceConstraint(cPassabilityLand, true, 30.0), cObjectConstraintBufferNone);
   addObjectLocsAtOrigin(globalFishID, (8 * sqrt(cNumberPlayers)) * getMapAreaSizeFactor(), continentLoc, 0.0, -1.0, avoidFishMeters);

   generateLocs("global fish locs");

   // Free transport ship.
   int transportAvoidLand = rmCreatePassabilityDistanceConstraint(cPassabilityLand, true, 2.0);
   int transportForceNearLand = rmCreatePassabilityMaxDistanceConstraint(cPassabilityLand, true, 8.0);
   // Cheap trick to prevent the transport from spawning next to the neighboring instead of our own island.
   float transportMaxPlayerLocDist = min(60.0, 0.45 * getShortestPlayerLocDistance());

   for(int i = 1; i <= cNumberPlayers; i++)
   {
      int p = vDefaultTeamPlayerOrder[i];
      int culture = rmGetPlayerCulture(p);

      int transportID = rmObjectDefCreate("transport ship " + p);
      if(culture == cCultureGreek)
      {
         rmObjectDefAddItem(transportID, cUnitTypeTransportShipGreek, 1);
      }
      else if(culture == cCultureEgyptian)
      {
         rmObjectDefAddItem(transportID, cUnitTypeTransportShipEgyptian, 1);
      }
      else if(culture == cCultureNorse)
      {
         rmObjectDefAddItem(transportID, cUnitTypeTransportShipNorse, 1);
      }
      else if(culture == cCultureAtlantean)
      {
         rmObjectDefAddItem(transportID, cUnitTypeTransportShipAtlantean, 1);
      }
      else if(culture == cCultureChinese)
      {
         rmObjectDefAddItem(transportID, cUnitTypeTransportShipChinese, 1);
      }
      else
      {
         rmEchoError("Invalid/missing culture!");
      }
      rmObjectDefAddConstraint(transportID, transportAvoidLand, cObjectConstraintBufferNone);
      rmObjectDefAddConstraint(transportID, transportForceNearLand, cObjectConstraintBufferNone);
      rmObjectDefAddConstraint(transportID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(transportID, vDefaultAvoidCorner40);

      addObjectLocsForPlayer(transportID, true, p, 1, 30.0, transportMaxPlayerLocDist, 0.0, cBiasDefensive);
   }

   generateLocs("starting transport locs");

   rmSetProgress(0.9);

   // Embellishment.
   buildAreaUnderObjectDef(startingGoldID, cTerrainNorseSnowRocks2, cTerrainNorseSnowRocks1, 6.0);

   // TODO Smart way for terrain replacements for areas under objects on continents.

   // Random trees.
   int randomTreeID = rmObjectDefCreate("random tree");
   rmObjectDefAddItem(randomTreeID, cUnitTypeTreePine, 1);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidImpassableLand);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidTree);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefAddConstraint(randomTreeID, avoidPlayerIsland);
   rmObjectDefPlaceAnywhere(randomTreeID, 0, 5 * cNumberPlayers * getMapAreaSizeFactor());

   // Rocks.
   int rockTinyID = rmObjectDefCreate("rock tiny");
   rmObjectDefAddItem(rockTinyID, cUnitTypeRockGreekTiny, 1);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(rockTinyID, avoidPlayerIsland);
   rmObjectDefPlaceAnywhere(rockTinyID, 0, 35 * cNumberPlayers * getMapAreaSizeFactor());

   int rockSmallID = rmObjectDefCreate("rock small");
   rmObjectDefAddItem(rockSmallID, cUnitTypeRockGreekSmall, 1);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(rockSmallID, avoidPlayerIsland);
   rmObjectDefPlaceAnywhere(rockSmallID, 0, 35 * cNumberPlayers * getMapAreaSizeFactor());

   // Lush Plants.
   int avoidSnow1 = rmCreateTerrainTypeDistanceConstraint(cTerrainNorseSnow1, 1.0);
   int avoidSnow2 = rmCreateTerrainTypeDistanceConstraint(cTerrainNorseSnow2, 1.0);
   int avoidSnowGrass1 = rmCreateTerrainTypeDistanceConstraint(cTerrainNorseSnowGrass1, 1.0);
   int avoidSnowGrass2 = rmCreateTerrainTypeDistanceConstraint(cTerrainNorseSnowGrass2, 1.0);

   int grassID = rmObjectDefCreate("grass");
   rmObjectDefAddItem(grassID, cUnitTypePlantNorseGrass, 1);
   rmObjectDefAddConstraint(grassID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(grassID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(grassID, vDefaultAvoidWater16);
   rmObjectDefAddConstraint(grassID, avoidSnow1);
   rmObjectDefAddConstraint(grassID, avoidSnow2);
   rmObjectDefAddConstraint(grassID, avoidSnowGrass1);
   rmObjectDefAddConstraint(grassID, avoidSnowGrass2);
   rmObjectDefAddConstraint(grassID, avoidPlayerIsland);
   rmObjectDefPlaceAnywhere(grassID, 0, 40 * cNumberPlayers * getMapAreaSizeFactor());

   int bushID = rmObjectDefCreate("bush");
   rmObjectDefAddItem(bushID, cUnitTypePlantNorseBush, 1);
   rmObjectDefAddConstraint(bushID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(bushID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(bushID, vDefaultAvoidWater16);
   rmObjectDefAddConstraint(bushID, avoidSnow1);
   rmObjectDefAddConstraint(bushID, avoidSnow2);
   rmObjectDefAddConstraint(bushID, avoidSnowGrass1);
   rmObjectDefAddConstraint(bushID, avoidSnowGrass2);
   rmObjectDefAddConstraint(bushID, avoidPlayerIsland);
   rmObjectDefPlaceAnywhere(bushID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   int shrubID = rmObjectDefCreate("shrub");
   rmObjectDefAddItem(shrubID, cUnitTypePlantNorseShrub, 1);
   rmObjectDefAddConstraint(shrubID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(shrubID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(shrubID, vDefaultAvoidWater16);
   rmObjectDefAddConstraint(shrubID, avoidSnow1);
   rmObjectDefAddConstraint(shrubID, avoidSnow2);
   rmObjectDefAddConstraint(shrubID, avoidSnowGrass1);
   rmObjectDefAddConstraint(shrubID, avoidSnowGrass2);
   rmObjectDefAddConstraint(shrubID, avoidPlayerIsland);
   rmObjectDefPlaceAnywhere(shrubID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());

   int weedsID = rmObjectDefCreate("weeds");
   rmObjectDefAddItem(weedsID, cUnitTypePlantNorseWeeds, 1);
   rmObjectDefAddConstraint(weedsID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(weedsID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(weedsID, vDefaultAvoidWater16);
   rmObjectDefAddConstraint(weedsID, avoidSnow1);
   rmObjectDefAddConstraint(weedsID, avoidSnow2);
   rmObjectDefAddConstraint(weedsID, avoidSnowGrass1);
   rmObjectDefAddConstraint(weedsID, avoidSnowGrass2);
   rmObjectDefAddConstraint(weedsID, avoidPlayerIsland);
   rmObjectDefPlaceAnywhere(weedsID, 0, 20 * cNumberPlayers * getMapAreaSizeFactor());

   // Snow Plants.
   int grassSnowID = rmObjectDefCreate("grass snow");
   rmObjectDefAddItem(grassSnowID, cUnitTypePlantSnowGrass, 1);
   rmObjectDefAddConstraint(grassSnowID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(grassSnowID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(grassSnowID, vDefaultAvoidWater4);
   rmObjectDefAddConstraint(grassSnowID, avoidContinent);
   rmObjectDefPlaceAnywhere(grassSnowID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   int shrubSnowID = rmObjectDefCreate("shrub snow");
   rmObjectDefAddItem(shrubSnowID, cUnitTypePlantSnowShrub, 1);
   rmObjectDefAddConstraint(shrubSnowID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(shrubSnowID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(shrubSnowID, vDefaultAvoidWater4);
   rmObjectDefAddConstraint(shrubSnowID, avoidContinent);
   rmObjectDefPlaceAnywhere(shrubSnowID, 0, 5 * cNumberPlayers * getMapAreaSizeFactor());

   int weedsSnowID = rmObjectDefCreate("weeds snow");
   rmObjectDefAddItem(weedsSnowID, cUnitTypePlantSnowWeeds, 1);
   rmObjectDefAddConstraint(weedsSnowID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(weedsSnowID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(weedsSnowID, vDefaultAvoidWater4);
   rmObjectDefAddConstraint(weedsSnowID, avoidContinent);
   rmObjectDefPlaceAnywhere(weedsSnowID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   // Logs.
   int logID = rmObjectDefCreate("log");
   rmObjectDefAddItem(logID, cUnitTypeRottingLog, 1);
   rmObjectDefAddConstraint(logID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(logID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(logID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(logID, avoidPlayerIsland);
   rmObjectDefPlaceAnywhere(logID, 0, 4 * cNumberPlayers * getMapAreaSizeFactor());

   int logGroupID = rmObjectDefCreate("log group");
   rmObjectDefAddItem(logGroupID, cUnitTypeRottingLog, 2, 2.0);
   rmObjectDefAddConstraint(logGroupID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(logGroupID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(logGroupID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(logGroupID, avoidPlayerIsland);
   rmObjectDefPlaceAnywhere(logGroupID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeHawk, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 4 * cNumberPlayers * getMapAreaSizeFactor());

   rmSetProgress(1.0);
}
