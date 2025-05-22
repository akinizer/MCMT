include "lib2/rm_core.xs";

void generateTriggers()
{
   rmTriggerAddScriptLine("rule _stonewall");
   rmTriggerAddScriptLine("highFrequency");
   rmTriggerAddScriptLine("active");
   rmTriggerAddScriptLine("runImmediately");
   rmTriggerAddScriptLine("{");
   rmTriggerAddScriptLine("   for(int i = 1; i <= cNumberPlayers; i++)");
   rmTriggerAddScriptLine("   {");
   rmTriggerAddScriptLine("      trTechSetStatus(i, cTechStoneWall, 2);");
   rmTriggerAddScriptLine("      xsDisableSelf();");
   rmTriggerAddScriptLine("   }");
   rmTriggerAddScriptLine("}");
}

mutable void applySuddenDeath()
{
   // Remove all settlements.
   rmRemoveUnitType(cUnitTypeSettlement);

   // Add some tents around towers.

   int tentAvoidTentMeters = 15.0;

   int tentID = rmObjectDefCreate(cSuddenDeathTentName);
   rmObjectDefAddItem(tentID, cUnitTypeTent, 1);
   rmObjectDefAddConstraint(tentID, vDefaultAvoidCollideable);
   addObjectLocsPerPlayer(tentID, true, cNumberSuddenDeathTents, cStartingTowerMinDist - 5.0,
                          cStartingTowerMaxDist + 15.0, tentAvoidTentMeters);

   generateLocs("sudden death tent locs");
}

