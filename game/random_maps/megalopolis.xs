include "lib2/rm_core.xs";
include "lib2/rm_connections.xs";

void generate()
{
   rmSetProgress(0.0);

   // Define mixes.
   int baseMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.15, 2, 0.5);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptSand3, 1.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptSand2, 1.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptDirt1, 1.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptDirt2, 1.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptDirt3, 1.0);

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
   rmSetTeamSpacingModifier(0.15 + 0.03 * cNumberPlayers);
   rmPlacePlayersOnSquare(0.28, 0.28);

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCivFromCulture(cCultureEgyptian);

   // Lighting.
   rmSetLighting(cLightingSetRmMegalopolis01);

   // KotH.
   placeKotHObjects();

   rmSetProgress(0.1);

   // Global elevation.
   rmAddGlobalHeightNoise(cNoiseFractalSum, 10.0, 0.025, 3, 0.5);

   rmSetProgress(0.2);

   float playerAreaRadiusMeters = 12.0;
   float playerAreaSize = rmRadiusToAreaFraction(playerAreaRadiusMeters);
   
   for(int i = 1; i <= cNumberPlayers; i++)
   {
      int p = vDefaultTeamPlayerOrder[i];

      int playerAreaID = rmAreaCreate("player area " + p);
      rmAreaSetSize(playerAreaID, playerAreaSize);
      rmAreaSetLocPlayer(playerAreaID, p);

      rmAreaSetTerrainType(playerAreaID, cTerrainEgyptRoad1);
   }

   rmAreaBuildAll();

   // Settlements and towers.
   placeStartingTownCenters();

   // Starting towers.
   int startingTowerID = rmObjectDefCreate("starting tower");
   rmObjectDefAddItem(startingTowerID, cUnitTypeSentryTower, 1);
   addObjectLocsPerPlayer(startingTowerID, true, 4, cStartingTowerMinDist, cStartingTowerMaxDist, cStartingTowerAvoidanceMeters);
   generateLocs("starting tower locs");

   int centerSettlementID = cInvalidID;
   if (gameIsKotH() == false)
   {
      // Bonus settlement in the center of the map.
      centerSettlementID = rmObjectDefCreate("bonus settlement");
      rmObjectDefAddItem(centerSettlementID, cUnitTypeSettlement, 1);
      rmObjectDefPlaceAtLoc(centerSettlementID, 0, cCenterLoc);
   }

   // Settlements.
   int settlementAvoidBonusSettlement = rmCreateTypeDistanceConstraint(cUnitTypeSettlement, 70.0);
   int settlementAvoidTownCenter = createPlayerLocDistanceConstraint(35.0);

   int firstSettlementID = rmObjectDefCreate("first settlement");
   rmObjectDefAddItem(firstSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(firstSettlementID, settlementAvoidBonusSettlement);
   rmObjectDefAddConstraint(firstSettlementID, settlementAvoidTownCenter);

   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(firstSettlementID, true, 1, 40.0, 60.0, cSettlementDist1v1, cBiasAggressive);
   }
   else
   {
      // Randomize inside/outside.
      addObjectLocsPerPlayer(firstSettlementID, false, 1, 40.0, 70.0, cCloseSettlementDist, cBiasBackward | cBiasAllyInside);
   }

   generateLocs("close settlement locs", true, true, true, false);
      
   // Spawn paths to connect close settlements to starting town centers.
   int pathClassID = rmClassCreate();

   for(int i = 1; i <= cNumberPlayers; i++)
   {
      int p = vDefaultTeamPlayerOrder[i];
      
      int settlementPathID = rmPathCreate("settlement path " + p);
      rmPathSetCostNoise(settlementPathID, 0.0, 10.0);

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
      rmAreaSetCoherence(connectionID, 0.25);
      rmAreaSetPath(connectionID, settlementPathID, 0.0);
      rmAreaSetTerrainType(connectionID, cTerrainEgyptRoad1);
      rmAreaAddToClass(connectionID, pathClassID);
      rmAreaBuild(connectionID);
   }

   resetLocGen();

   // Far settlements.
   int secondSettlementID = rmObjectDefCreate("second settlement");
   rmObjectDefAddItem(secondSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(secondSettlementID, settlementAvoidBonusSettlement);
   rmObjectDefAddConstraint(secondSettlementID, settlementAvoidTownCenter);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidKotH);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(secondSettlementID, false, 1, 80.0, 100.0, cSettlementDist1v1, cBiasForward);
   }
   else if (gameIsFair() == true)
   {
      // Randomize inside/outside.
      addObjectLocsPerPlayer(secondSettlementID, false, 1, 100.0, 120.0, cFarSettlementDist, cBiasAggressive | getRandomAllyBias());
   }
   else
   {
      // Randomize inside/outside.
      addObjectLocsPerPlayer(secondSettlementID, false, 1, 100.0, 140.0, cFarSettlementDist, cBiasAggressive);
   }

   // Other map sizes settlements.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int bonusSettlementID = rmObjectDefCreate("bonus settlement");
      rmObjectDefAddItem(bonusSettlementID, cUnitTypeSettlement, 1);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidEdge);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(bonusSettlementID, settlementAvoidBonusSettlement);
      rmObjectDefAddConstraint(bonusSettlementID, settlementAvoidTownCenter);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidKotH);
      addObjectLocsPerPlayer(bonusSettlementID, false, 1 * getMapAreaSizeFactor(), 90.0, -1.0, 100.0);
   }

   generateLocs("far settlement locs");

   rmSetProgress(0.3);

   // Ponds.
   int pondClassID = rmClassCreate();
   int numPondsPerPlayer = 1 * getMapAreaSizeFactor();

   if(gameIs1v1() == true)
   {
      numPondsPerPlayer = xsRandInt(1 * getMapAreaSizeFactor(), 2 * getMapAreaSizeFactor());
   }

   float minPondSize = rmTilesToAreaFraction(375);
   float maxPondSize = rmTilesToAreaFraction(400);
   int pondAvoidPond = rmCreateClassDistanceConstraint(pondClassID, 40.0);
   int pondAvoidEdge = createSymmetricBoxConstraint(rmXMetersToFraction(16.0), rmZMetersToFraction(16.0));
   int pondAvoidSettlement = rmCreateTypeDistanceConstraint(cUnitTypeSettlement, 40.0);
   int pondAvoidStartingLoc = createPlayerLocDistanceConstraint(60.0);

   for(int j = 0; j < numPondsPerPlayer; j++)
   {
      for(int i = 1; i <= cNumberPlayers; i++)
      {
         int p = vDefaultTeamPlayerOrder[i];

         int pondID = rmAreaCreate("pond " + p + " " + j);
         rmAreaSetParent(pondID, vTeamAreaIDs[rmGetPlayerTeam(p)]);

         rmAreaSetSize(pondID, xsRandFloat(minPondSize, maxPondSize));
         rmAreaSetWaterType(pondID, cWaterEgyptLake);

         rmAreaSetBlobs(pondID, 1, 5);
         rmAreaSetBlobDistance(pondID, 10.0, 10.0);
         rmAreaSetWaterHeight(pondID, 3.0);

         rmAreaSetWaterHeightBlend(pondID, cFilter5x5Gaussian, 25.0, 10);
         
         rmAreaAddConstraint(pondID, pondAvoidPond);
         rmAreaAddConstraint(pondID, pondAvoidEdge);
         rmAreaAddConstraint(pondID, pondAvoidSettlement);
         rmAreaAddConstraint(pondID, pondAvoidStartingLoc);
         rmAreaAddConstraint(pondID, vDefaultAvoidKotH);
         rmAreaAddToClass(pondID, pondClassID);

         rmAreaBuild(pondID);
      }
   }

   rmSetProgress(0.4);

   // Starting objects.
   // Starting gold.
   int startingGoldID = rmObjectDefCreate("starting gold");
   rmObjectDefAddItem(startingGoldID, cUnitTypeMineGoldMedium, 1);
   rmObjectDefAddConstraint(startingGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingGoldID, vDefaultAvoidWater);
   rmObjectDefAddConstraint(startingGoldID, vDefaultStartingGoldAvoidTower);
   rmObjectDefAddConstraint(startingGoldID, vDefaultForceStartingGoldNearTower);
   addObjectLocsPerPlayer(startingGoldID, false, 1, cStartingGoldMinDist, cStartingGoldMaxDist, cStartingObjectAvoidanceMeters, cBiasNotAggressive);

   generateLocs("starting gold locs");

   // Berries.
   int avoidPath = rmCreateClassDistanceConstraint(pathClassID, 8.0);

   int startingBerriesID = rmObjectDefCreate("starting berries");
   rmObjectDefAddItem(startingBerriesID, cUnitTypeBerryBush, xsRandInt(5, 8), cBerryClusterRadius);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidWater);
   rmObjectDefAddConstraint(startingBerriesID, avoidPath);
   addObjectLocsPerPlayer(startingBerriesID, false, 1, 25.0, 32.0, cStartingObjectAvoidanceMeters);

   // Starting hunt.
   int startingHuntID = rmObjectDefCreate("starting hunt");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeRhinoceros, xsRandInt(2, 3));
      rmObjectDefAddItem(startingHuntID, cUnitTypeZebra, xsRandInt(1, 3));
   }
   else
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeHippopotamus, xsRandInt(3, 4));
   }
   rmObjectDefAddConstraint(startingHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidWater);
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
   rmObjectDefAddItem(startingHerdID, cUnitTypeGoat, xsRandInt(2, 5));
   rmObjectDefAddConstraint(startingHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidWater);
   addObjectLocsPerPlayer(startingHerdID, true, 1, cStartingHerdMinDist, cStartingHerdMaxDist);

   generateLocs("starting food locs");

   rmSetProgress(0.5);

   // Gold.
   float avoidGoldMeters = 50.0;

   // Close gold.
   int closeGoldID = rmObjectDefCreate("close gold");
   rmObjectDefAddItem(closeGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidWater);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeGoldID, 60.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeGoldID, false, 1, 60.0, 80.0, avoidGoldMeters, cBiasForward);
   }
   else
   {
      addObjectLocsPerPlayer(closeGoldID, false, 1, 60.0, 80.0, avoidGoldMeters);
   }

   // Bonus gold.
   int bonusGoldID = rmObjectDefCreate("bonus gold");
   rmObjectDefAddItem(bonusGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidWater);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(bonusGoldID, 80.0);

   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusGoldID, false, xsRandInt(3, 4) * getMapAreaSizeFactor(), 80.0, -1.0, avoidGoldMeters);
   }
   else
   {
      addObjectLocsPerPlayer(bonusGoldID, false, xsRandInt(3, 4) * getMapAreaSizeFactor(), 80.0, -1.0, avoidGoldMeters);
   }

   generateLocs("gold locs");

   rmSetProgress(0.6);

   // Hunt.
   float avoidHuntMeters = 50.0;

   // Close hunt.
   int closeHuntID = rmObjectDefCreate("close hunt");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeGiraffe, xsRandInt(3, 9));
   }
   else
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeGazelle, xsRandInt(3, 9));
   }
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeHuntID, 65.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeHuntID, false, 1, 65.0, 80.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(closeHuntID, false, 1, 65.0, 90.0, avoidHuntMeters);
   }

   // Bonus hunt 1.
   float bonusHunt1Float = xsRandFloat(0.0, 1.0);
   int bonusHunt1ID = rmObjectDefCreate("bonus hunt 1");
   if(bonusHunt1Float < 0.25)
   {
      rmObjectDefAddItem(bonusHunt1ID, cUnitTypeZebra, xsRandInt(2, 4));
      rmObjectDefAddItem(bonusHunt1ID, cUnitTypeGiraffe, xsRandInt(1, 2));
   }
   else if(bonusHunt1Float < 0.5)
   {
      rmObjectDefAddItem(bonusHunt1ID, cUnitTypeZebra, xsRandInt(6, 9));
   }
   else if(bonusHunt1Float < 0.75)
   {
      rmObjectDefAddItem(bonusHunt1ID, cUnitTypeGiraffe, xsRandInt(3, 4));
   }
   else
   {
      rmObjectDefAddItem(bonusHunt1ID, cUnitTypeGazelle, xsRandInt(4, 7));
   }
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(bonusHunt1ID, 80.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusHunt1ID, false, 1, 80.0, -1.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(bonusHunt1ID, false, 1, 80.0, -1.0, avoidHuntMeters);
   }

   // Bonus hunt 2.
   float bonusHunt2Float = xsRandFloat(0.0, 1.0);
   int bonusHunt2ID = rmObjectDefCreate("bonus hunt 2");
   if(bonusHunt2Float < 0.1)
   {
      rmObjectDefAddItem(bonusHunt2ID, cUnitTypeElephant, 3);
   }
   else if(bonusHunt2Float < 0.5)
   {
      rmObjectDefAddItem(bonusHunt2ID, cUnitTypeElephant, 2, 3.0);
   }
   else if(bonusHunt2Float < 0.9)
   {
      rmObjectDefAddItem(bonusHunt2ID, cUnitTypeRhinoceros, 2, 3.0);
   }
   else
   {
      rmObjectDefAddItem(bonusHunt2ID, cUnitTypeRhinoceros, 4, 3.0);
   }
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(bonusHunt2ID, 80.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusHunt2ID, false, 1, 80.0, -1.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(bonusHunt2ID, false, 1, 80.0, -1.0, avoidHuntMeters);
   }

   // Bonus hunt 3.
   int bonusHunt3ID = rmObjectDefCreate("bonus hunt 3");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(bonusHunt3ID, cUnitTypeMonkey, xsRandInt(6, 9));
   }
   else
   {
      rmObjectDefAddItem(bonusHunt3ID, cUnitTypeBaboon, xsRandInt(6, 9));
   }
   rmObjectDefAddConstraint(bonusHunt3ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHunt3ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(bonusHunt3ID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(bonusHunt3ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHunt3ID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(bonusHunt3ID, 80.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusHunt3ID, false, 1, 80.0, -1.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(bonusHunt3ID, false, 1, 80.0, -1.0, avoidHuntMeters);
   }

   // Other map sizes hunt.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int numLargeMapHunt = 2 * getMapSizeBonusFactor();
      for(int i = 0; i < numLargeMapHunt; i++)
      {
         float largeMapHuntFloat = xsRandFloat(0.0, 1.0);
         int largeMapHuntID = rmObjectDefCreate("large map hunt" + i);
         if(largeMapHuntFloat < 1.0 / 4.0)
         {
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeRhinoceros, xsRandInt(2, 4));
         }
         else if(largeMapHuntFloat < 2.0 / 4.0)
         {
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeMonkey, xsRandInt(7, 15));
         }
         else if(largeMapHuntFloat < 3.0 / 4.0)
         {
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeZebra, xsRandInt(3, 6));
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeGiraffe, xsRandInt(1, 3));
         }
         else
         {
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeGazelle, xsRandInt(6, 12));
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

   rmSetProgress(0.7);

   // Berries.
   float avoidBerriesMeters = 50.0;

   int berriesID = rmObjectDefCreate("berries");
   rmObjectDefAddItem(berriesID, cUnitTypeBerryBush, xsRandInt(5, 9), cBerryClusterRadius);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(berriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(berriesID, vDefaultBerriesAvoidWater);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(berriesID, 80.0);
   addObjectLocsPerPlayer(berriesID, false, 1 * getMapSizeBonusFactor(), 80.0, -1.0, avoidBerriesMeters);

   generateLocs("berries locs");

   // Herdables.
   float avoidHerdMeters = 50.0;

   int closeHerdID = rmObjectDefCreate("close herd");
   rmObjectDefAddItem(closeHerdID, cUnitTypeGoat, xsRandInt(1, 3));
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidWater);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidTowerLOS);
   addObjectDefPlayerLocConstraint(closeHerdID, 50.0);
   addObjectLocsPerPlayer(closeHerdID, false, xsRandInt(1, 2), 50.0, 70.0, avoidHerdMeters);

   int bonusHerdID = rmObjectDefCreate("bonus herd");
   rmObjectDefAddItem(bonusHerdID, cUnitTypeGoat, xsRandInt(1, 3));
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidWater);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidTowerLOS);
   addObjectDefPlayerLocConstraint(bonusHerdID, 70.0);
   addObjectLocsPerPlayer(bonusHerdID, false, 1 * getMapSizeBonusFactor(), 70.0, -1.0, avoidHerdMeters);

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
   rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidImpassableLand);
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
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidImpassableLand);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidWater);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(relicID, 80.0);
   addObjectLocsPerPlayer(relicID, false, 2 * getMapAreaSizeFactor(), 80.0, -1.0, avoidRelicMeters);

   generateLocs("relic locs");

   rmSetProgress(0.8);

   // Forests.
   float avoidForestMeters = 40.0;

   int forestDefID = rmAreaDefCreate("forest");
   rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(100), rmTilesToAreaFraction(125));
   rmAreaDefSetForestType(forestDefID, cForestEgyptPalm);
   rmAreaDefSetAvoidSelfDistance(forestDefID, avoidForestMeters);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidImpassableLand10);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddConstraint(forestDefID, avoidPath);

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
   // Avoid the owner paths to prevent forests from closing off resources.
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidOwnerPaths, 0.0);
   // rmAreaDefSetConstraintBuffer(forestDefID, 0.0, 6.0);

   // Build for each player in the team area.
   buildAreaDefInTeamAreas(forestDefID, 5 * getMapAreaSizeFactor());

   // Stragglers.
   placeStartingStragglers(cUnitTypeTreePalm);

   rmSetProgress(0.9);

   // Embellishment.
   buildAreaUnderObjectDef(firstSettlementID, cTerrainEgyptRoad1, cInvalidID, playerAreaRadiusMeters);
   buildAreaUnderObjectDef(secondSettlementID, cTerrainEgyptRoad1, cInvalidID, playerAreaRadiusMeters);

   // Center TC.
   if(centerSettlementID != cInvalidID)
   {
      buildAreaUnderObjectDef(centerSettlementID, cTerrainEgyptRoad1, cInvalidID, playerAreaRadiusMeters);
   }

   // Gold areas.
   buildAreaUnderObjectDef(startingGoldID, cTerrainEgyptDirtRocks2, cTerrainEgyptDirtRocks1, 6.0);
   buildAreaUnderObjectDef(closeGoldID, cTerrainEgyptDirtRocks2, cTerrainEgyptDirtRocks1, 6.0);
   buildAreaUnderObjectDef(bonusGoldID, cTerrainEgyptDirtRocks2, cTerrainEgyptDirtRocks1, 6.0);

   // Berries areas.
   buildAreaUnderObjectDef(startingBerriesID, cTerrainEgyptGrass1, cTerrainEgyptGrassDirt2, 9.0);
   buildAreaUnderObjectDef(berriesID, cTerrainEgyptGrass1, cTerrainEgyptGrassDirt2, 9.0);

   // Create team road connections.
   float roadWidth = 1.0; // == 0.5 tiles == only the tiles part of the actual path.

   // Team road path definition.
   int pathDefID = rmPathDefCreate("ally connection path");
   rmPathDefSetCostNoise(pathDefID, 0.0, 10.0);
   rmPathDefAddConstraint(pathDefID, vDefaultAvoidWater4);
   rmPathDefAddConstraint(pathDefID, rmCreateTypeDistanceConstraint(cUnitTypeBerryBush, 6.0));
   rmPathDefAddConstraint(pathDefID, rmCreateTypeDistanceConstraint(cUnitTypeGoldResource, 6.0));
   rmPathDefAddConstraint(pathDefID, rmCreateTypeDistanceConstraint(cUnitTypeTree, 4.0));
   // TODO Add random noise for the terrains we use for bonus randomness?

   // Player road areas built on the connections.
   int pathAreaDefID = rmAreaDefCreate("ally connection area");
   rmAreaDefSetTerrainType(pathAreaDefID, cTerrainEgyptRoad1);

   // Use both to build ally connections.
   createAllyConnections("ally connection", pathDefID, pathAreaDefID, roadWidth);

   // Random trees.
   int randomTreeID = rmObjectDefCreate("random tree");
   rmObjectDefAddItem(randomTreeID, cUnitTypeTreePalm, 1);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidImpassableLand);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidTree);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefPlaceAnywhere(randomTreeID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   // Water lilies.
   int lilyAvoidLand = rmCreateWaterDistanceConstraint(false, 4.0);
   int forceLilyNearLand = rmCreateWaterMaxDistanceConstraint(false, 6.0);

   int waterLilyID = rmObjectDefCreate("lily");
   rmObjectDefAddItem(waterLilyID, cUnitTypeWaterLily, 1);
   rmObjectDefAddConstraint(waterLilyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(waterLilyID, lilyAvoidLand);
   rmObjectDefAddConstraint(waterLilyID, forceLilyNearLand);
   rmObjectDefPlaceAnywhere(waterLilyID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   int waterLilyGroupID = rmObjectDefCreate("lily group");
   rmObjectDefAddItem(waterLilyGroupID, cUnitTypeWaterLily, xsRandInt(2, 4), 4.0);
   rmObjectDefAddConstraint(waterLilyGroupID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(waterLilyGroupID, lilyAvoidLand);
   rmObjectDefAddConstraint(waterLilyGroupID, forceLilyNearLand);
   rmObjectDefPlaceAnywhere(waterLilyGroupID, 0, 5 * cNumberPlayers * getMapAreaSizeFactor());

   // Rocks.
   int rockTinyID = rmObjectDefCreate("rock tiny");
   rmObjectDefAddItem(rockTinyID, cUnitTypeRockEgyptTiny, 1);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockTinyID, vDefaultAvoidWater4);
   rmObjectDefPlaceAnywhere(rockTinyID, 0, 50 * cNumberPlayers * getMapAreaSizeFactor());

   int rockSmallID = rmObjectDefCreate("rock small");
   rmObjectDefAddItem(rockSmallID, cUnitTypeRockEgyptSmall, 1);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockSmallID, vDefaultAvoidWater4);
   rmObjectDefPlaceAnywhere(rockSmallID, 0, 50 * cNumberPlayers * getMapAreaSizeFactor());

   // Plants.
   int plantShrubID = rmObjectDefCreate("plant shrub");
   rmObjectDefAddItem(plantShrubID, cUnitTypePlantDeadShrub, 1);
   rmObjectDefAddConstraint(plantShrubID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefPlaceAnywhere(plantShrubID, 0, 35 * cNumberPlayers * getMapAreaSizeFactor());

   int plantBushID = rmObjectDefCreate("plant bush");
   rmObjectDefAddItem(plantBushID, cUnitTypePlantDeadBush, 1);
   rmObjectDefAddConstraint(plantBushID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefPlaceAnywhere(plantBushID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());

   int plantFernID = rmObjectDefCreate("plant fern");
   rmObjectDefAddItem(plantFernID, cUnitTypePlantDeadFern, 1);
   rmObjectDefAddConstraint(plantFernID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefPlaceAnywhere(plantFernID, 0, 15 * cNumberPlayers * getMapAreaSizeFactor());

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeVulture, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   rmSetProgress(1.0);
}
