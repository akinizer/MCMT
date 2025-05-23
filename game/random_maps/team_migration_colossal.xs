include "lib2/rm_core.xs";

// Override.
mutable void applySuddenDeath()
{
   // Remove all settlements.
   rmRemoveUnitType(cUnitTypeSettlement);

   // Add some tents (not around towers).
   int tentID = rmObjectDefCreate(cSuddenDeathTentName);
   rmObjectDefAddItem(tentID, cUnitTypeTent, 1);
   rmObjectDefAddConstraint(tentID, vDefaultAvoidCollideable);
   addObjectLocsPerPlayer(tentID, true, cNumberSuddenDeathTents, cStartingTowerMinDist - 10.0,
                          cStartingTowerMaxDist + 10.0, cStartingTowerAvoidanceMeters);

   generateLocs("sudden death tent locs");
}

void generate()
{
   rmSetProgress(0.0);
   
   // Define Mixes.
   int baseMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.15, 5, 0.5);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainAtlanteanDirt1, 1.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainAtlanteanDirt2, 1.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainAtlanteanDirt3, 1.0);
   
   int continentMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(continentMixID, cNoiseFractalSum, 0.15, 5, 0.5);
   rmCustomMixAddPaintEntry(continentMixID, cTerrainAtlanteanGrass2, 2.0);
   rmCustomMixAddPaintEntry(continentMixID, cTerrainAtlanteanGrass1, 2.0);
   rmCustomMixAddPaintEntry(continentMixID, cTerrainAtlanteanGrassDirt1, 2.0);

   // Water overrides.
   rmWaterTypeAddBeachLayer(cWaterAtlanteanSea, cTerrainAtlanteanBeach1, 3.0, 2.0);
   rmWaterTypeAddBeachLayer(cWaterAtlanteanSea, cTerrainAtlanteanDirt1, 6.0);

   // Set size.
   float sclr=3;
   if(cMapSizeCurrent == 1)
   {
      sclr=4;
   }

   // Map size and terrain init.
   int axisTiles = (gameIs1v1() == true) ? getScaledAxisTiles(168*sclr) : getScaledAxisTiles(128*sclr);
   rmSetMapSize(axisTiles);
   rmInitializeWater(cWaterAtlanteanSea);

   // Player placement.
   // TODO Better way of computing team spacing modifier.
   rmSetTeamSpacingModifier(0.2 + 0.025 * cNumberPlayers);

   // TODO Solve this by specifying a placement range instead?
   if(gameIs1v1() == true)
   {
      // Total circumference: 8 * radius = 3.2; use 0.5 in each direction.
      rmPlacePlayersOnSquare(0.4, 0.4, 0.0, rmXFractionToMeters(0.5));
   }
   else
   {
      rmPlacePlayersOnSquare(0.45, 0.45, 0.0, rmXFractionToMeters(0.025));
   }

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCivFromCulture(cCultureAtlantean);

   // Lighting.
   rmSetLighting(cLightingSetRmTeamMigration01);

   rmSetProgress(0.1);

   // Terrain classes and constraints.
   int continentClassID = rmClassCreate();
   int teamContinentClassID = rmClassCreate();
   int continentAvoidContinent = rmCreateClassDistanceConstraint(continentClassID, 30.0);

   // Team continents.
   float teamAreaPerPlayer = (gameIs1v1() == true) ? 0.05 : (0.175 / cNumberPlayers);

   for(int i = 1; i <= cNumberTeams; i++)
   {
      int teamContinentID = rmAreaCreate("team continent " + i);
      rmAreaSetSize(teamContinentID, (teamAreaPerPlayer * rmGetNumberPlayersOnTeam(i)));
      rmAreaSetMix(teamContinentID, baseMixID);
      rmAreaSetLocTeam(teamContinentID, i);

	  rmAreaSetHeight(teamContinentID, 0.5);
	  rmAreaAddHeightBlend(teamContinentID, cBlendAll, cFilter5x5Box, 10, 5);
      
	  rmAreaAddConstraint(teamContinentID, continentAvoidContinent);
	  rmAreaAddToClass(teamContinentID, teamContinentClassID);
     rmAreaAddToClass(teamContinentID, continentClassID);
   }

   // Center continent.
   int centerContinentID = rmAreaCreate("continent");
   rmAreaSetSize(centerContinentID, 0.375);
   rmAreaSetLoc(centerContinentID, cCenterLoc);
   // The first few tiles will be overwritten by the shoreline, and that's okay.
   rmAreaAddTerrainLayer(centerContinentID, cTerrainAtlanteanDirt1, 0, 4);
   rmAreaAddTerrainLayer(centerContinentID, cTerrainAtlanteanGrassDirt3, 4);
   rmAreaAddTerrainLayer(centerContinentID, cTerrainAtlanteanGrassDirt2, 5);
   rmAreaAddTerrainLayer(centerContinentID, cTerrainAtlanteanGrassDirt1, 6);
   rmAreaSetMix(centerContinentID, continentMixID);
   
   rmAreaSetHeight(centerContinentID, 0.5);
	rmAreaAddHeightBlend(centerContinentID, cBlendAll, cFilter5x5Box, 10, 5);
   rmAreaSetBlobs(centerContinentID, 5, 5);
   rmAreaSetBlobDistance(centerContinentID, smallerFractionToMeters(0.15));
   
   // The continent should never touch the edge.
   rmAreaAddConstraint(centerContinentID, createSymmetricBoxConstraint(rmXTileIndexToFraction(10)), 0.0, 10.0);
   rmAreaAddConstraint(centerContinentID, continentAvoidContinent);
   rmAreaAddToClass(centerContinentID, continentClassID);

   // Build continent and team continents simultaneously.
   rmAreaBuildAll();

   // KotH.
   placeKotHObjects();

   // Force on center constraint.
   int avoidCenterContinent = rmCreateAreaDistanceConstraint(centerContinentID, 0.1);
   int avoidTeamContinent = rmCreateClassDistanceConstraint(teamContinentClassID, 1.0);
   int forceInCenterContinent = rmCreateAreaConstraint(centerContinentID);

   rmSetProgress(0.2);

   int inAreaType = (gameIsFair() == true) ? cInAreaTeam : cInAreaNone;

   // Settlements and towers.
   placeStartingTownCenters();

   // First settlement.
   int firstSettlementID = rmObjectDefCreate("first settlement");
   rmObjectDefAddItem(firstSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidWater);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(firstSettlementID, avoidTeamContinent);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidKotH);
   addObjectLocsPerPlayer(firstSettlementID, false, 1, 100.0, -1.0, cFarSettlementDist, cBiasNone, inAreaType);

   // Second settlement.
   int secondSettlementID = rmObjectDefCreate("second settlement");
   rmObjectDefAddItem(secondSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidWater);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(secondSettlementID, avoidTeamContinent);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidKotH);
   addObjectLocsPerPlayer(secondSettlementID, false, 1, 100.0, -1.0, cFarSettlementDist, cBiasNone, inAreaType);

   // Other map sizes settlements.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int bonusSettlementID = rmObjectDefCreate("bonus settlement");
      rmObjectDefAddItem(bonusSettlementID, cUnitTypeSettlement, 1);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidEdge);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidWater);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(bonusSettlementID, avoidTeamContinent);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidKotH);
      addObjectLocsPerPlayer(bonusSettlementID, false, 1 * getMapAreaSizeFactor(), 100.0, -1.0, cFarSettlementDist);
   }

   generateLocs("settlement locs");

   rmSetProgress(0.3);

   // Center cliffs.
   int cliffClassID = rmClassCreate();
   int numCliffs = cNumberPlayers * getMapAreaSizeFactor();
   if(gameIs1v1() == true & xsRandBool(1.0) == true)
   {
      numCliffs *= 2;
   }

   float cliffMinSize = rmTilesToAreaFraction(250);
   float cliffMaxSize = rmTilesToAreaFraction(300);

   int cliffAvoidCliff = rmCreateClassDistanceConstraint(cliffClassID, 30.0);
   int cliffAvoidBuildings = rmCreateTypeDistanceConstraint(cUnitTypeBuilding, 20.0);

   for(int i = 0; i < numCliffs; i++)
   {
      int cliffID = rmAreaCreate("cliff " + i);
      rmAreaSetParent(cliffID, centerContinentID);

      rmAreaSetMix(cliffID, continentMixID);
      rmAreaSetCliffType(cliffID, cCliffAtlanteanGrass);
      rmAreaSetCliffEmbellishmentDensity(cliffID, 0.25);

      // Randomize between 1 ramp and full cliff.
      if(xsRandBool(0.5) == true)
      {
         rmAreaSetSize(cliffID, xsRandFloat(cliffMinSize, cliffMaxSize));
         rmAreaSetCliffRamps(cliffID, 1, 0.4, 0.0, 1.0);
         rmAreaSetCliffRampSteepness(cliffID, 1.0);
         rmAreaSetHeightRelative(cliffID, 6.0);
      }
      else
      {
         rmAreaSetSize(cliffID, 0.5 * xsRandFloat(cliffMinSize, cliffMaxSize));
         rmAreaSetCliffPaintInsideAsSide(cliffID, true);
         rmAreaSetHeightNoise(cliffID, cNoiseFractalSum, 10.0, 0.15, 2, 0.5);
         rmAreaSetHeightNoiseBias(cliffID, 1.0);
         rmAreaSetHeightRelative(cliffID, 3.0);
         rmAreaSetBlobs(cliffID, 1, 4);
         rmAreaSetBlobDistance(cliffID, 10.0, 20.0);
      }

      rmAreaSetEdgeSmoothDistance(cliffID, 2);
      rmAreaSetCoherence(cliffID, 0.25);

      rmAreaAddConstraint(cliffID, vDefaultAvoidWater16);
      rmAreaAddConstraint(cliffID, cliffAvoidCliff);
      rmAreaAddConstraint(cliffID, cliffAvoidBuildings);
      rmAreaSetOriginConstraintBuffer(cliffID, 10.0);
      rmAreaAddToClass(cliffID, cliffClassID);

      rmAreaBuild(cliffID);
   }

   rmSetProgress(0.4);

   // Starting objects.
   // Starting gold.
   int startingGoldID = rmObjectDefCreate("starting gold");
   rmObjectDefAddItem(startingGoldID, cUnitTypeMineGoldMedium, 1);
   rmObjectDefAddConstraint(startingGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingGoldID, vDefaultGoldAvoidWater);
   addObjectLocsPerPlayer(startingGoldID, false, 1, 16.0, 20.0, cStartingObjectAvoidanceMeters);

   generateLocs("starting gold locs");

   // Berries.
   int startingBerriesID = rmObjectDefCreate("starting berries");
   rmObjectDefAddItem(startingBerriesID, cUnitTypeBerryBush, xsRandInt(6, 9), cBerryClusterRadius);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidWater);
   addObjectLocsPerPlayer(startingBerriesID, false, 1, cStartingBerriesMinDist, cStartingBerriesMaxDist, cStartingObjectAvoidanceMeters);

   // Starting hunt.
   int startingHuntID = rmObjectDefCreate("starting hunt");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeHippopotamus, xsRandInt(3, 4));
   }
   else
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeWaterBuffalo, xsRandInt(3, 4));
   }
   rmObjectDefAddConstraint(startingHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidWater);
   addObjectLocsPerPlayer(startingHuntID, false, 1, 18.0, 24.0, cStartingObjectAvoidanceMeters);

   // Chicken.
   int startingChickenID = rmObjectDefCreate("starting chicken");
   rmObjectDefAddItem(startingChickenID, cUnitTypeChicken, xsRandInt(5, 9));
   rmObjectDefAddConstraint(startingChickenID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidWater);
   addObjectLocsPerPlayer(startingChickenID, false, 1, 15.0, 25.0, cStartingObjectAvoidanceMeters);

   generateLocs("starting food locs");

   rmSetProgress(0.5);

   // Gold.
   float avoidGoldMeters = 50.0;

   // Bonus gold.
   int bonusGoldID = rmObjectDefCreate("bonus gold");
   rmObjectDefAddItem(bonusGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidImpassableLand16);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(bonusGoldID, forceInCenterContinent);
   addObjectDefPlayerLocConstraint(bonusGoldID, 100.0);
   addObjectLocsPerPlayer(bonusGoldID, false, 3 * getMapAreaSizeFactor(), 100.0, -1.0, avoidGoldMeters, cBiasNone, inAreaType);

   generateLocs("center gold locs");

   // Hunt.
   float avoidHuntMeters = 30.0;

   // Bonus hunt.
   int numBonusHunt = xsRandInt(2, 3) * getMapAreaSizeFactor();
   for(int i = 0; i < numBonusHunt; i++)
   {
      float bonusHuntFloat = xsRandFloat(0.0, 1.0);
      int bonusHuntID = rmObjectDefCreate("bonus hunt " + i);
      if(bonusHuntFloat < 0.25)
      {
         rmObjectDefAddItem(bonusHuntID, cUnitTypeDeer, xsRandInt(5, 7));
      }
      else if(bonusHuntFloat < 0.5)
      {
         rmObjectDefAddItem(bonusHuntID, cUnitTypeWaterBuffalo, xsRandInt(2, 4));
      }
      else if(bonusHuntFloat < 0.75)
      {
         rmObjectDefAddItem(bonusHuntID, cUnitTypeHippopotamus, xsRandInt(2, 4));
      }
      else
      {
         rmObjectDefAddItem(bonusHuntID, cUnitTypeBoar, xsRandInt(2, 4));
      }
      rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidWater);
      rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidImpassableLand);
      rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidSettlementRange);
      rmObjectDefAddConstraint(bonusHuntID, forceInCenterContinent);
      addObjectDefPlayerLocConstraint(bonusHuntID, 100.0);
      addObjectLocsPerPlayer(bonusHuntID, false, 1, 100.0, -1.0, avoidHuntMeters, cBiasNone, inAreaType);
   }

   generateLocs("hunt locs");

   rmSetProgress(0.6);

   // Berries.
   float avoidBerriesMeters = 50.0;

   int berriesID = rmObjectDefCreate("berries");
   rmObjectDefAddItem(berriesID, cUnitTypeBerryBush, xsRandInt(5, 9), cBerryClusterRadius);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(berriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(berriesID, vDefaultBerriesAvoidWater);
   rmObjectDefAddConstraint(berriesID, vDefaultBerriesAvoidImpassableLand);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(berriesID, 100.0);
   addObjectLocsPerPlayer(berriesID, false, 1 * getMapSizeBonusFactor(), 100.0, -1.0, avoidBerriesMeters);

   generateLocs("berries locs");

   // Herdables.
   float avoidHerdMeters = 50.0;

   int bonusHerdID = rmObjectDefCreate("bonus herd");
   rmObjectDefAddItem(bonusHerdID, cUnitTypePig, xsRandInt(1, 3));
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidWater);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHerdID, forceInCenterContinent);
   addObjectLocsPerPlayer(bonusHerdID, false, xsRandInt(2, 3) * getMapAreaSizeFactor(), 100.0, -1.0, avoidHerdMeters, cBiasNone, inAreaType);

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
   rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(predatorID, forceInCenterContinent);
   addObjectDefPlayerLocConstraint(predatorID, 100.0);
   addObjectLocsPerPlayer(predatorID, false, 1 * getMapAreaSizeFactor(), 100.0, -1.0, avoidPredatorMeters, cBiasNone, inAreaType);

   generateLocs("predator locs");

   // Relics.
   float avoidRelicMeters = 80.0;

   int relicID = rmObjectDefCreate("relic");
   rmObjectDefAddItem(relicID, cUnitTypeRelic, 1);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidAll);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidImpassableLand8);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidWater8);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(relicID, forceInCenterContinent);
   addObjectLocsPerPlayer(relicID, false, 2 * getMapAreaSizeFactor(), 100.0, -1.0, avoidRelicMeters, cBiasNone, inAreaType);

   generateLocs("relic locs");

   rmSetProgress(0.7);

   // Forests.
   float avoidForestMeters = 30.0;

   int forestDefID = rmAreaDefCreate("forest");
   rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(60), rmTilesToAreaFraction(120));
   rmAreaDefSetForestType(forestDefID, cForestAtlantean);
   rmAreaDefSetAvoidSelfDistance(forestDefID, avoidForestMeters);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidWater4);
   rmAreaDefAddConstraint(forestDefID, rmCreateClassDistanceConstraint(cliffClassID, 10.0));
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidTownCenter);
   // rmAreaDefSetConstraintBuffer(forestDefID, 0.0, 4.0);

   // Starting forests.
   if(gameIs1v1() == true)
   {
      addSimAreaLocsPerPlayerPair(forestDefID, 2, cStartingForestMinDist, cStartingForestMaxDist, avoidForestMeters);
   }
   else
   {
      addAreaLocsPerPlayer(forestDefID, 2, cStartingForestMinDist, cStartingForestMaxDist, avoidForestMeters);
   }

   generateLocs("starting forest locs");

   // Global forests.
   // Avoid player areas.
   rmAreaDefAddConstraint(forestDefID, forceInCenterContinent);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidWater10);

   // Avoid the owner paths to prevent forests from closing off resources.
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidOwnerPaths, 0.0);
   // rmAreaDefSetConstraintBuffer(forestDefID, 0.0, 6.0);

   // Build for each player in the team area.
   buildAreaDefInTeamAreas(forestDefID, 10 * getMapAreaSizeFactor());

   // Stragglers.
   placeStartingStragglers(cUnitTypeTreePalm);

   rmSetProgress(0.8);

   // Fish.
   float fishDistMeters = 35.0;

   int fishID = rmObjectDefCreate("player fish");
   rmObjectDefAddItem(fishID, cUnitTypeMahi, 3, 6.0);
   rmObjectDefAddConstraint(fishID, rmCreatePassabilityDistanceConstraint(cPassabilityLand, true, 10.0));
   rmObjectDefAddConstraint(fishID, rmCreatePassabilityMaxDistanceConstraint(cPassabilityLand, true, 40.0), cObjectConstraintBufferNone);
   rmObjectDefAddConstraint(fishID, rmCreateTypeDistanceConstraint(cUnitTypeFishResource, fishDistMeters), cObjectConstraintBufferNone);
   addObjectLocsPerPlayer(fishID, false, 5, 30.0, rmXFractionToMeters(1.0), fishDistMeters, cBiasNone, inAreaType);

   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int globalFishID = rmObjectDefCreate("global fish");
      rmObjectDefAddItem(globalFishID, cUnitTypeMahi, 3, 6.0);
      rmObjectDefAddConstraint(globalFishID, rmCreatePassabilityDistanceConstraint(cPassabilityLand, true, 30.0));
      rmObjectDefAddConstraint(globalFishID, rmCreateTypeDistanceConstraint(cUnitTypeFishResource, fishDistMeters));
      addObjectLocsPerPlayer(globalFishID, false, 6 * getMapSizeBonusFactor(), 30.0, rmXFractionToMeters(1.0), fishDistMeters, cBiasNone, inAreaType);
   }

   generateLocs("fish locs");

   // Free transport ship.
   int transportAvoidLand = rmCreatePassabilityDistanceConstraint(cPassabilityLand, true, 2.0);

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
      // In case we have a small corner "lake" from how the continents are built.
      rmObjectDefAddConstraint(transportID, vDefaultAvoidCorner40);
      rmObjectDefPlaceNearLoc(transportID, p, rmGetPlayerLoc(p));
   }

   rmSetProgress(0.9);

   // Gold.
   buildAreaUnderObjectDef(startingGoldID, cTerrainAtlanteanDirtRocks2, cTerrainAtlanteanDirtRocks1, 6.0);
   buildAreaUnderObjectDef(bonusGoldID, cTerrainAtlanteanGrassRocks2, cTerrainAtlanteanGrassRocks1, 6.0);

   // Berries.
   buildAreaUnderObjectDef(startingBerriesID, cTerrainAtlanteanGrass2, cTerrainAtlanteanGrassDirt1, 12.0);
   buildAreaUnderObjectDef(berriesID, cTerrainAtlanteanGrass2, cTerrainAtlanteanGrass1, 12.0);

   // Embellishment.
   // Random trees.
   int randomTreeID = rmObjectDefCreate("random tree");
   rmObjectDefAddItem(randomTreeID, cUnitTypeTreePalm, 1);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidAll);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidImpassableLand8);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidTree);
   rmObjectDefPlaceAnywhere(randomTreeID, 0, 5 * cNumberPlayers * getMapAreaSizeFactor());

   // Rocks.
   int rockTinyID = rmObjectDefCreate("rock tiny");
   rmObjectDefAddItem(rockTinyID, cUnitTypeRockAtlanteanTiny, 1);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockTinyID, vDefaultAvoidImpassableLand8);
   rmObjectDefPlaceAnywhere(rockTinyID, 0, 50 * cNumberPlayers * getMapAreaSizeFactor());

   int rockSmallID = rmObjectDefCreate("rock small");
   rmObjectDefAddItem(rockSmallID, cUnitTypeRockAtlanteanSmall, 1);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockSmallID, vDefaultAvoidImpassableLand8);
   rmObjectDefPlaceAnywhere(rockSmallID, 0, 50 * cNumberPlayers * getMapAreaSizeFactor());

   // Plants.
   int plantGrassID = rmObjectDefCreate("plant grass");
   rmObjectDefAddItem(plantGrassID, cUnitTypePlantAtlanteanGrass, 1);
   rmObjectDefAddConstraint(plantGrassID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantGrassID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(plantGrassID, vDefaultAvoidWater10);
   rmObjectDefAddConstraint(plantGrassID, avoidTeamContinent);
   rmObjectDefPlaceAnywhere(plantGrassID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantShrubID = rmObjectDefCreate("plant shrub");
   rmObjectDefAddItem(plantShrubID, cUnitTypePlantAtlanteanShrub, 1);
   rmObjectDefAddConstraint(plantShrubID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantShrubID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(plantShrubID, vDefaultAvoidWater10);
   rmObjectDefAddConstraint(plantShrubID, avoidTeamContinent);
   rmObjectDefPlaceAnywhere(plantShrubID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantBushID = rmObjectDefCreate("plant bush");
   rmObjectDefAddItem(plantBushID, cUnitTypePlantAtlanteanShrub, 1);
   rmObjectDefAddConstraint(plantBushID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantBushID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(plantBushID, vDefaultAvoidWater10);
   rmObjectDefAddConstraint(plantBushID, avoidTeamContinent);
   rmObjectDefPlaceAnywhere(plantBushID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantFernID = rmObjectDefCreate("plant fern");
   rmObjectDefAddItemRange(plantFernID, cUnitTypePlantAtlanteanFern, 1);
   rmObjectDefAddConstraint(plantFernID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantFernID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(plantFernID, vDefaultAvoidWater10);
   rmObjectDefAddConstraint(plantFernID, avoidTeamContinent);
   rmObjectDefPlaceAnywhere(plantFernID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantWeedsID = rmObjectDefCreate("plant weeds");
   rmObjectDefAddItemRange(plantWeedsID, cUnitTypePlantAtlanteanWeeds, 1);
   rmObjectDefAddConstraint(plantWeedsID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantWeedsID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(plantWeedsID, vDefaultAvoidWater10);
   rmObjectDefAddConstraint(plantWeedsID, avoidTeamContinent);
   rmObjectDefPlaceAnywhere(plantWeedsID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());

   // Seaweed.
   int seaweedID = rmObjectDefCreate("seaweed");
   rmObjectDefAddItem(seaweedID, cUnitTypeSeaweed, 1);
   rmObjectDefAddConstraint(seaweedID, rmCreateMinWaterDepthConstraint(1.25));
   rmObjectDefAddConstraint(seaweedID, rmCreateMaxWaterDepthConstraint(2.75));
   rmObjectDefPlaceAnywhere(seaweedID, 0, 200 * sqrt(cNumberPlayers) * getMapAreaSizeFactor());

   // Orcas.
   int orcaID = rmObjectDefCreate("orca");
   rmObjectDefAddItem(orcaID, cUnitTypeOrca);
   rmObjectDefAddConstraint(orcaID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(orcaID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(orcaID, vDefaultAvoidLand20);
   rmObjectDefAddConstraint(orcaID, createSymmetricBoxConstraint(rmXMetersToFraction(16.0), rmZMetersToFraction(16.0)));
   rmObjectDefAddConstraint(orcaID, rmCreateTypeDistanceConstraint(cUnitTypeOrca, 40.0));
   rmObjectDefPlaceAnywhere(orcaID, 0, 3 * cNumberPlayers * getMapAreaSizeFactor());

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeHawk, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   rmSetProgress(1.0);
}