void generate()
{
   rmSetProgress(0.0);

   // Define mixes.
   int baseMixID = rmCustomMixCreate("base mix");
   rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.15, 5, 0.5);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseGrass2, 4.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseGrass1, 4.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseGrassRocks1, 1.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseGrassDirt1, 5.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainNorseGrassDirt2, 5.0);
   
   int roadMix1ID = rmCustomMixCreate("road mix 1");
   rmCustomMixSetPaintParams(roadMix1ID, cNoiseFractalSum, 0.3, 5, 0.5);
   rmCustomMixAddPaintEntry(roadMix1ID, cTerrainNorseRoad, 3.0);
   rmCustomMixAddPaintEntry(roadMix1ID, cTerrainNorseGrassRocks2, 2.5);
   
   int roadMix2ID = rmCustomMixCreate("road mix 2");
   rmCustomMixSetPaintParams(roadMix2ID, cNoiseFractalSum, 0.3, 5, 0.5);
   rmCustomMixAddPaintEntry(roadMix2ID, cTerrainNorseGrassRocks2, 4.0);
   rmCustomMixAddPaintEntry(roadMix2ID, cTerrainNorseGrassRocks1, 4.0);
   
   int grassMixID = rmCustomMixCreate("grass mix");
   rmCustomMixSetPaintParams(grassMixID, cNoiseFractalSum, 0.15, 5, 0.5);
   rmCustomMixAddPaintEntry(grassMixID, cTerrainNorseGrassRocks1, 5.0);
   rmCustomMixAddPaintEntry(grassMixID, cTerrainNorseGrassRocks2, 1.0);
   rmCustomMixAddPaintEntry(grassMixID, cTerrainNorseGrassDirt1, 2.0);
   rmCustomMixAddPaintEntry(grassMixID, cTerrainNorseGrassDirt2, 1.0);
   rmCustomMixAddPaintEntry(grassMixID, cTerrainNorseGrass1, 3.0);
   rmCustomMixAddPaintEntry(grassMixID, cTerrainNorseGrass2, 3.0);

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
   float placementRadius = min(0.4, 0.5 - rmXTileIndexToFraction(20));
   
   rmPlacePlayersOnCircle(placementRadius);

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCivFromCulture(cCultureNorse);

   // KotH.
   placeKotHObjects();

   // Lighting.
   rmSetLighting(cLightingSetRmArena01);

   rmSetProgress(0.1);

   // Global elevation.
   rmAddGlobalHeightNoise(cNoiseFractalSum, 5.0, 0.075, 6, 0.3);
   
   // Center area.
   float centerAreaSize = rmRadiusToAreaFraction(rmXFractionToMeters(placementRadius) - 5.0);
   
   int centerAreaID = rmAreaCreate("center area");
   rmAreaSetSize(centerAreaID, centerAreaSize);
   rmAreaSetLoc(centerAreaID, cCenterLoc);
   // This is needed so the forest can always surround the center no matter what.
   rmAreaAddConstraint(centerAreaID, createSymmetricBoxConstraint(rmXTilesToFraction(5), rmZTilesToFraction(5)));
   rmAreaBuild(centerAreaID);

   int forceToCenterArea = rmCreateAreaConstraint(centerAreaID);
   
   // Settlements.
   placeStartingTownCenters();

   // Fake player areas to block out edge forests.
   int fakePlayerAreaClassID = rmClassCreate();
   int fakePlayerAreaAvoidEdge = createSymmetricBoxConstraint(rmXTileIndexToFraction(1), rmZTileIndexToFraction(1));
   float fakePlayerAreaSize = rmRadiusToAreaFraction(40.0);

   for(int i = 1; i <= cNumberPlayers; i++)
   {
      int p = vDefaultTeamPlayerOrder[i];

      int fakePlayerAreaID = rmAreaCreate("fake player area " + p);
      rmAreaSetSize(fakePlayerAreaID, fakePlayerAreaSize);
      rmAreaSetLocPlayer(fakePlayerAreaID, p);

      rmAreaSetCoherence(fakePlayerAreaID, 0.0, 32.0);

      rmAreaAddConstraint(fakePlayerAreaID, fakePlayerAreaAvoidEdge);      
      rmAreaAddToClass(fakePlayerAreaID, fakePlayerAreaClassID);

      rmAreaBuild(fakePlayerAreaID);
   }

   // Edge forests.
   int classOuterForestID = rmClassCreate();
   int avoidOuterForest = rmCreateClassDistanceConstraint(classOuterForestID, 1.0);
   int outerForestAvoidPlayer = rmCreateClassDistanceConstraint(fakePlayerAreaClassID, 0.1);
   int outerForestAvoidCenter = rmCreateAreaDistanceConstraint(centerAreaID, 0.1);

   for(int i = 0; i < 4; i++)
   {
      int outerForestID = rmAreaCreate("outer forest area " + i);
      rmAreaSetForestType(outerForestID, cForestNorsePineMix);
      rmAreaSetForestUnderbrushDensity(outerForestID, 1.0);
      rmAreaSetSize(outerForestID, 1.0);
      rmAreaSetCoherence(outerForestID, 1.0);
      rmAreaAddToClass(outerForestID, classOuterForestID);

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

      rmAreaAddConstraint(outerForestID, outerForestAvoidPlayer);
      // If you have a buffer for this one, make sure the box constraint for the center is still large enough.
      rmAreaAddConstraint(outerForestID, outerForestAvoidCenter, 0.0, 6.0);
      rmAreaAddConstraint(outerForestID, avoidOuterForest);
   }

   rmAreaBuildAll();
   
   rmSetProgress(0.2);

   // Arena walls and 15 gold for 1 gate.
   float wallRadiusMeters = 50.0;

   for(int i = 1; i <= cNumberPlayers; i++)
   {
      int p = vDefaultTeamPlayerOrder[i];

      rmWallsPlaceSquare(p, rmGetPlayerLoc(p), wallRadiusMeters);

      addProtoCostToPlayerRes(cUnitTypeWallGate, p);
   }

   // Block out player areas.
   float wallRadiusFraction = rmXMetersToFraction(wallRadiusMeters);
   vector wallBoxOffset = vectorXZ(wallRadiusFraction, wallRadiusFraction);
   int playerAreaClassID = rmClassCreate();
   int avoidPlayerArea = rmCreateClassDistanceConstraint(playerAreaClassID, 1.0);
   int avoidTrees = rmCreateTypeDistanceConstraint(cUnitTypeTree, 1.0);

   for(int i = 1; i <= cNumberPlayers; i++)
   {
      int p = vDefaultTeamPlayerOrder[i];
      vector pPos = rmGetPlayerLoc(p);
      int forceInsideWalls = rmCreateBoxConstraint(pPos - wallBoxOffset, pPos + wallBoxOffset);

      int playerAreaID = rmAreaCreate("player wall area " + p);
      rmAreaSetSize(playerAreaID, 1.0);
      rmAreaSetLocPlayer(playerAreaID, p);
      
      rmAreaAddConstraint(playerAreaID, forceInsideWalls);
      rmAreaAddConstraint(playerAreaID, avoidTrees);
      rmAreaAddToClass(playerAreaID, playerAreaClassID);

      rmAreaBuild(playerAreaID);
   }

   rmSetProgress(0.3);

   // Starting towers.
   // Make the towers always face towards the center (and not towards enemies/along the team angle).
   vDefaultPlayerLocForwardAngles = vPlayerLocForwardAnglesByPlayer;
   
   int startingTowerID = rmObjectDefCreate("starting tower");
   rmObjectDefAddItem(startingTowerID, cUnitTypeSentryTower, 1);
   rmObjectDefAddConstraint(startingTowerID, rmCreateTypeDistanceConstraint(cUnitTypeAll, 5.0));
   int[] startingTowerLocs = addObjectLocsPerPlayer(startingTowerID, true, 5, 40.0, 46.0, 24.0, cBiasAggressive);
   // Make the locs generate in a square around the player.
   setLocsSquarePlacement(startingTowerLocs, true);

   generateLocs("starting tower locs");

   // Reset the angles.
   vDefaultPlayerLocForwardAngles = vPlayerLocForwardAnglesByTeam;

   rmSetProgress(0.4);

   // Settlements.
   int settlementAvoidCenterAreaEdge = rmCreateAreaEdgeDistanceConstraint(centerAreaID, 16.0);
   
   int firstSettlementID = rmObjectDefCreate("first settlement");
   rmObjectDefAddItem(firstSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(firstSettlementID, forceToCenterArea);
   rmObjectDefAddConstraint(firstSettlementID, settlementAvoidCenterAreaEdge);
   rmObjectDefAddConstraint(firstSettlementID, avoidPlayerArea);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidKotH);

   int secondSettlementID = rmObjectDefCreate("second settlement");
   rmObjectDefAddItem(secondSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(secondSettlementID, forceToCenterArea);
   rmObjectDefAddConstraint(secondSettlementID, settlementAvoidCenterAreaEdge);
   rmObjectDefAddConstraint(secondSettlementID, avoidPlayerArea);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidKotH);

   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(firstSettlementID, false, 1, 80.0, 90.0, cSettlementDist1v1, cBiasForward);
      addSimObjectLocsPerPlayerPair(secondSettlementID, false, 1, 120.0, 130.0, cSettlementDist1v1, cBiasForward);
   }
   else
   {
      addObjectLocsPerPlayer(firstSettlementID, false, 1, 80.0, 100.0, cCloseSettlementDist, cBiasForward);
      addObjectLocsPerPlayer(secondSettlementID, false, 1, 100.0, 150.0, cFarSettlementDist, cBiasForward);
   }
   
   // Other map sizes settlements.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int bonusSettlementID = rmObjectDefCreate("bonus settlement");
      rmObjectDefAddItem(bonusSettlementID, cUnitTypeSettlement, 1);
      rmObjectDefAddConstraint(bonusSettlementID, forceToCenterArea);
      rmObjectDefAddConstraint(bonusSettlementID, settlementAvoidCenterAreaEdge);
      rmObjectDefAddConstraint(bonusSettlementID, avoidPlayerArea);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidKotH);
      addObjectLocsPerPlayer(bonusSettlementID, false, 1 * getMapAreaSizeFactor(), 90.0, -1.0, 100.0);
   }

   generateLocs("settlement locs");

   rmSetProgress(0.5);

   // Starting objects.
   // Starting gold.
   int startingGoldID = rmObjectDefCreate("starting gold");
   rmObjectDefAddItem(startingGoldID, cUnitTypeMineGoldMedium, 1);
   rmObjectDefAddConstraint(startingGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingGoldID, vDefaultGoldAvoidAll);
   addObjectLocsPerPlayer(startingGoldID, false, 2, 20.0, 26.0, 30.0);

   generateLocs("starting gold locs");

   // Starting hunt.
   int startingHunt1ID = rmObjectDefCreate("starting hunt 1");
   rmObjectDefAddItem(startingHunt1ID, cUnitTypeElk, xsRandInt(8, 9));
   rmObjectDefAddConstraint(startingHunt1ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHunt1ID, vDefaultFoodAvoidAll);
   addObjectLocsPerPlayer(startingHunt1ID, false, 1, cStartingHuntMinDist, 30.0, 16.0);
   
   int startingHunt2ID = rmObjectDefCreate("starting hunt 2");
   rmObjectDefAddItem(startingHunt2ID, cUnitTypeCaribou, xsRandInt(4, 6));
   rmObjectDefAddItem(startingHunt2ID, cUnitTypeElk, xsRandInt(3, 4));
   rmObjectDefAddConstraint(startingHunt2ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHunt2ID, vDefaultFoodAvoidAll);
   addObjectLocsPerPlayer(startingHunt2ID, false, 1, 30.0, 45.0, 16.0);

   // Chicken.
   int startingChickenID = rmObjectDefCreate("starting chicken");
   rmObjectDefAddItem(startingChickenID, cUnitTypeChicken, xsRandInt(5, 9));
   rmObjectDefAddConstraint(startingChickenID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidAll);
   addObjectLocsPerPlayer(startingChickenID, false, 1, cStartingChickenMinDist, 30.0, 16.0);

   // Berries.
   int startingBerriesID = rmObjectDefCreate("starting berries");
   rmObjectDefAddItem(startingBerriesID, cUnitTypeBerryBush, xsRandInt(6, 9), cBerryClusterRadius);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidAll);
   addObjectLocsPerPlayer(startingBerriesID, false, 1, cStartingBerriesMinDist, 36.0, 16.0);

   // Herdables.
   int startingHerdID = rmObjectDefCreate("starting herd");
   rmObjectDefAddItem(startingHerdID, cUnitTypeCow, xsRandInt(2, 4));
   rmObjectDefAddConstraint(startingHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidAll);
   addObjectLocsPerPlayer(startingHerdID, true, 1, cStartingHerdMinDist, 40.0);

   generateLocs("starting food locs");
   
   rmSetProgress(0.6);
   
   // Gold.
   float avoidGoldMeters = 40.0;

   // Bonus gold.
   int bonusGoldID = rmObjectDefCreate("bonus gold");
   rmObjectDefAddItem(bonusGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(bonusGoldID, 65.0);
   addObjectLocsPerPlayer(bonusGoldID, false, xsRandInt(3, 4) * getMapAreaSizeFactor(), 65.0, -1.0, avoidGoldMeters);

   generateLocs("gold locs");

   // Hunt.
   float avoidHuntMeters = 30.0;

   // Close hunt.
   int closeHuntID = rmObjectDefCreate("close hunt");
   rmObjectDefAddItem(closeHuntID, cUnitTypeBoar, xsRandInt(2, 3));
   rmObjectDefAddItem(closeHuntID, cUnitTypeElk, xsRandInt(3, 4));
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeHuntID, 60.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeHuntID, false, 1, 60.0, 90.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(closeHuntID, false, 1, 60.0, 90.0, avoidHuntMeters);
   }
   
   generateLocs("hunt locs");

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
   rmObjectDefAddConstraint(farHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(farHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(farHuntID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(farHuntID, 70.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(farHuntID, false, 1, 70.0, -1.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(farHuntID, false, 1 , 70.0, -1.0, avoidHuntMeters);
   }

   // Other map sizes hunt.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int largeMapHuntID = rmObjectDefCreate("large map hunt");
      if(xsRandBool(0.5) == true)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeCaribou, xsRandInt(3, 7));
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeElk, xsRandInt(3, 7));
      }
      else
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeAurochs, xsRandInt(3, 5));
      }

      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidSettlementRange);
      addObjectDefPlayerLocConstraint(largeMapHuntID, 100.0);
      addObjectLocsPerPlayer(largeMapHuntID, false, 1 * getMapSizeBonusFactor(), 100.0, -1.0, avoidHuntMeters);
   }

   generateLocs("far hunt locs");

   rmSetProgress(0.7);

   // Berries.
   int berriesID = rmObjectDefCreate("berries");
   rmObjectDefAddItem(berriesID, cUnitTypeBerryBush, xsRandInt(7, 10), cBerryClusterRadius);
   rmObjectDefAddConstraint(berriesID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(berriesID, 60.0);
   addObjectLocsPerPlayer(berriesID, false, 1 * getMapSizeBonusFactor(), 60.0, -1.0, 50.0);

   generateLocs("berries locs");

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
   rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(predatorID, 80.0);
   addObjectLocsPerPlayer(predatorID, false, xsRandInt(1, 2) * getMapAreaSizeFactor(), 80.0, -1.0, 50.0);

   generateLocs("predator locs");

   // Herdables.
   float avoidHerdMeters = 50.0;
   
   int bonusHerdID = rmObjectDefCreate("bonus herd");
   rmObjectDefAddItem(bonusHerdID, cUnitTypeCow, xsRandInt(1, 2));
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidTowerLOS);
   addObjectLocsPerPlayer(bonusHerdID, false, xsRandInt(2, 3) * getMapAreaSizeFactor(), 65.0, -1.0, avoidHerdMeters);

   generateLocs("herd locs");

   // Relics.
   int relicID = rmObjectDefCreate("relic");
   rmObjectDefAddItem(relicID, cUnitTypeRelic, 1);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidAll);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(relicID, 70.0);
   addObjectLocsPerPlayer(relicID, false, 2 * getMapAreaSizeFactor(), 70.0, -1.0, 80.0);

   generateLocs("relic locs");
   
   // Stragglers.
   placeStartingStragglers(cUnitTypeTreePine);

   rmSetProgress(0.8);
    
   // Embellishment.
   // Gold areas.
   buildAreaUnderObjectDef(startingGoldID, cTerrainNorseGrassRocks2, cTerrainNorseGrassRocks1, 6.0);
   buildAreaUnderObjectDef(bonusGoldID, cTerrainNorseGrassRocks2, cTerrainNorseGrassRocks1, 6.0);

   // Berries areas.
   buildAreaUnderObjectDef(startingBerriesID, cTerrainNorseGrass2, cTerrainNorseGrass1, 8.0);
   buildAreaUnderObjectDef(berriesID, cTerrainNorseGrass2, cTerrainNorseGrass1, 10.0);
    
   rmSetProgress(0.9);
   
   // Random trees.
   int randomTreeID = rmObjectDefCreate("random tree");
   rmObjectDefAddItem(randomTreeID, cUnitTypeTreePine, 1);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidTree);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefPlaceAnywhere(randomTreeID, 0, 8 * cNumberPlayers * getMapAreaSizeFactor());

   // Rocks.
   int rockTinyID = rmObjectDefCreate("rock tiny");
   rmObjectDefAddItem(rockTinyID, cUnitTypeRockNorseTiny, 1);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefPlaceAnywhere(rockTinyID, 0, 45 * cNumberPlayers * getMapAreaSizeFactor());

   int rockSmallID = rmObjectDefCreate("rock small");
   rmObjectDefAddItem(rockSmallID, cUnitTypeRockNorseSmall, 1);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefPlaceAnywhere(rockSmallID, 0, 45 * cNumberPlayers * getMapAreaSizeFactor());

   // Plants.
   int grassID = rmObjectDefCreate("grass");
   rmObjectDefAddItem(grassID, cUnitTypePlantNorseGrass, 1);
   rmObjectDefAddConstraint(grassID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefPlaceAnywhere(grassID, 0, 40 * cNumberPlayers * getMapAreaSizeFactor());

   int bushID = rmObjectDefCreate("bush");
   rmObjectDefAddItem(bushID, cUnitTypePlantNorseBush, 1);
   rmObjectDefAddConstraint(bushID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefPlaceAnywhere(bushID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());

   int shrubID = rmObjectDefCreate("shrub");
   rmObjectDefAddItem(shrubID, cUnitTypePlantNorseShrub, 1);
   rmObjectDefAddConstraint(shrubID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefPlaceAnywhere(shrubID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());

   int weedsID = rmObjectDefCreate("weeds");
   rmObjectDefAddItem(weedsID, cUnitTypePlantNorseWeeds, 1);
   rmObjectDefAddConstraint(weedsID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefPlaceAnywhere(weedsID, 0, 40 * cNumberPlayers * getMapAreaSizeFactor());
   
   int destroyedSmallID = rmObjectDefCreate("destroyed small");
   rmObjectDefAddItem(destroyedSmallID, cUnitTypeDestroyedSmall, 1);
   rmObjectDefAddConstraint(destroyedSmallID, vDefaultAvoidAll12);
   rmObjectDefAddConstraint(destroyedSmallID, forceToCenterArea);
   rmObjectDefAddConstraint(destroyedSmallID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefAddConstraint(destroyedSmallID, rmCreateClassDistanceConstraint(playerAreaClassID, 20.0));
   rmObjectDefPlaceAnywhere(destroyedSmallID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());
   
   int destroyedMedID = rmObjectDefCreate("destroyed med");
   rmObjectDefAddItem(destroyedMedID, cUnitTypeDestroyedMed, 1);
   rmObjectDefAddConstraint(destroyedMedID, vDefaultAvoidAll12);
   rmObjectDefAddConstraint(destroyedMedID, forceToCenterArea);
   rmObjectDefAddConstraint(destroyedMedID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefAddConstraint(destroyedMedID, rmCreateClassDistanceConstraint(playerAreaClassID, 20.0));
   rmObjectDefPlaceAnywhere(destroyedMedID, 0, cNumberPlayers * getMapAreaSizeFactor());

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeHawk, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());
   
   generateTriggers();

   rmSetProgress(1.0);
}
