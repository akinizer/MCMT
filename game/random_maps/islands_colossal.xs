include "lib2/rm_core.xs";

void generate()
{
   rmSetProgress(0.0);
   
   // Define Mixes.
   int baseMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.25, 5, 0.1);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainAtlanteanGrass2, 4.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainAtlanteanGrass1, 4.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainAtlanteanGrassRocks1, 2.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainAtlanteanGrassDirt1, 3.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainAtlanteanGrassDirt2, 3.0);

   // Water overrides.
   rmWaterTypeAddBeachLayer(cWaterAtlanteanSea, cTerrainAtlanteanBeach1, 3.0, 2.0);
   rmWaterTypeAddBeachLayer(cWaterAtlanteanSea, cTerrainAtlanteanGrassDirt3, 5.0, 2.0);
   rmWaterTypeAddBeachLayer(cWaterAtlanteanSea, cTerrainAtlanteanGrassDirt2, 7.0, 2.0);

 // Set size.
   int playerTiles=20000;
   int cNumberNonGaiaPlayers = 10;
   if(cMapSizeCurrent == 1)
   {
      playerTiles = 30000;
   }
   int size=2.0*sqrt(cNumberNonGaiaPlayers*playerTiles/0.9);
   rmSetMapSize(size, size);
   rmInitializeWater(cWaterAtlanteanSea);

   // Player placement.
   float radiusVarMeters = rmXFractionToMeters(0.075);
   rmPlacePlayersOnCircle(0.35, radiusVarMeters);

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCivFromCulture(cCultureAtlantean);

   // KotH.
   float islandAvoidIslandDist = 25.0;
   int bonusIslandClassID = rmClassCreate();
   int islandClassID = rmClassCreate();
   int avoidIsland = rmCreateClassDistanceConstraint(islandClassID, islandAvoidIslandDist);

   if (gameIsKotH() == true)
   {
      int islandKotHID = rmAreaCreate("koth island");
      rmAreaSetSize(islandKotHID, rmRadiusToAreaFraction(20.0 + (3 * cNumberPlayers)));
      rmAreaSetLoc(islandKotHID, cCenterLoc);
      rmAreaSetMix(islandKotHID, baseMixID);

      rmAreaSetHeight(islandKotHID, 1.0);
      rmAreaAddHeightBlend(islandKotHID, cBlendEdge, cFilter5x5Gaussian, 10, 10);
      
      rmAreaAddToClass(islandKotHID, bonusIslandClassID);
      rmAreaAddToClass(islandKotHID, islandClassID);

      rmAreaBuild(islandKotHID);
   }

   placeKotHObjects();


   // Lighting.
   rmSetLighting(cLightingSetRmIslands01);

   rmSetProgress(0.1);

   // Shared island constraint.
   int islandAvoidEdge = createSymmetricBoxConstraint(rmXTilesToFraction(5));

   // Player areas.
   int playerIslandClassID = rmClassCreate();

   int avoidPlayerIsland = rmCreateClassDistanceConstraint(playerIslandClassID, 0.1);
   int avoidBonusIsland = rmCreateClassDistanceConstraint(bonusIslandClassID, 0.1);

   float playerIslandSize = rmTilesToAreaFraction(xsRandInt(3500, 4000));

   for(int i = 1; i <= cNumberPlayers; i++)
   {
      int p = vDefaultTeamPlayerOrder[i];

      int playerIslandID = rmAreaCreate("player island " + p);
      rmAreaSetSize(playerIslandID, playerIslandSize);
      rmAreaSetMix(playerIslandID, baseMixID);
      rmAreaSetLoc(playerIslandID, rmGetPlayerLoc(p));

      rmAreaSetHeight(playerIslandID, 1.0);
      rmAreaAddHeightBlend(playerIslandID, cBlendEdge, cFilter5x5Gaussian, 15, 10);
      rmAreaSetBlobs(playerIslandID, 2, 5);
      rmAreaSetBlobDistance(playerIslandID, 35.0);
      
      rmAreaAddConstraint(playerIslandID, vDefaultAvoidEdge);
      rmAreaAddConstraint(playerIslandID, avoidIsland);
      rmAreaSetConstraintBuffer(playerIslandID, 0.0, 20.0);
      rmAreaAddToClass(playerIslandID, playerIslandClassID);
      rmAreaAddToClass(playerIslandID, islandClassID);
   }

   rmAreaBuildAll();

   rmSetProgress(0.2);

   // Randomly place some bonus islands.
   int numBonusIslands = 3 * cNumberPlayers * getMapAreaSizeFactor();
   float bonusIslandMinSize = rmTilesToAreaFraction(1500);
   float bonusIslandMaxSize = rmTilesToAreaFraction(2500 * getMapAreaSizeFactor());
   int bonusIslandOriginAvoidEdge = createSymmetricBoxConstraint(rmXTilesToFraction(10));

   for(int i = 1; i <= numBonusIslands; i++)
   {
      int bonusIslandID = rmAreaCreate("bonus island " + i);
      rmAreaSetSize(bonusIslandID, xsRandFloat(bonusIslandMinSize, bonusIslandMaxSize));
      rmAreaSetMix(bonusIslandID, baseMixID);

      rmAreaSetHeight(bonusIslandID, 1.0);
      rmAreaAddHeightBlend(bonusIslandID, cBlendEdge, cFilter5x5Gaussian, 10, 10);

      rmAreaSetBlobs(bonusIslandID, 0, 4);
      rmAreaSetBlobDistance(bonusIslandID, 15.0);

      rmAreaAddConstraint(bonusIslandID, avoidIsland);
      rmAreaAddOriginConstraint(bonusIslandID, bonusIslandOriginAvoidEdge);
      //rmAreaSetConstraintBuffer(bonusIslandID, 0.0, 5.0);
      rmAreaAddToClass(bonusIslandID, bonusIslandClassID);
      rmAreaAddToClass(bonusIslandID, islandClassID);

      rmAreaBuild(bonusIslandID);
   }

   rmSetProgress(0.3);
   // Settlements and towers.
   placeStartingTownCenters();

   // Starting towers.
   int startingTowerID = rmObjectDefCreate("starting tower");
   rmObjectDefAddItem(startingTowerID, cUnitTypeSentryTower, 1);
   rmObjectDefAddConstraint(startingTowerID, vDefaultAvoidImpassableLand4);
   addObjectLocsPerPlayer(startingTowerID, true, 4, cStartingTowerMinDist, cStartingTowerMaxDist, cStartingTowerAvoidanceMeters);
   generateLocs("starting tower locs");

   // Settlements.

   int InAreaCustom = cInAreaNone;

   if (gameIsFair() == true)
   {
      InAreaCustom = cInAreaTeam;
   }

   int playerIslandSettlementID = rmObjectDefCreate("player settlement");
   rmObjectDefAddItem(playerIslandSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(playerIslandSettlementID, vDefaultSettlementAvoidWater);
   rmObjectDefAddConstraint(playerIslandSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(playerIslandSettlementID, avoidBonusIsland);

   // Settlements.
   int bonusIslandSettlementID = rmObjectDefCreate("bonus island settlement");
   rmObjectDefAddItem(bonusIslandSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(bonusIslandSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(bonusIslandSettlementID, vDefaultSettlementAvoidWater);
   rmObjectDefAddConstraint(bonusIslandSettlementID, vDefaultSettlementForceInSiegeShipRange);
   rmObjectDefAddConstraint(bonusIslandSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusIslandSettlementID, avoidPlayerIsland);
   rmObjectDefAddConstraint(bonusIslandSettlementID, vDefaultAvoidKotH);

   addObjectLocsPerPlayer(playerIslandSettlementID, false, 1, 35.0, 100.0, cCloseSettlementDist, cBiasNone, InAreaCustom);
   addObjectLocsPerPlayer(bonusIslandSettlementID, false, 1, 60.0, -1.0, cFarSettlementDist, cBiasNone, InAreaCustom);
   
   // Other map sizes settlements.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int bonusSettlementID = rmObjectDefCreate("bonus settlement");
      rmObjectDefAddItem(bonusSettlementID, cUnitTypeSettlement, 1);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidEdge);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidWater);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementForceInSiegeShipRange);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(bonusSettlementID, avoidPlayerIsland);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidKotH);
      addObjectLocsPerPlayer(bonusSettlementID, false, 1 * getMapAreaSizeFactor(), 90.0, -1.0, 100.0);
   }

   generateLocs("settlement locs");

   rmSetProgress(0.4);

   // Starting objects.
   // Starting gold.
   int startingGoldID = rmObjectDefCreate("starting gold");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(startingGoldID, cUnitTypeMineGoldMedium, 1);
   }
   else
   {
      rmObjectDefAddItem(startingGoldID, cUnitTypeMineGoldLarge, 1);
   }
   rmObjectDefAddConstraint(startingGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingGoldID, vDefaultGoldAvoidWater);
   rmObjectDefAddConstraint(startingGoldID, vDefaultStartingGoldAvoidTower);
   rmObjectDefAddConstraint(startingGoldID, vDefaultForceStartingGoldNearTower);
   addObjectLocsPerPlayer(startingGoldID, false, 1, cStartingGoldMinDist, cStartingGoldMaxDist, cStartingObjectAvoidanceMeters);

   generateLocs("starting gold locs");

   // Berries.
   int startingBerriesID = rmObjectDefCreate("starting berries");
   rmObjectDefAddItem(startingBerriesID, cUnitTypeBerryBush, xsRandInt(6, 10), cBerryClusterRadius);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidWater);
   addObjectLocsPerPlayer(startingBerriesID, false, 1, cStartingBerriesMinDist, cStartingBerriesMaxDist, cStartingObjectAvoidanceMeters);

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
   rmObjectDefAddConstraint(startingHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(startingHuntID, vDefaultForceInTowerLOS);
   addObjectLocsPerPlayer(startingHuntID, false, 1, cStartingHuntMinDist, cStartingHuntMaxDist, cStartingObjectAvoidanceMeters);

   // Chicken.
   int startingChickenID = rmObjectDefCreate("starting chicken");
   rmObjectDefAddItem(startingChickenID, cUnitTypeChicken, xsRandInt(6, 10));
   rmObjectDefAddConstraint(startingChickenID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidWater);
   addObjectLocsPerPlayer(startingChickenID, false, 1, cStartingChickenMinDist, cStartingChickenMaxDist, cStartingObjectAvoidanceMeters);

   // Herdables.
   int startingHerdID = rmObjectDefCreate("starting herd");
   rmObjectDefAddItem(startingHerdID, cUnitTypePig, xsRandInt(2, 4));
   rmObjectDefAddConstraint(startingHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidWater);
   addObjectLocsPerPlayer(startingHerdID, true, 1, cStartingHerdMinDist, cStartingHerdMaxDist);

   generateLocs("starting food locs");

   rmSetProgress(0.5);

   // Gold.
   float avoidGoldMeters = 50.0;

   int playerGoldID = rmObjectDefCreate("player gold");
   rmObjectDefAddItem(playerGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(playerGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(playerGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(playerGoldID, vDefaultGoldAvoidWater);
   rmObjectDefAddConstraint(playerGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(playerGoldID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefAddConstraint(playerGoldID, avoidBonusIsland);
   addObjectLocsPerPlayer(playerGoldID, false, 2, 40.0, 100.0, avoidGoldMeters, cInAreaPlayer);

   generateLocs("player gold locs");

   // Hunt.
   float avoidHuntMeters = 40.0;

   int numPlayerHunt = xsRandInt(1, 2);

   for(int i = 0; i < numPlayerHunt; i++)
   {
      float huntFloat = xsRandFloat(0.0, 1.0);
      int playerHuntID = rmObjectDefCreate("player hunt " + i);
      if(huntFloat < 1.0 / 3.0)
      {
         rmObjectDefAddItem(playerHuntID, cUnitTypeDeer, xsRandInt(6, 9));
      }
      else if(huntFloat < 2.0 / 3.0)
      {
         rmObjectDefAddItem(playerHuntID, cUnitTypeBoar, xsRandInt(1, 3));
         rmObjectDefAddItem(playerHuntID, cUnitTypeDeer, xsRandInt(2, 4));
      }
      else
      {
         rmObjectDefAddItem(playerHuntID, cUnitTypeAurochs, xsRandInt(2, 4));
      }
      rmObjectDefAddConstraint(playerHuntID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(playerHuntID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(playerHuntID, vDefaultFoodAvoidWater);
      rmObjectDefAddConstraint(playerHuntID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(playerHuntID, vDefaultAvoidSettlementWithFarm);
      rmObjectDefAddConstraint(playerHuntID, avoidBonusIsland);
      addObjectLocsPerPlayer(playerHuntID, false, 1, 40.0, -1.0, avoidHuntMeters, cInAreaPlayer);
   }

   generateLocs("player hunt locs");

   int numBonusHunt = xsRandInt(1, 2);

   for(int i = 0; i < numBonusHunt; i++)
   {
      int bonusHuntID = rmObjectDefCreate("bonus hunt " + i);
      rmObjectDefAddItem(bonusHuntID, cUnitTypeBoar, xsRandInt(4, 6));
      rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidWater);
      rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidSettlementWithFarm);
      rmObjectDefAddConstraint(bonusHuntID, avoidPlayerIsland);
      addObjectLocsPerPlayer(bonusHuntID, false, 1, 50.0, -1.0, avoidHuntMeters, cInAreaPlayer);
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
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeDeer, xsRandInt(4, 9));
         }
         else
         {
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeBoar, xsRandInt(1, 3));
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeDeer, xsRandInt(3, 6));
         }

         rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidEdge);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidAll);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidWater);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidTowerLOS);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidSettlementWithFarm);
         rmObjectDefAddConstraint(largeMapHuntID, avoidPlayerIsland);
         addObjectLocsPerPlayer(largeMapHuntID, false, 1, 100.0, -1.0, avoidHuntMeters);
      }
   }

   generateLocs("bonus hunt locs");

   rmSetProgress(0.6);

   // Herdables.
   float avoidHerdMeters = 30.0;

   int numPlayerHerd = xsRandInt(1, 2);

   for(int i = 0; i < numPlayerHerd; i++)
   {
      int playerHerdID = rmObjectDefCreate("player herd " + i);
      rmObjectDefAddItem(playerHerdID, cUnitTypePig, xsRandInt(1, 3));
      rmObjectDefAddConstraint(playerHerdID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(playerHerdID, vDefaultHerdAvoidAll);
      rmObjectDefAddConstraint(playerHerdID, vDefaultHerdAvoidWater);
      rmObjectDefAddConstraint(playerHerdID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(playerHerdID, avoidBonusIsland);
      addObjectLocsPerPlayer(playerHerdID, false, 1, 40.0, 100.0, avoidHerdMeters, cInAreaPlayer);
   }

   generateLocs("player herd locs");

   // Berries.
   float avoidBerriesMeters = 40.0;

   int playerBerriesID = rmObjectDefCreate("player berries");
   rmObjectDefAddItem(playerBerriesID, cUnitTypeBerryBush, xsRandInt(5, 9), cBerryClusterRadius);
   rmObjectDefAddConstraint(playerBerriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(playerBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(playerBerriesID, vDefaultBerriesAvoidWater);
   rmObjectDefAddConstraint(playerBerriesID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(playerBerriesID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefAddConstraint(playerBerriesID, avoidBonusIsland);
   addObjectLocsPerPlayer(playerBerriesID, false, 1, 40.0, 100.0, avoidBerriesMeters, cInAreaPlayer);

   // Other map sizes berries.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int largeMapBerriesID = rmObjectDefCreate("large map berries");
      rmObjectDefAddItem(largeMapBerriesID, cUnitTypeBerryBush, xsRandInt(6, 11), cBerryClusterRadius);
      rmObjectDefAddConstraint(largeMapBerriesID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(largeMapBerriesID, vDefaultBerriesAvoidAll);
      rmObjectDefAddConstraint(largeMapBerriesID, vDefaultBerriesAvoidWater);
      rmObjectDefAddConstraint(largeMapBerriesID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(largeMapBerriesID, vDefaultAvoidSettlementWithFarm);
      rmObjectDefAddConstraint(largeMapBerriesID, avoidPlayerIsland);
      addObjectLocsPerPlayer(largeMapBerriesID, false, 1 * getMapAreaSizeFactor(), 100.0, -1.0, avoidBerriesMeters);
   }

   generateLocs("berries locs");

   // Bonus stuff.
   int bonusGoldID = rmObjectDefCreate("bonus gold");
   rmObjectDefAddItem(bonusGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidWater);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefAddConstraint(bonusGoldID, avoidPlayerIsland);
   addObjectLocsPerPlayer(bonusGoldID, false, xsRandInt(2, 4) * getMapSizeBonusFactor(), 70.0, -1.0, avoidGoldMeters);

   generateLocs("bonus gold locs");

   // Relics.
   float avoidRelicMeters = 80.0;

   int relicNumPerPlayer = 3 * getMapAreaSizeFactor();
   
   int numRelicsPerPlayer = min(relicNumPerPlayer * cNumberPlayers, cMaxRelics) / cNumberPlayers;

   int relicID = rmObjectDefCreate("relic");
   rmObjectDefAddItem(relicID, cUnitTypeRelic, 1);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidAll);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidWater);
   rmObjectDefAddConstraint(relicID, avoidPlayerIsland);
   addObjectLocsPerPlayer(relicID, false, numRelicsPerPlayer, 80.0, -1.0, avoidRelicMeters);

   generateLocs("relic locs");

   rmSetProgress(0.7);

   // Forests.
   float avoidForestMeters = 30.0;

   int forestDefID = rmAreaDefCreate("forest");
   rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(60), rmTilesToAreaFraction(80));
   rmAreaDefSetForestType(forestDefID, cForestAtlanteanLush);
   rmAreaDefSetAvoidSelfDistance(forestDefID, avoidForestMeters);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidWater4);
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
   // rmAreaDefAddConstraint(forestDefID, vDefaultAvoidOwnerPaths, 0.0);
   // rmAreaDefSetConstraintBuffer(forestDefID, 0.0, 6.0);

   // Build for each player in the team area.
   buildAreaDefInTeamAreas(forestDefID, 15 * getMapAreaSizeFactor());

   // Stragglers.
   placeStartingStragglers(cUnitTypeTreeOak);

   rmSetProgress(0.8);

   // Fish.
   int fishAvoidLand = rmCreatePassabilityDistanceConstraint(cPassabilityLand, true, 5.0);
   int forceFishNearLand = rmCreatePassabilityMaxDistanceConstraint(cPassabilityLand, true, 15.0);
   float fishDistMeters = 30.0;

   int fishID = rmObjectDefCreate("global fish");
   rmObjectDefAddItem(fishID, cUnitTypeMahi, 3, 6.0);
   // Disable the object obstruction buffer for constraints here (we only look at 1 tile when evaluating).
   rmObjectDefAddConstraint(fishID, fishAvoidLand, cObjectConstraintBufferNone);
   rmObjectDefAddConstraint(fishID, forceFishNearLand, cObjectConstraintBufferNone);
   addObjectLocsPerPlayer(fishID, false, 12 * getMapAreaSizeFactor(), 30.0, -1.0, 30.0, cBiasNone, cInAreaNone);

   generateLocs("fish locs");

   rmSetProgress(0.9);

   // Rocks.
   int rockTinyID = rmObjectDefCreate("rock tiny");
   rmObjectDefAddItem(rockTinyID, cUnitTypeRockAtlanteanTiny, 1);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefPlaceAnywhere(rockTinyID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());

   int rockSmallID = rmObjectDefCreate("rock small");
   rmObjectDefAddItem(rockSmallID, cUnitTypeRockAtlanteanSmall, 1);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefPlaceAnywhere(rockSmallID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());

   // Plants.
   int plantGrassID = rmObjectDefCreate("plant grass");
   rmObjectDefAddItem(plantGrassID, cUnitTypePlantAtlanteanGrass, 1);
   rmObjectDefAddConstraint(plantGrassID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantGrassID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefPlaceAnywhere(plantGrassID, 0, 35 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantShrubID = rmObjectDefCreate("plant shrub");
   rmObjectDefAddItem(plantShrubID, cUnitTypePlantAtlanteanShrub, 1);
   rmObjectDefAddConstraint(plantShrubID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantShrubID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefPlaceAnywhere(plantShrubID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantFernID = rmObjectDefCreate("plant fern");
   rmObjectDefAddItemRange(plantFernID, cUnitTypePlantAtlanteanFern, 1, 2, 0.0, 4.0);
   rmObjectDefAddConstraint(plantFernID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantFernID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefPlaceAnywhere(plantFernID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantWeedsID = rmObjectDefCreate("plant weeds");
   rmObjectDefAddItemRange(plantWeedsID, cUnitTypePlantAtlanteanWeeds, 1, 3, 0.0, 4.0);
   rmObjectDefAddConstraint(plantWeedsID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantWeedsID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefPlaceAnywhere(plantWeedsID, 0, 15 * cNumberPlayers * getMapAreaSizeFactor());
   
   int flowersID = rmObjectDefCreate("flowers");
   rmObjectDefAddItemRange(flowersID, cUnitTypeFlowers, 1, 3, 0.0, 4.0);
   rmObjectDefAddConstraint(flowersID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(flowersID, vDefaultEmbellishmentAvoidWater);
   rmObjectDefPlaceAnywhere(flowersID, 0, 8 * cNumberPlayers * getMapAreaSizeFactor());

   // Seaweed.
   int seaweedID = rmObjectDefCreate("seaweed");
   rmObjectDefAddItem(seaweedID, cUnitTypeSeaweed, 3, 4.0);
   rmObjectDefAddConstraint(seaweedID, rmCreatePassabilityDistanceConstraint(cPassabilityLand, true, 2.5));
   rmObjectDefAddConstraint(seaweedID, rmCreatePassabilityMaxDistanceConstraint(cPassabilityLand, true, 5.0));
   rmObjectDefPlaceAnywhere(seaweedID, 0, 50 * cNumberPlayers * getMapAreaSizeFactor());

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeHawk, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   rmSetProgress(1.0);
}
