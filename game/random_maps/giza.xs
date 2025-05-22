include "lib2/rm_core.xs";

void generate()
{
   rmSetProgress(0.0);

   // Define mixes.
   int baseMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.20, 1);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptSand2, 4.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptSand1, 3.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptDirt2, 1.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptDirtRocks2, 1.0);

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
   rmPlacePlayersOnCircle(xsRandFloat(0.36, 0.38));

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCivFromCulture(cCultureEgyptian);

   // KotH.
   placeKotHObjects();

   // Lighting.
   rmSetLighting(cLightingSetRmGiza01);

   rmSetProgress(0.1);

   // Global elevation.
   rmAddGlobalHeightNoise(cNoiseFractalSum, 7.0, 0.05, 5, 0.3);
   
   // Player areas.
   int oasisClassID = rmClassCreate();
   
   int stayInOasis = rmCreateClassMaxDistanceConstraint(oasisClassID, 0.0);

   int avoidOasis = rmCreateClassDistanceConstraint(oasisClassID, 0.1);
   int avoidOasisEdge4 = rmCreateClassDistanceConstraint(oasisClassID, 4.0, cClassAreaEdgeDistance);
   int avoidOasisEdge8 = rmCreateClassDistanceConstraint(oasisClassID, 8.0, cClassAreaEdgeDistance);
   int avoidOasisEdge12 = rmCreateClassDistanceConstraint(oasisClassID, 12.0, cClassAreaEdgeDistance);
   int avoidOasisEdge16 = rmCreateClassDistanceConstraint(oasisClassID, 16.0, cClassAreaEdgeDistance);
   
   float playerAreaSize = rmRadiusToAreaFraction(47.5);
   
   for(int i = 1; i <= cNumberPlayers; i++)
   {
      int p = vDefaultTeamPlayerOrder[i];

      int playerIslandID = rmAreaCreate("player island " + p);
      rmAreaSetSize(playerIslandID, playerAreaSize);
      rmAreaSetLocPlayer(playerIslandID, p);

      rmAreaSetBlobs(playerIslandID, 1, 4);
      rmAreaSetBlobDistance(playerIslandID, 10.0, 20.0);
      rmAreaAddTerrainLayer(playerIslandID, cTerrainEgyptGrassDirt2, 0, 1);
      rmAreaAddTerrainLayer(playerIslandID, cTerrainEgyptGrassDirt1, 1, 2);
      rmAreaAddTerrainLayer(playerIslandID, cTerrainEgyptGrass1, 2, 4);
      rmAreaSetTerrainType(playerIslandID, cTerrainEgyptGrass2);

      rmAreaAddToClass(playerIslandID, oasisClassID);
   }

   rmAreaBuildAll();

   rmSetProgress(0.2);

   // Settlements and towers.
   placeStartingTownCenters();

   // Starting towers.
   int startingTowerID = rmObjectDefCreate("starting tower");
   rmObjectDefAddItem(startingTowerID, cUnitTypeSentryTower, 1);
   rmObjectDefAddConstraint(startingTowerID, stayInOasis);
   addObjectLocsPerPlayer(startingTowerID, true, 4, 22.0, 30.0, 23.0);
   
   generateLocs("starting tower locs");

   // Settlements.
   int firstSettlementID = rmObjectDefCreate("first settlement");
   rmObjectDefAddItem(firstSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidCorner40);

   int secondSettlementID = rmObjectDefCreate("second settlement");
   rmObjectDefAddItem(secondSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidKotH);

   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(firstSettlementID, false, 1, 80.0, 100.0, cSettlementDist1v1, cBiasBackward,
                                    cInAreaDefault, cLocSideOpposite);
      addSimObjectLocsPerPlayerPair(secondSettlementID, false, 1, 90.0, 120.0, cSettlementDist1v1, cBiasAggressive);
   }
   else
   {
      addObjectLocsPerPlayer(firstSettlementID, false, 1, 80.0, 100.0, cFarSettlementDist, cBiasBackward | cBiasAllyInside);
      addObjectLocsPerPlayer(secondSettlementID, false, 1, 100.0, 125.0, cFarSettlementDist, cBiasAggressive);
   }
   
   // Other map sizes settlements.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int bonusSettlementID = rmObjectDefCreate("bonus settlement");
      rmObjectDefAddItem(bonusSettlementID, cUnitTypeSettlement, 1);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidEdge);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidCorner40);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidKotH);
      addObjectLocsPerPlayer(bonusSettlementID, false, 1 * getMapAreaSizeFactor(), 90.0, -1.0, 100.0);
   }

   // Generate the locs, but don't place yet if we succeed.
   bool settlementLocsGenerated = generateLocs("settlement locs", true, false, true, false);
   
   // Settlement hunt.
   int settlementHuntID = rmObjectDefCreate("settlement hunt");
   rmObjectDefAddItem(settlementHuntID, cUnitTypeRhinoceros, xsRandInt(1, 2));
   rmObjectDefAddConstraint(settlementHuntID, vDefaultAvoidAll);
   rmObjectDefAddConstraint(settlementHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(settlementHuntID, avoidOasisEdge12);
   rmObjectDefAddConstraint(settlementHuntID, createPlayerLocDistanceConstraint(50.0));
   rmObjectDefAddConstraint(settlementHuntID, rmCreateTypeDistanceConstraint(cUnitTypeSettlement, 12.0));

   for(int i = 0; i < rmLocGenGetNumberLocs(); i++)
   {
      vector loc = rmLocGenGetLoc(i);
   
      int areaSettlementID = rmAreaCreate("settlement " + i); 
      rmAreaSetSize(areaSettlementID, 0.5 * playerAreaSize);
      rmAreaSetLoc(areaSettlementID, loc);
      
      rmAreaSetBlobs(areaSettlementID, 3, 4);
      rmAreaSetBlobDistance(areaSettlementID, 5.0, 20.0);
      rmAreaAddConstraint(areaSettlementID, avoidOasisEdge12);
      rmAreaAddConstraint(areaSettlementID, vDefaultAvoidKotH);
      
      rmAreaAddTerrainLayer(areaSettlementID, cTerrainEgyptGrassDirt2, 0, 1);
      rmAreaAddTerrainLayer(areaSettlementID, cTerrainEgyptGrassDirt1, 1, 2);
      rmAreaAddTerrainLayer(areaSettlementID, cTerrainEgyptGrass1, 2, 4);
      rmAreaSetTerrainType(areaSettlementID, cTerrainEgyptGrass2);
      
      rmAreaAddToClass(areaSettlementID, oasisClassID);
   
      rmAreaBuild(areaSettlementID);
      
      rmObjectDefPlaceInArea(settlementHuntID, 0, areaSettlementID, 1);
   }

   // Actually place stuff.
   if(settlementLocsGenerated == true)
   {
      applyGeneratedLocs();
   }

   resetLocGen();
   
   rmSetProgress(0.3);
   
   // Bonus oases.
   int bonusOasisHuntID = rmObjectDefCreate("bonus oasis hunt");
   rmObjectDefAddItem(bonusOasisHuntID, cUnitTypeGazelle, xsRandInt(5, 9));
   rmObjectDefAddConstraint(bonusOasisHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusOasisHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(bonusOasisHuntID, avoidOasisEdge8);

   int bonusOasisClassID = rmClassCreate();
   int oasisAvoidEdge = createSymmetricBoxConstraint(rmXMetersToFraction(15.0), rmZMetersToFraction(15.0));
   float bonusOasisMinSize = rmTilesToAreaFraction(400);
   float bonusOasisMaxSize = rmTilesToAreaFraction(450);
   
   for(int i = 1; i <= cNumberPlayers; i++)
   {
      int p = vDefaultTeamPlayerOrder[i];

      int teamAreaID = vTeamAreaIDs[rmGetPlayerTeam(p)];

      for(int j = 0; j < 1 * getMapSizeBonusFactor(); j++)
      {
         int bonusOasisID = rmAreaCreate("bonus oasis " + p + " " + j);
         rmAreaSetParent(bonusOasisID, teamAreaID);

         rmAreaSetSize(bonusOasisID, xsRandFloat(bonusOasisMinSize, bonusOasisMaxSize));
         
         rmAreaAddTerrainLayer(bonusOasisID, cTerrainEgyptGrassDirt2, 0, 1);
         rmAreaAddTerrainLayer(bonusOasisID, cTerrainEgyptGrassDirt1, 1, 2);
         rmAreaAddTerrainLayer(bonusOasisID, cTerrainEgyptGrass1, 2, 4);
         rmAreaSetTerrainType(bonusOasisID, cTerrainEgyptGrass2);
         
         rmAreaAddToClass(bonusOasisID, oasisClassID);
         rmAreaAddToClass(bonusOasisID, bonusOasisClassID);
         rmAreaSetBlobs(bonusOasisID, 0, 2);
         rmAreaSetBlobDistance(bonusOasisID, 2.0, 15.0);
         rmAreaSetCoherence(bonusOasisID, 0.5);

         rmAreaAddOriginConstraint(bonusOasisID, oasisAvoidEdge);
         rmAreaAddConstraint(bonusOasisID, avoidOasis);
         rmAreaAddConstraint(bonusOasisID, avoidOasisEdge16);
         rmAreaAddConstraint(bonusOasisID, vDefaultAvoidKotH);

         rmAreaBuild(bonusOasisID);
      
         rmObjectDefPlaceInArea(bonusOasisHuntID, 0, bonusOasisID, 1);
      }
   }

   rmSetProgress(0.4);

   // Cliffs.
   int cliffClassID = rmClassCreate();
   int numCliffsPerPlayer = 0;
   int cliffSize = xsRandInt(1, 2);
   if (cliffSize == 1)
   {
       numCliffsPerPlayer = 2 * getMapSizeBonusFactor();
   }
   else
   {
       numCliffsPerPlayer = 1 * getMapSizeBonusFactor();
   }

   float cliffMinSize = rmTilesToAreaFraction(100 * cliffSize);
   float cliffMaxSize = rmTilesToAreaFraction(150 * cliffSize);

   int cliffAvoidCliff = rmCreateClassDistanceConstraint(cliffClassID, 30.0);
   int cliffAvoidBuildings = rmCreateTypeDistanceConstraint(cUnitTypeBuilding, 20.0);

   for(int i = 1; i <= cNumberPlayers; i++)
   {
      int p = vDefaultTeamPlayerOrder[i];

      int teamAreaID = vTeamAreaIDs[rmGetPlayerTeam(p)];

      for(int j = 0; j < numCliffsPerPlayer; j++)
      {
         int cliffID = rmAreaCreate("cliff " + p + " " + j);
         rmAreaSetParent(cliffID, teamAreaID);

         rmAreaSetSize(cliffID, xsRandFloat(cliffMinSize, cliffMaxSize));
         rmAreaSetTerrainType(cliffID, cTerrainEgyptCliff1);
         rmAreaSetCliffType(cliffID, cCliffEgyptSand);
         rmAreaSetCliffSideRadius(cliffID, 0, 2);
         rmAreaSetCliffPaintInsideAsSide(cliffID, true);
         rmAreaSetCliffEmbellishmentDensity(cliffID, 0.25);
         
         rmAreaSetHeightRelative(cliffID, 9.0);
         rmAreaSetHeightNoise(cliffID, cNoiseFractalSum, 10.0, 0.2, 2, 0.5);

         rmAreaSetCoherence(cliffID, 0.25);
         rmAreaAddHeightBlend(cliffID, cBlendEdge, cFilter5x5Gaussian, 2);
         rmAreaSetEdgeSmoothDistance(cliffID, 5);

         rmAreaAddConstraint(cliffID, cliffAvoidCliff);
         rmAreaAddConstraint(cliffID, cliffAvoidBuildings);
         rmAreaAddConstraint(cliffID, vDefaultAvoidTowerLOS);
         rmAreaAddConstraint(cliffID, avoidOasis);
         rmAreaAddConstraint(cliffID, avoidOasisEdge12);
         rmAreaAddToClass(cliffID, cliffClassID);

         rmAreaSetConstraintBuffer(cliffID, 5.0);

         rmAreaBuild(cliffID);
      }
   }

   rmSetProgress(0.5);

   // Starting objects.
   // Starting gold.
   int startingGoldID = rmObjectDefCreate("starting gold");
   rmObjectDefAddItem(startingGoldID, cUnitTypeMineGoldMedium, 1);
   rmObjectDefAddConstraint(startingGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(startingGoldID, vDefaultStartingGoldAvoidTower);
   rmObjectDefAddConstraint(startingGoldID, vDefaultForceStartingGoldNearTower);
   rmObjectDefAddConstraint(startingGoldID, stayInOasis);
   rmObjectDefAddConstraint(startingGoldID, avoidOasisEdge4);
   addObjectLocsPerPlayer(startingGoldID, false, 1, 21, 25, cStartingObjectAvoidanceMeters);

   generateLocs("starting gold locs");

   // Berries.
   int startingBerriesID = rmObjectDefCreate("starting berries");
   rmObjectDefAddItem(startingBerriesID, cUnitTypeBerryBush, xsRandInt(6, 9), cBerryClusterRadius);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidImpassableLand);
   rmObjectDefAddConstraint(startingBerriesID, stayInOasis);
   rmObjectDefAddConstraint(startingBerriesID, avoidOasisEdge4);
   addObjectLocsPerPlayer(startingBerriesID, false, 1, cStartingBerriesMinDist, cStartingBerriesMaxDist, cStartingObjectAvoidanceMeters);

   // Starting hunt.
   float startingHuntFloat = xsRandFloat(0.0, 1.0);
   int startingHuntID = rmObjectDefCreate("starting hunt");
   if(startingHuntFloat < 1.0 / 3.0)
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeGazelle, xsRandInt(8, 9));
   }
   else if(startingHuntFloat < 2.0 / 3.0)
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeZebra, xsRandInt(6, 8));
   }
   else
   {
       rmObjectDefAddItem(startingHuntID, cUnitTypeHippopotamus, xsRandInt(3, 4));
   }
   rmObjectDefAddConstraint(startingHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(startingHuntID, stayInOasis);
   rmObjectDefAddConstraint(startingHuntID, avoidOasisEdge4);
   addObjectLocsPerPlayer(startingHuntID, false, 1, cStartingHuntMinDist, cStartingHuntMaxDist, cStartingObjectAvoidanceMeters);

   // Chicken.
   int startingChickenID = rmObjectDefCreate("starting chicken");
   rmObjectDefAddItem(startingChickenID, cUnitTypeChicken, xsRandInt(5, 7));
   rmObjectDefAddConstraint(startingChickenID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(startingChickenID, stayInOasis);
   rmObjectDefAddConstraint(startingChickenID, avoidOasisEdge4);
   addObjectLocsPerPlayer(startingChickenID, false, 1, cStartingChickenMinDist, cStartingChickenMaxDist, cStartingObjectAvoidanceMeters);

   // // Herdables.
   // int startingHerdID = rmObjectDefCreate("starting herd");
   // rmObjectDefAddItem(startingHerdID, cUnitTypeGoat, xsRandInt(2, 5));
   // rmObjectDefAddConstraint(startingHerdID, vDefaultAvoidEdge);
   // rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidAll);
   // rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidImpassableLand);
   // addObjectLocsPerPlayer(startingHerdID, true, 1, cStartingHerdMinDist, cStartingHerdMaxDist);

   generateLocs("starting food locs");

   rmSetProgress(0.6);

   // Gold.
   float avoidGoldMeters = 50.0;

   int closeGoldID = rmObjectDefCreate("close gold");
   rmObjectDefAddItem(closeGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(closeGoldID, avoidOasis);
   rmObjectDefAddConstraint(closeGoldID, avoidOasisEdge12);
   addObjectDefPlayerLocConstraint(closeGoldID, 55.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeGoldID, false, 1, 50.0, 70.0, avoidGoldMeters);
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
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(bonusGoldID, avoidOasis);
   rmObjectDefAddConstraint(bonusGoldID, avoidOasisEdge8);
   addObjectDefPlayerLocConstraint(bonusGoldID, 70.0);
   if(gameIs1v1()== true)
   {
      addSimObjectLocsPerPlayerPair(bonusGoldID, false, xsRandInt(2, 3) * getMapAreaSizeFactor(), 70.0, -1.0, avoidGoldMeters);
   }
   else
   {
      addObjectLocsPerPlayer(bonusGoldID, false, xsRandInt(2, 3) * getMapAreaSizeFactor(), 70.0, -1.0, avoidGoldMeters);
   }

   generateLocs("gold locs");

   // Hunt.
   float avoidHuntMeters = 50.0;

   // Close hunt.
   int closeHuntID = rmObjectDefCreate("close hunt");
   rmObjectDefAddItem(closeHuntID, cUnitTypeZebra, xsRandInt(5, 8));
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(closeHuntID, avoidOasis);
   rmObjectDefAddConstraint(closeHuntID, avoidOasisEdge8);
   addObjectDefPlayerLocConstraint(closeHuntID, 55.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeHuntID, false, 1, 55.0, 80.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(closeHuntID, false, 1, 55.0, 80.0, avoidHuntMeters);
   }

   generateLocs("close hunt locs");

   // Other map sizes hunt.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int largeMapHuntID = rmObjectDefCreate("large map hunt");
      if(xsRandBool(0.5) == true)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeZebra, xsRandInt(6, 11));
      }
      else
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeElephant, xsRandInt(1, 3));
      }
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidImpassableLand);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidSettlementRange);
      rmObjectDefAddConstraint(largeMapHuntID, avoidOasis);
      rmObjectDefAddConstraint(largeMapHuntID, avoidOasisEdge8);
      addObjectDefPlayerLocConstraint(largeMapHuntID, 100.0);
      addObjectLocsPerPlayer(largeMapHuntID, false, 1 * getMapAreaSizeFactor(), 100.0, -1.0, avoidHuntMeters);
   
      generateLocs("large map hunt locs");
   }

   rmSetProgress(0.7);

   // No additional berries on this map.

   // Herdables.
   float avoidHerdMeters = 50.0;

   int closeHerdID = rmObjectDefCreate("close herd");
   rmObjectDefAddItem(closeHerdID, cUnitTypeGoat, 2);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHerdID, stayInOasis);
   addObjectLocsPerPlayer(closeHerdID, false, xsRandInt(2, 4), 50.0, 80.0, avoidHerdMeters);

   int bonusHerdID = rmObjectDefCreate("bonus herd");
   rmObjectDefAddItem(bonusHerdID, cUnitTypeGoat, xsRandInt(2, 3));
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHerdID, stayInOasis);
   addObjectLocsPerPlayer(bonusHerdID, false, xsRandInt(1, 2) * getMapSizeBonusFactor(), 70.0, -1.0, avoidHerdMeters);

   generateLocs("herd locs");

   // Predators.
   int predatorID = rmObjectDefCreate("predator");
   rmObjectDefAddItem(predatorID, cUnitTypeHyena, xsRandInt(2, 3));
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(predatorID, avoidOasis);
   rmObjectDefAddConstraint(predatorID, avoidOasisEdge12);
   addObjectDefPlayerLocConstraint(predatorID, 70.0);
   addObjectLocsPerPlayer(predatorID, false, xsRandInt(1, 3) * getMapAreaSizeFactor(), 70.0, -1.0, 50.0);

   generateLocs("predator locs");

   // Relics.
   int relicID = rmObjectDefCreate("relic");
   rmObjectDefAddItem(relicID, cUnitTypeRelic, 1);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidAll);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidImpassableLand);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(relicID, avoidOasisEdge8);
   rmObjectDefAddConstraint(relicID, avoidOasis);
   addObjectDefPlayerLocConstraint(relicID, 70.0);
   addObjectLocsPerPlayer(relicID, false, 2 * getMapAreaSizeFactor(), 70.0, -1.0, 70.0);

   generateLocs("relic locs");

   rmSetProgress(0.8);

   // Forests.
   float avoidForestMeters = 22.0;

   int forestDefID = rmAreaDefCreate("forest");
   rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(50), rmTilesToAreaFraction(70));
   rmAreaDefSetForestType(forestDefID, cForestEgyptPalmGrass);
   rmAreaDefSetAvoidSelfDistance(forestDefID, avoidForestMeters);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidImpassableLand4);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddConstraint(forestDefID, stayInOasis);

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
   buildAreaDefInTeamAreas(forestDefID, 8 * getMapAreaSizeFactor());

   // Stragglers.
   placeStartingStragglers(cUnitTypeTreePalm);

   rmSetProgress(0.9);

   // Embellishment.
   int pyramidsID = rmObjectDefCreate("pyramids");
   rmObjectDefAddItem(pyramidsID, cUnitTypePyramid, 1);
   rmObjectDefAddConstraint(pyramidsID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(pyramidsID, vDefaultAvoidAll8);
   rmObjectDefAddConstraint(pyramidsID, vDefaultAvoidImpassableLand8);
   rmObjectDefAddConstraint(pyramidsID, avoidOasisEdge16);
   rmObjectDefAddConstraint(pyramidsID, avoidOasis);
   rmObjectDefAddConstraint(pyramidsID, rmCreateTypeDistanceConstraint(cUnitTypeGoldResource, 10.0));
   rmObjectDefAddConstraint(pyramidsID, rmCreateTypeDistanceConstraint(cUnitTypePyramid, 40.0));
   rmObjectDefPlaceAnywhere(pyramidsID, 0, cNumberPlayers * getMapAreaSizeFactor());

   // Roads.
   int roadAreaDef = rmAreaDefCreate();
   rmAreaDefSetTerrainType(roadAreaDef, cTerrainEgyptRoad1);
   rmAreaDefAddConstraint(roadAreaDef, avoidOasisEdge4);
   rmAreaDefAddConstraint(roadAreaDef, rmCreatePassabilityDistanceConstraint(cPassabilityLand, false, 4.0));

   int numPyramids = rmObjectDefGetNumberCreatedObjects(pyramidsID);
   int roadAvoidGold = rmCreateTypeDistanceConstraint(cUnitTypeGoldResource, 6.0);

   // Create n - 1 connections.
   for(int i = 0; i < numPyramids - 1; i++)
   {
      int object1ID = rmObjectDefGetCreatedObject(pyramidsID, i);
      vector object1Loc = rmObjectGetLoc(object1ID);

      int object2ID = rmObjectDefGetCreatedObject(pyramidsID, i + 1);
      vector object2Loc = rmObjectGetLoc(object2ID);

      if(object1Loc == cInvalidVector || object2Loc == cInvalidVector)
      {
         continue;
      }

      int pathID = rmPathCreate();
      rmPathAddWaypoint(pathID, object1Loc);
      rmPathAddWaypoint(pathID, object2Loc);
      rmPathSetCostNoise(pathID, 0.0, 10.0);
      rmPathSetAllTerrainCosts(pathID, 1000.0);
      rmPathSetTerrainCost(pathID, cTerrainEgyptRoad1, 0.0);
      rmPathAddConstraint(pathID, roadAvoidGold);
      rmPathAddConstraint(pathID, avoidOasisEdge8);
      rmPathAddConstraint(pathID, rmCreatePassabilityDistanceConstraint(cPassabilityLand, false, 4.0));

      if(rmPathBuild(pathID) == true)
      {
         int areaID = rmAreaDefCreateArea(roadAreaDef);
         rmAreaSetPath(areaID, pathID, 0.5);
         // rmAreaAddTerrainLayer(areaID, cTerrainEgyptDirtRocks2, 0);
         rmAreaBuild(areaID);
      }
   }
   
   // Gold areas.
   buildAreaUnderObjectDef(startingGoldID, cTerrainEgyptGrassRocks2, cTerrainEgyptGrassDirt1, 4.0);
   buildAreaUnderObjectDef(closeGoldID, cTerrainEgyptDirtRocks2, cTerrainEgyptDirtRocks1, 7.0);
   buildAreaUnderObjectDef(bonusGoldID, cTerrainEgyptDirtRocks2, cTerrainEgyptDirtRocks1, 7.0);

   // Random trees.
   int randomTreeID = rmObjectDefCreate("random tree");
   rmObjectDefAddItem(randomTreeID, cUnitTypeTreePalm, 1);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidImpassableLand);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidTree);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefAddConstraint(randomTreeID, stayInOasis);
   rmObjectDefAddConstraint(randomTreeID, avoidOasisEdge4);
   rmObjectDefPlaceAnywhere(randomTreeID, 0, 3 * cNumberPlayers * getMapAreaSizeFactor());

   // Rocks.
   int rockTinyID = rmObjectDefCreate("rock tiny");
   rmObjectDefAddItem(rockTinyID, cUnitTypeRockEgyptTiny, 1);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(rockTinyID, avoidOasis);
   rmObjectDefPlaceAnywhere(rockTinyID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());

   int rockSmallID = rmObjectDefCreate("rock small");
   rmObjectDefAddItem(rockSmallID, cUnitTypeRockEgyptSmall, 1);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(rockSmallID, avoidOasis);
   rmObjectDefPlaceAnywhere(rockSmallID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());
   
   // Plants.
   int plantEgyptGrassID = rmObjectDefCreate("egypt grass");
   rmObjectDefAddItem(plantEgyptGrassID, cUnitTypePlantEgyptianGrass, 1);
   rmObjectDefAddConstraint(plantEgyptGrassID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantEgyptGrassID, stayInOasis);
   rmObjectDefAddConstraint(plantEgyptGrassID, avoidOasisEdge4);
   rmObjectDefPlaceAnywhere(plantEgyptGrassID, 0, 15 * cNumberPlayers * getMapAreaSizeFactor());

   int plantDeadShrubID = rmObjectDefCreate("dead shrub");
   rmObjectDefAddItem(plantDeadShrubID, cUnitTypePlantDeadShrub, 1);
   rmObjectDefAddConstraint(plantDeadShrubID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantDeadShrubID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(plantDeadShrubID, avoidOasis);
   rmObjectDefAddConstraint(plantDeadShrubID, avoidOasisEdge4);
   rmObjectDefPlaceAnywhere(plantDeadShrubID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());

   int plantDeadBushID = rmObjectDefCreate("dead bush");
   rmObjectDefAddItem(plantDeadBushID, cUnitTypePlantDeadBush, 1);
   rmObjectDefAddConstraint(plantDeadBushID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantDeadBushID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefAddConstraint(plantDeadBushID, avoidOasis);
   rmObjectDefAddConstraint(plantDeadBushID, avoidOasisEdge4);
   rmObjectDefPlaceAnywhere(plantDeadBushID, 0, 15 * cNumberPlayers * getMapAreaSizeFactor());
   
   int flowersID = rmObjectDefCreate("flowers");
   rmObjectDefAddItem(flowersID, cUnitTypeFlowers, 1);
   rmObjectDefAddConstraint(flowersID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(flowersID, stayInOasis);
   rmObjectDefAddConstraint(flowersID, avoidOasisEdge12);
   rmObjectDefPlaceAnywhere(flowersID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());
   
   // Sand VFX.
   int sandDriftPlainID = rmObjectDefCreate("sand drift plain");
   rmObjectDefAddItem(sandDriftPlainID, cUnitTypeVFXSandDriftPlain, 1);
   rmObjectDefAddConstraint(sandDriftPlainID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(sandDriftPlainID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(sandDriftPlainID, avoidOasis);
   rmObjectDefPlaceAnywhere(sandDriftPlainID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeVulture, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   rmSetProgress(1.0);
}
