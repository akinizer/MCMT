include "lib2/rm_core.xs";

void generate()
{
   rmSetProgress(0.0);

   // Define mixes.
   int baseMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.2, 5, 0.5);
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
   rmInitializeWater(cWaterHadesRiver);
   
   // Player placement.
   // TODO Better way of computing team spacing modifier.
   rmSetTeamSpacingModifier(0.35 + 0.025 * cNumberPlayers);
   rmPlacePlayersOnSquare(0.44, 0.425, 0.0, rmXFractionToMeters(0.025));

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCiv(cCivHades);

   // Lighting.
   rmSetLighting(cLightingSetRmRiverStyx01);

   rmSetProgress(0.1);

   // Terrain classes and constraints.
   int continentClassID = rmClassCreate();
   int teamContinentClassID = rmClassCreate();
   int continentAvoidContinent = rmCreateClassDistanceConstraint(continentClassID, 30.0);

   // Team continents.
   float teamAreaPerPlayer = 0.3 / cNumberPlayers;

   for(int i = 1; i <= cNumberTeams; i++)
   {
      int teamContinentID = rmAreaCreate("team continent " + i);
      rmAreaSetSize(teamContinentID, (teamAreaPerPlayer * rmGetNumberPlayersOnTeam(i)));
      rmAreaSetMix(teamContinentID, baseMixID);
      rmAreaSetLocTeam(teamContinentID, i);

	  rmAreaSetHeight(teamContinentID, 1.0);
	  rmAreaAddHeightBlend(teamContinentID, cBlendAll, cFilter5x5Gaussian, 10, 5);
     rmAreaSetBlobs(teamContinentID, 1, 5);
     rmAreaSetBlobDistance(teamContinentID, 20.0, 40.0);
      
	  rmAreaAddConstraint(teamContinentID, continentAvoidContinent);
	  rmAreaAddToClass(teamContinentID, teamContinentClassID);
     rmAreaAddToClass(teamContinentID, continentClassID);
   }

   // Center continent.
   int centerContinentID = rmAreaCreate("continent");
   rmAreaSetSize(centerContinentID, 0.325);
   rmAreaSetLoc(centerContinentID, cCenterLoc);
   rmAreaSetMix(centerContinentID, baseMixID);
   
   rmAreaSetCoherence(centerContinentID, 0.0);
   rmAreaSetHeight(centerContinentID, 1.0);
	rmAreaAddHeightBlend(centerContinentID, cBlendAll, cFilter5x5Gaussian, 10, 5);
   rmAreaSetBlobs(centerContinentID, 1, 5);
   rmAreaSetBlobDistance(centerContinentID, smallerFractionToMeters(0.2));
   
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

   // Starting towers.
   int startingTowerID = rmObjectDefCreate("starting tower");
   rmObjectDefAddItem(startingTowerID, cUnitTypeSentryTower, 1);
   rmObjectDefAddConstraint(startingTowerID, vDefaultAvoidAll);
   rmObjectDefAddConstraint(startingTowerID, vDefaultAvoidWater4);
   addObjectLocsPerPlayer(startingTowerID, true, 4, cStartingTowerMinDist, cStartingTowerMaxDist, cStartingTowerAvoidanceMeters);
   generateLocs("starting tower locs");

   // First settlement.
   int firstSettlementID = rmObjectDefCreate("first settlement");
   rmObjectDefAddItem(firstSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidWater);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(firstSettlementID, avoidCenterContinent);
   addObjectLocsPerPlayer(firstSettlementID, false, 1, 35.0, 80.0, cCloseSettlementDist, cBiasNone, cInAreaTeam);
   
   // Second settlement.
   int secondSettlementID = rmObjectDefCreate("second settlement");
   rmObjectDefAddItem(secondSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidSiegeShipRange);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(secondSettlementID, avoidTeamContinent);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidKotH);
   addObjectLocsPerPlayer(secondSettlementID, false, 1, 60.0, -1.0, cFarSettlementDist, cBiasNone, inAreaType);

   // Other map sizes settlements.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int bonusSettlementID = rmObjectDefCreate("bonus settlement");
      rmObjectDefAddItem(bonusSettlementID, cUnitTypeSettlement, 1);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidEdge);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidSiegeShipRange);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(bonusSettlementID, avoidTeamContinent);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidKotH);
      addObjectLocsPerPlayer(bonusSettlementID, false, 1 * getMapAreaSizeFactor(), 90.0, -1.0, 90.0, cBiasNone, inAreaType);
   }

   generateLocs("settlement locs");

   rmSetProgress(0.3);

   // Center cliffs.
   int numCliffs = 3 * cNumberPlayers * getMapAreaSizeFactor();

   int cliffClassID = rmClassCreate();
   int cliffAvoidCliff = rmCreateClassDistanceConstraint(cliffClassID, 35.0);
   int cliffAvoidBuildings = rmCreateTypeDistanceConstraint(cUnitTypeBuilding, 22.5);

   float cliffMinSize = rmTilesToAreaFraction(200);
   float cliffMaxSize = rmTilesToAreaFraction(300);

   for(int i = 0; i < numCliffs; i++)
   {
      int cliffID = rmAreaCreate("cliff " + i);

      rmAreaSetSize(cliffID, xsRandFloat(cliffMinSize, cliffMaxSize));
      rmAreaSetTerrainType(cliffID, cTerrainHadesCliff1);
      rmAreaSetCliffType(cliffID, cCliffHadesDirt);
      rmAreaSetCliffSideRadius(cliffID, 0, 2);
      rmAreaSetCliffPaintInsideAsSide(cliffID, true);
      rmAreaSetCliffEmbellishmentDensity(cliffID, 0.25);
   
      rmAreaSetEdgeSmoothDistance(cliffID, 2);
      rmAreaSetCoherence(cliffID, 0.25);
      rmAreaSetBlobs(cliffID, 1, 5);
      rmAreaSetBlobDistance(cliffID, 5.0, 15.0);
      
      rmAreaSetHeightRelative(cliffID, 6.0);
      rmAreaSetHeightNoise(cliffID, cNoiseFractalSum, 10.0, 0.1, 5, 0.5);
      rmAreaSetHeightNoiseBias(cliffID, 1.0);

      rmAreaAddHeightBlend(cliffID, cBlendEdge, cFilter5x5Gaussian, 2);

      // Randomize on water or on land.
      if (xsRandBool(0.5) == true)
      {
         rmAreaAddConstraint(cliffID, rmCreatePassabilityDistanceConstraint(cPassabilityLand, true, 12.0));
      }
      else
      {
         rmAreaAddConstraint(cliffID, rmCreatePassabilityMaxDistanceConstraint(cPassabilityLand, true, 8.0));
      }

      rmAreaAddConstraint(cliffID, cliffAvoidCliff);
      rmAreaAddConstraint(cliffID, cliffAvoidBuildings);
      rmAreaAddConstraint(cliffID, avoidTeamContinent);
      rmAreaSetConstraintBuffer(cliffID, 0.0, 8.0);
      rmAreaAddToClass(cliffID, cliffClassID);

      rmAreaBuild(cliffID);
   }

   rmSetProgress(0.4);

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
      rmObjectDefAddItem(startingHuntID, cUnitTypeBoar, xsRandInt(3, 5));
   }
   else
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeAurochs, xsRandInt(3, 4));
   }
   rmObjectDefAddConstraint(startingHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(startingHuntID, vDefaultForceInTowerLOS);
   addObjectLocsPerPlayer(startingHuntID, false, 1, cStartingHuntMinDist, cStartingHuntMaxDist, cStartingObjectAvoidanceMeters);
   
   // Chicken.
   int startingChickenID = rmObjectDefCreate("starting chicken");
   rmObjectDefAddItem(startingChickenID, cUnitTypeChicken, xsRandInt(5, 9));
   rmObjectDefAddConstraint(startingChickenID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidWater);
   addObjectLocsPerPlayer(startingChickenID, false, 1, cStartingChickenMinDist, cStartingChickenMaxDist, cStartingObjectAvoidanceMeters);

   // Herdables.
   int startingHerdID = rmObjectDefCreate("starting herd");
   rmObjectDefAddItem(startingHerdID, cUnitTypeGoat, xsRandInt(2, 4));
   rmObjectDefAddConstraint(startingHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidWater);
   addObjectLocsPerPlayer(startingHerdID, true, 1, cStartingHerdMinDist, cStartingHerdMaxDist);

   generateLocs("starting food locs");

   rmSetProgress(0.5);

   // Gold.
   float avoidGoldMeters = 40.0;

   // Close gold.
   int closeGoldID = rmObjectDefCreate("close gold");
   rmObjectDefAddItem(closeGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidWater);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(closeGoldID, avoidCenterContinent);
   addObjectLocsPerPlayer(closeGoldID, false, 1, 40.0, 80.0, avoidGoldMeters, cBiasForward, cInAreaTeam);

   generateLocs("player gold locs");

   // Bonus gold.
   int bonusGoldID = rmObjectDefCreate("bonus gold");
   rmObjectDefAddItem(bonusGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidImpassableLand16);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(bonusGoldID, forceInCenterContinent);
   addObjectDefPlayerLocConstraint(bonusGoldID, 60.0);
   addObjectLocsPerPlayer(bonusGoldID, false, xsRandInt(2, 3) * getMapAreaSizeFactor(), 60.0, -1.0, avoidGoldMeters, cBiasForward, inAreaType);

   generateLocs("center gold locs");

   // Hunt.
   float avoidHuntMeters = 30.0;
   
   // Close hunt 1.
   int closeHuntID = rmObjectDefCreate("close hunt");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeBoar, xsRandInt(1, 3));
   }
   else
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeAurochs, xsRandInt(1, 3));
   }
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(closeHuntID, avoidCenterContinent);
   addObjectLocsPerPlayer(closeHuntID, false, 1, 40.0, 80.0, avoidHuntMeters, cBiasForward, cInAreaTeam);

   // Bonus hunt.
   int numBonusHunt = 2;
   for(int i = 0; i < numBonusHunt; i++)
   {
      int bonusHuntID = rmObjectDefCreate("bonus hunt " + i);
      if(xsRandBool(0.5) == true)
      {
         rmObjectDefAddItem(bonusHuntID, cUnitTypeAurochs, xsRandInt(2, 4));
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
      addObjectDefPlayerLocConstraint(bonusHuntID, 60.0);
      addObjectLocsPerPlayer(bonusHuntID, false, 1, 60.0, -1.0, avoidHuntMeters, cBiasForward, inAreaType);
   }

   // Other map sizes hunt.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int numLargeMapHunt = 1 * getMapSizeBonusFactor();
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
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeBoar, xsRandInt(2, 5));
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeAurochs, xsRandInt(1, 3));
         }

         rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidEdge);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidAll);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidWater);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidImpassableLand);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidTowerLOS);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidSettlementRange);
         rmObjectDefAddConstraint(largeMapHuntID, forceInCenterContinent);
         addObjectDefPlayerLocConstraint(largeMapHuntID, 100.0);
         addObjectLocsPerPlayer(largeMapHuntID, false, 1, 100.0, -1.0, avoidHuntMeters, cBiasForward, inAreaType);
      }
   }

   generateLocs("hunt locs");

   rmSetProgress(0.6);

   // Herdables.
   float avoidHerdMeters = 50.0;
  
   int closeHerdID = rmObjectDefCreate("close herd");
   rmObjectDefAddItem(closeHerdID, cUnitTypeGoat, xsRandInt(1, 2));
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidWater);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHerdID, avoidCenterContinent);
   addObjectLocsPerPlayer(closeHerdID, false, 1, 40.0, 80.0, avoidHerdMeters, cBiasNone, cInAreaTeam);

   int bonusHerdID = rmObjectDefCreate("bonus herd");
   rmObjectDefAddItem(bonusHerdID, cUnitTypeGoat, xsRandInt(1, 3));
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidWater);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHerdID, forceInCenterContinent);
   addObjectDefPlayerLocConstraint(bonusHerdID, 60.0);
   addObjectLocsPerPlayer(bonusHerdID, false, xsRandInt(1, 2) * getMapAreaSizeFactor(), 60.0, -1.0, avoidHerdMeters, cBiasForward, inAreaType);

   generateLocs("herd locs");

   // Predators.
   float avoidPredatorMeters = 50.0;
  
   int predator1ID = rmObjectDefCreate("predator 1");
   rmObjectDefAddItem(predator1ID, cUnitTypeSerpentPredator, xsRandInt(2, 3));
   rmObjectDefAddConstraint(predator1ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(predator1ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(predator1ID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(predator1ID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(predator1ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(predator1ID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(predator1ID, forceInCenterContinent);
   addObjectDefPlayerLocConstraint(predator1ID, 80.0);
   addObjectLocsPerPlayer(predator1ID, false, 1 * getMapAreaSizeFactor(), 80.0, -1.0, avoidPredatorMeters, cBiasForward, inAreaType);

   int predator2ID = rmObjectDefCreate("predator 2");
   rmObjectDefAddItem(predator2ID, cUnitTypeShadePredator, xsRandInt(2, 3));
   rmObjectDefAddConstraint(predator2ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(predator2ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(predator2ID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(predator2ID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(predator2ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(predator2ID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(predator2ID, forceInCenterContinent);
   addObjectDefPlayerLocConstraint(predator2ID, 80.0);
   addObjectLocsPerPlayer(predator2ID, false, 1 * getMapAreaSizeFactor(), 80.0, -1.0, avoidPredatorMeters, cBiasForward, inAreaType);

   generateLocs("predator locs");

   // Relics.
   float avoidRelicMeters = 80.0;
  
   int relicID = rmObjectDefCreate("relic");
   rmObjectDefAddItem(relicID, cUnitTypeRelic, 1);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidAll);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidWater);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidImpassableLand);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(relicID, forceInCenterContinent);
   addObjectDefPlayerLocConstraint(relicID, 80.0);
   addObjectLocsPerPlayer(relicID, false, 2 * getMapAreaSizeFactor(), 80.0, -1.0, avoidRelicMeters, cBiasForward, inAreaType);

   generateLocs("relic locs");

   rmSetProgress(0.7);

   // Forests.
   float avoidForestMeters = 30.0;

   int forestDefID = rmAreaDefCreate("forest");
   rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(80), rmTilesToAreaFraction(120));
   rmAreaDefSetForestType(forestDefID, cForestHades);
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
   buildAreaDefInTeamAreas(forestDefID, 10 * getMapAreaSizeFactor());

   // Stragglers.
   placeStartingStragglers(cUnitTypeTreeHades);

   rmSetProgress(0.8);

   // Embellishment.
   buildAreaUnderObjectDef(startingGoldID, cTerrainHadesDirtRocks2, cTerrainHadesDirtRocks1, 6.0);
   buildAreaUnderObjectDef(closeGoldID, cTerrainHadesDirtRocks2, cTerrainHadesDirtRocks1, 6.0);
   buildAreaUnderObjectDef(bonusGoldID, cTerrainHadesDirtRocks2, cTerrainHadesDirtRocks1, 6.0);

   rmSetProgress(0.9);

   // Random trees.
   int randomTreeID = rmObjectDefCreate("random tree");
   rmObjectDefAddItem(randomTreeID, cUnitTypeTreeHades, 1);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidImpassableLand);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidTree);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefPlaceAnywhere(randomTreeID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   int stalagmiteAvoidAll = rmCreateTypeDistanceConstraint(cUnitTypeAll, 10.0);
   int stalagmiteAvoidBuilding = rmCreateTypeDistanceConstraint(cUnitTypeBuilding, 15.0);

   int stalagmiteID = rmObjectDefCreate("stalagmite");
   rmObjectDefAddItem(stalagmiteID, cUnitTypeStalagmite, 1);
   rmObjectDefAddConstraint(stalagmiteID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(stalagmiteID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(stalagmiteID, stalagmiteAvoidAll);
   rmObjectDefAddConstraint(stalagmiteID, stalagmiteAvoidBuilding);
   rmObjectDefPlaceAnywhere(stalagmiteID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   int bushID = rmObjectDefCreate("bush");
   rmObjectDefAddItem(bushID, cUnitTypePlantHadesBush, 1);
   rmObjectDefAddConstraint(bushID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(bushID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefPlaceAnywhere(bushID, 0, 50 * cNumberPlayers * getMapAreaSizeFactor());

   int shrubID = rmObjectDefCreate("shrub");
   rmObjectDefAddItem(shrubID, cUnitTypePlantHadesShrub, 1);
   rmObjectDefAddConstraint(shrubID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(shrubID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefPlaceAnywhere(shrubID, 0, 50 * cNumberPlayers * getMapAreaSizeFactor());

   int fernID = rmObjectDefCreate("fern");
   rmObjectDefAddItem(fernID, cUnitTypePlantHadesFern, 1);
   rmObjectDefAddConstraint(fernID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(fernID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefPlaceAnywhere(fernID, 0, 30 * cNumberPlayers * getMapAreaSizeFactor());

   int weedsID = rmObjectDefCreate("weeds");
   rmObjectDefAddItem(weedsID, cUnitTypePlantHadesWeeds, 1);
   rmObjectDefAddConstraint(weedsID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(weedsID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefPlaceAnywhere(weedsID, 0, 30 * cNumberPlayers * getMapAreaSizeFactor());

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeHarpy, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   rmSetProgress(1.0);
}
