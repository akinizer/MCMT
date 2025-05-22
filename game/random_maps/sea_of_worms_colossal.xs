include "lib2/rm_core.xs";

void generate()
{
   rmSetProgress(0.0);

   // Define mixes.
   // This is the coast.
   int baseMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.15, 5, 0.5);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainTundraGrass2, 2.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainTundraGrass1, 1.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainTundraSnowGrass3, 1.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainTundraSnowGrass2, 2.0);

   // Water overrides.
   rmWaterTypeAddBeachLayer(cWaterTundraSeaSnow, cTerrainTundraSnowRocks2, 2.0, 2.0);
   rmWaterTypeAddBeachLayer(cWaterTundraSeaSnow, cTerrainTundraSnowRocks1, 4.0, 2.0);
   rmWaterTypeAddBeachLayer(cWaterTundraSeaSnow, cTerrainTundraSnow1, 6.0, 2.0);
   rmWaterTypeAddBeachLayer(cWaterTundraSeaSnow, cTerrainTundraSnowGrass1, 8.0);
   rmWaterTypeAddBeachLayer(cWaterTundraSeaSnow, cTerrainTundraSnowGrass2, 10.0);
   rmWaterTypeAddBeachLayer(cWaterTundraSeaSnow, cTerrainTundraSnowGrass3, 12.0);

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
   // TODO Better way of computing team spacing modifier.
   if(gameIs1v1() == true)
   {
      rmPlacePlayersOnCircle(0.35, 0.0, 0.0, 0.75 * cPi, 0.45);
   }
   else
   {
      rmSetTeamSpacingModifier(0.9);
      rmPlacePlayersOnCircle(0.375, 0.0, 0.0, 0.75 * cPi, 0.55);
   }

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Hard override for the forward angles in 1v1.
   if(gameIs1v1() == true)
   {
      // First player loc: Parallel to the x axis (negative direction).
      vDefaultPlayerLocForwardAngles[1] = cPi;
      // Second player loc: Parallel to the z axis (positive direction).
      vDefaultPlayerLocForwardAngles[2] = 0.5 * cPi;
   }

   // Mother Nature's civ.
   rmSetNatureCivFromCulture(cCultureNorse);

   // Global elevation.
   rmAddGlobalHeightNoise(cNoiseFractalSum, 5.0, 0.05, 2, 0.25);

   // Lighting.
   rmSetLighting(cLightingSetRmSeaOfWorms01);

   rmSetProgress(0.1);

   // Create the sea.
   int seaAreaID = rmAreaCreate("sea");
   rmAreaSetWaterType(seaAreaID, cWaterTundraSeaSnow);
   rmAreaSetLoc(seaAreaID, vectorXZ(0.575, 0.425));
   rmAreaSetSize(seaAreaID, 0.15);
   rmAreaSetEdgeSmoothDistance(seaAreaID, 15);
   rmAreaAddConstraint(seaAreaID, createPlayerLocDistanceConstraint(60.0));
   rmAreaBuild(seaAreaID);

   if (gameIsKotH() == true)
   {
      int islandKotHID = rmAreaCreate("koth island");
      rmAreaSetSize(islandKotHID, rmRadiusToAreaFraction(20.0 + (3 * cNumberPlayers)));
      rmAreaSetLoc(islandKotHID, vectorXZ(0.55, 0.45));
      rmAreaSetMix(islandKotHID, baseMixID);

      rmAreaSetHeight(islandKotHID, 0.5);
      rmAreaAddHeightBlend(islandKotHID, cBlendAll, cFilter5x5Gaussian, 10.0, 5);

      rmAreaSetCoherence(islandKotHID, 0.0);
      rmAreaSetEdgeSmoothDistance(islandKotHID, 15, false);

      rmAreaSetBlobs(islandKotHID, 5, 10);
      rmAreaSetBlobDistance(islandKotHID, 10.0, 20.0);
      rmAreaBuild(islandKotHID);

      int plentyID = rmObjectDefCreate(cKotHPlentyName);
      rmObjectDefAddItem(plentyID, cUnitTypePlentyVaultKOTH, 1);
      rmObjectDefAddToClass(plentyID, vKotHClassID);
      rmObjectDefPlaceAtLoc(plentyID, 0, vectorXZ(0.55, 0.45));

      // Surrounding embellishment objects/predators.
      int predatorID = rmObjectDefCreate("koth predator");
      rmObjectDefAddItem(predatorID, cUnitTypeShadePredator, 1);
      rmObjectDefAddToClass(predatorID, vKotHClassID);
      placeObjectDefInCircle(predatorID, 0, 10, 10.0, 0.0, 0.0, 0.0, vectorXZ(0.55, 0.45));
   }

   // Make sure the corner is also covered.
   int cornerSeaAreaID = rmAreaCreate("corner sea");
   rmAreaSetWaterType(cornerSeaAreaID, cWaterTundraSeaSnow);
   rmAreaSetLoc(cornerSeaAreaID, cLocCornerEast);
   rmAreaSetSize(cornerSeaAreaID, 0.2);
   rmAreaSetEdgeSmoothDistance(cornerSeaAreaID, 15, false);
   rmAreaAddHeightBlend(cornerSeaAreaID, cBlendAll, cFilter5x5Gaussian, 10.0, 5);
   rmAreaSetBlobs(cornerSeaAreaID, 10, 10);
   rmAreaSetBlobDistance(cornerSeaAreaID, 10.0, 20.0);
   rmAreaBuild(cornerSeaAreaID);
   
   // Bonus islands.
   int bonusIslandClassID = rmClassCreate();
   
   int cornerIslandID = rmAreaCreate("corner island");
   rmAreaSetMix(cornerIslandID, baseMixID);
   rmAreaSetSize(cornerIslandID, xsRandFloat(0.05, 0.06));
   rmAreaSetLoc(cornerIslandID, vectorXZ(1.0, 0.0));
   rmAreaAddToClass(cornerIslandID, bonusIslandClassID);

   rmAreaSetHeight(cornerIslandID, 0.5);
   rmAreaAddHeightBlend(cornerIslandID, cBlendAll, cFilter5x5Gaussian, 10.0, 5);

   rmAreaSetEdgeSmoothDistance(cornerIslandID, 15, false);

   rmAreaSetBlobs(cornerIslandID, 10, 10);
   rmAreaSetBlobDistance(cornerIslandID, 10.0, 20.0);

   int forceOnCornerIsland = rmCreateAreaConstraint(cornerIslandID);

   // Corner forests in teamgames.
   if(gameIs1v1() == false)
   {
      int cornerForestDefID = rmAreaDefCreate("corner forest");
      rmAreaDefSetSize(cornerForestDefID, 0.0125);
      rmAreaDefSetForestType(cornerForestDefID, cForestTundraLateAutumn);
      rmAreaDefAddConstraint(cornerForestDefID, vDefaultAvoidAll16);

      int northernForestID = rmAreaDefCreateArea(cornerForestDefID);
      rmAreaSetLoc(northernForestID, cLocCornerNorth);
      rmAreaBuild(northernForestID);

      int westernForestID = rmAreaDefCreateArea(cornerForestDefID);
      rmAreaSetLoc(westernForestID, cLocCornerWest);
      rmAreaBuild(westernForestID);

      int southernForestID = rmAreaDefCreateArea(cornerForestDefID);
      rmAreaSetLoc(southernForestID, cLocCornerSouth);
      rmAreaBuild(southernForestID);  
   }

   // Create some bonus islands.
   int numBonusIslands = cNumberPlayers * getMapAreaSizeFactor();

   int bonusIslandAvoidLand = rmCreatePassabilityDistanceConstraint(cPassabilityLand, true, 25.0 * getMapAreaSizeFactor());
   int bonusIslandAvoidBonusIsland = rmCreateClassDistanceConstraint(bonusIslandClassID, 20.0);
   int avoidBonusIsland = rmCreateClassDistanceConstraint(bonusIslandClassID, 0.1);
   int forceOnBonusIsland = rmCreateClassMaxDistanceConstraint(bonusIslandClassID, 0.0);
   
   float bonusIslandMinSize = rmTilesToAreaFraction(900);
   float bonusIslandMaxSize = rmTilesToAreaFraction(1500 * getMapAreaSizeFactor());

   for(int i = 0; i < numBonusIslands; i++)
   {
      int bonusIslandID = rmAreaCreate("bonus island " + i);
      rmAreaSetMix(bonusIslandID, baseMixID);
      rmAreaSetSize(bonusIslandID, xsRandFloat(bonusIslandMinSize, bonusIslandMaxSize));

      rmAreaSetCoherence(bonusIslandID, 0.0);
      rmAreaSetHeight(bonusIslandID, 0.5);
      rmAreaSetEdgeSmoothDistance(bonusIslandID, 20);
      rmAreaAddHeightBlend(bonusIslandID, cBlendAll, cFilter5x5Box, 5, 5);

      rmAreaAddToClass(bonusIslandID, bonusIslandClassID);
      rmAreaAddConstraint(bonusIslandID, bonusIslandAvoidLand);
      rmAreaAddConstraint(bonusIslandID, vDefaultAvoidKotH);
      rmAreaAddConstraint(bonusIslandID, bonusIslandAvoidBonusIsland);
   }

   rmAreaBuildAll();

   rmSetProgress(0.2);

   // Base beautification.
   float baseBeautificationSize = rmRadiusToAreaFraction(25.0);

   for(int i = 1; i <= cNumberPlayers; i++)
   {
      int p = vDefaultTeamPlayerOrder[i];

      int baseBeautificationAreaID = rmAreaCreate("base area beautification " + p);
      rmAreaSetLocPlayer(baseBeautificationAreaID, p);
      rmAreaSetSize(baseBeautificationAreaID, baseBeautificationSize);
      rmAreaAddTerrainLayer(baseBeautificationAreaID, cTerrainTundraGrass1, 0);
      rmAreaAddTerrainLayer(baseBeautificationAreaID, cTerrainTundraGrassDirt1, 1);
      rmAreaAddTerrainLayer(baseBeautificationAreaID, cTerrainTundraGrassDirt2, 2);
      rmAreaAddTerrainLayer(baseBeautificationAreaID, cTerrainTundraGrassDirt3, 3);
      // rmAreaAddTerrainLayer(baseBeautificationAreaID, cTerrainTundraDirt1, 4);
      rmAreaSetTerrainType(baseBeautificationAreaID, cTerrainTundraDirt1);
      rmAreaAddConstraint(baseBeautificationAreaID, vDefaultAvoidImpassableLand8);
      rmAreaBuild(baseBeautificationAreaID);
   }

   rmSetProgress(0.3);

   placeStartingTownCenters();
   
   // Starting towers.
   int startingTowerID = rmObjectDefCreate("starting tower");
   rmObjectDefAddItem(startingTowerID, cUnitTypeSentryTower, 1);
   rmObjectDefAddConstraint(startingTowerID, vDefaultAvoidAll);
   addObjectLocsPerPlayer(startingTowerID, true, 4, cStartingTowerMinDist, cStartingTowerMaxDist, cStartingTowerAvoidanceMeters);
   generateLocs("starting tower locs");

   // Settlements.
   // First settlement.
   int firstSettlementID = rmObjectDefCreate("first settlement");
   rmObjectDefAddItem(firstSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidAllWithFarm);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidSiegeShipRange);

   // Second settlement.
   int secondSettlementID = rmObjectDefCreate("second settlement");
   rmObjectDefAddItem(secondSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidAllWithFarm);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(secondSettlementID, avoidBonusIsland);
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddConstraint(secondSettlementID, rmCreatePassabilityDistanceConstraint(cPassabilityLand, false, 50.0));
   }
   else
   {
      rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidSiegeShipRange);
   }

   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(firstSettlementID, false, 1, 50.0, 70.0, cSettlementDist1v1, cBiasBackward, cLocSideSame);
      addSimObjectLocsPerPlayerPair(secondSettlementID, false, 1, 70.0, 100.0, cSettlementDist1v1, cBiasForward);
   }
   else
   {
      addObjectLocsPerPlayer(firstSettlementID, false, 1, 50.0, 70.0, cCloseSettlementDist, cBiasBackward);
      addObjectLocsPerPlayer(secondSettlementID, false, 1, 70.0, 100.0, cFarSettlementDist, cBiasAggressive);
   }

   // Other map sizes settlements.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int bonusIslandSettlementID = rmObjectDefCreate("bonus settlement");
      rmObjectDefAddItem(bonusIslandSettlementID, cUnitTypeSettlement, 1);
      rmObjectDefAddConstraint(bonusIslandSettlementID, vDefaultSettlementAvoidEdge);
      rmObjectDefAddConstraint(bonusIslandSettlementID, vDefaultSettlementAvoidAllWithFarm);
      rmObjectDefAddConstraint(bonusIslandSettlementID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(bonusIslandSettlementID, vDefaultAvoidCorner40);
      rmObjectDefAddConstraint(bonusIslandSettlementID, avoidBonusIsland);
      addObjectLocsPerPlayer(bonusIslandSettlementID, false, 1 * getMapAreaSizeFactor(), 90.0, -1.0, 80.0);
   }
   
   generateLocs("settlement locs");
   
   rmSetProgress(0.4);

   // Starting objects.
   // Starting gold.
   int startingGoldID = rmObjectDefCreate("starting gold");
   rmObjectDefAddItem(startingGoldID, cUnitTypeMineGoldMedium, 1);
   rmObjectDefAddConstraint(startingGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingGoldID, vDefaultAvoidImpassableLand16);
   rmObjectDefAddConstraint(startingGoldID, vDefaultStartingGoldAvoidTower);
   rmObjectDefAddConstraint(startingGoldID, vDefaultForceStartingGoldNearTower);
   addObjectLocsPerPlayer(startingGoldID, false, 1, cStartingGoldMinDist, cStartingGoldMaxDist, cStartingObjectAvoidanceMeters);

   generateLocs("starting gold locs");

   // Starting hunt.
   int startingHuntID = rmObjectDefCreate("starting hunt");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeBoar, 4);
   }
   else
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeAurochs, xsRandInt(3, 4));
   }
   rmObjectDefAddConstraint(startingHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHuntID, vDefaultAvoidImpassableLand16);
   addObjectLocsPerPlayer(startingHuntID, false, 1, cStartingHuntMinDist, cStartingHuntMaxDist, cStartingObjectAvoidanceMeters);
   
   // Berries.
   int startingBerriesID = rmObjectDefCreate("starting berries");
   rmObjectDefAddItem(startingBerriesID, cUnitTypeBerryBush, xsRandInt(6, 10), cBerryClusterRadius);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultAvoidImpassableLand16);
   addObjectLocsPerPlayer(startingBerriesID, false, 1, cStartingBerriesMinDist, cStartingBerriesMaxDist, cStartingObjectAvoidanceMeters);

   // Chicken.
   int startingChickenID = rmObjectDefCreate("starting chicken");
   rmObjectDefAddItem(startingChickenID, cUnitTypeChicken, xsRandInt(6, 10));
   rmObjectDefAddConstraint(startingChickenID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingChickenID, vDefaultAvoidImpassableLand16);
   addObjectLocsPerPlayer(startingChickenID, false, 1, cStartingChickenMinDist, cStartingChickenMaxDist, cStartingObjectAvoidanceMeters);

   // Herdables.
   int startingHerdID = rmObjectDefCreate("starting herd");
   rmObjectDefAddItem(startingHerdID, cUnitTypeCow, xsRandInt(2, 4));
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
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidImpassableLand20);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(closeGoldID, avoidBonusIsland);
   addObjectDefPlayerLocConstraint(closeGoldID, 50.0);
   if(gameIs1v1() == true)
   {
      // This will result in either a forward or a backward mine due to the map layout.
      addSimObjectLocsPerPlayerPair(closeGoldID, false, 1, 50.0, 70.0, avoidGoldMeters, cBiasNone, cInAreaDefault, cLocSideSame);
   }
   else
   {
      addObjectLocsPerPlayer(closeGoldID, false, 1, 50.0, 70.0, avoidGoldMeters);
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
   rmObjectDefAddConstraint(farGoldID, avoidBonusIsland);
   if(gameIs1v1() == true)
   { 
      addObjectDefPlayerLocConstraint(farGoldID, 60.0);
      addSimObjectLocsPerPlayerPair(farGoldID, false, 1, 60.0, 100.0, avoidGoldMeters, cBiasForward);
   }
   else
   {
      addObjectDefPlayerLocConstraint(farGoldID, 90.0);
      addObjectLocsPerPlayer(farGoldID, false, 1, 90.0, 130.0, avoidGoldMeters);
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
   rmObjectDefAddConstraint(bonusGoldID, avoidBonusIsland);
   addObjectDefPlayerLocConstraint(bonusGoldID, 100.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusGoldID, false, 1 * getMapSizeBonusFactor(), 100.0, -1.0, avoidGoldMeters, cBiasForward);
   }
   else
   {
      addObjectLocsPerPlayer(bonusGoldID, false, 1 * getMapSizeBonusFactor(), 100.0, -1.0, avoidGoldMeters);
   }

   generateLocs("gold locs");

   // Other map sizes gold on mainland.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int largeMapGoldID = rmObjectDefCreate("large map gold");
      rmObjectDefAddItem(largeMapGoldID, cUnitTypeMineGoldLarge, 1);
      rmObjectDefAddConstraint(largeMapGoldID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(largeMapGoldID, vDefaultGoldAvoidAll);
      rmObjectDefAddConstraint(largeMapGoldID, vDefaultAvoidImpassableLand20);
      rmObjectDefAddConstraint(largeMapGoldID, vDefaultAvoidCorner40);
      rmObjectDefAddConstraint(largeMapGoldID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(largeMapGoldID, vDefaultAvoidSettlementRange);
      rmObjectDefAddConstraint(largeMapGoldID, avoidBonusIsland);
      addObjectDefPlayerLocConstraint(largeMapGoldID, 100.0);
      addObjectLocsPerPlayer(largeMapGoldID, false, 1 * getMapSizeBonusFactor(), 100.0, -1.0, avoidGoldMeters);
   }

   generateLocs("gold locs");
   
   // Bonus island stuff.
   // Bonus settlement on bonus island.
   int bonusIslandSettlementID = rmObjectDefCreate("bonus island settlement");
   rmObjectDefAddItem(bonusIslandSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(bonusIslandSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(bonusIslandSettlementID, vDefaultSettlementAvoidAllWithFarm);
   rmObjectDefAddConstraint(bonusIslandSettlementID, vDefaultSettlementAvoidSiegeShipRange);
   rmObjectDefAddConstraint(bonusIslandSettlementID, rmCreateTypeDistanceConstraint(cUnitTypeAbstractSettlement, 45.0));
   rmObjectDefAddConstraint(bonusIslandSettlementID, forceOnCornerIsland);
   rmObjectDefPlaceAnywhere(bonusIslandSettlementID, 0, 1 * getMapAreaSizeFactor());
   
   // Bonus relics on bonus island.
   int bonusIslandRelicID = rmObjectDefCreate("bonus island relic");
   rmObjectDefAddItem(bonusIslandRelicID, cUnitTypeRelic, 1);
   rmObjectDefAddConstraint(bonusIslandRelicID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusIslandRelicID, vDefaultRelicAvoidAll);
   rmObjectDefAddConstraint(bonusIslandRelicID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusIslandRelicID, forceOnCornerIsland);
   rmObjectDefPlaceAnywhere(bonusIslandRelicID, 0, (1 + (0.5 * cNumberPlayers)) * getMapAreaSizeFactor());

   // Bonus shore hunt.
   int shoreHuntMinDist = rmCreatePassabilityDistanceConstraint(cPassabilityLand, false, 6.0);
   int shoreHuntMaxDist = rmCreatePassabilityMaxDistanceConstraint(cPassabilityLand, false, 14.0);

   int bonusIslandHuntID = rmObjectDefCreate("bonus island hunt");
   rmObjectDefAddItem(bonusIslandHuntID, cUnitTypeWalrus, xsRandInt(3, 6));
   rmObjectDefAddConstraint(bonusIslandHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(bonusIslandHuntID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(bonusIslandHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusIslandHuntID, shoreHuntMinDist, cObjectConstraintBufferNone);
   rmObjectDefAddConstraint(bonusIslandHuntID, shoreHuntMaxDist, cObjectConstraintBufferNone);
   rmObjectDefAddConstraint(bonusIslandHuntID, rmCreateTypeDistanceConstraint(cUnitTypeFoodResource, 20.0));
   rmObjectDefAddConstraint(bonusIslandHuntID, forceOnBonusIsland);
   rmObjectDefPlaceAnywhere(bonusIslandHuntID, 0, cNumberPlayers * getMapAreaSizeFactor());

   // More bonus gold on islands (randomly and unchecked).
   int bonusIslandGoldID = rmObjectDefCreate("bonus island gold");
   rmObjectDefAddItem(bonusIslandGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(bonusIslandGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusIslandGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(bonusIslandGoldID, vDefaultGoldAvoidWater);
   rmObjectDefAddConstraint(bonusIslandGoldID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(bonusIslandGoldID, rmCreateTypeDistanceConstraint(cUnitTypeGoldResource, 20.0));
   rmObjectDefAddConstraint(bonusIslandGoldID, forceOnBonusIsland);
   if(cNumberPlayers < 7)
   {
      rmObjectDefPlaceAnywhere(bonusIslandGoldID, 0, xsRandInt(2, 3) * cNumberPlayers * getMapAreaSizeFactor());
   }
   else
   {
      rmObjectDefPlaceAnywhere(bonusIslandGoldID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());
   }

   // Hunt.
   float avoidHuntMeters = 50.0;
   
   // Close hunt.
   float closeHuntFloat = xsRandFloat(0.0, 1.0);
   int closeHuntID = rmObjectDefCreate("close hunt");
   if(closeHuntFloat < 1.0 / 3.0)
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeElk, xsRandInt(5, 8));
   }
   else if(closeHuntFloat < 2.0 / 3.0)
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeCaribou, xsRandInt(5, 8));
   }
   else
   {
      rmObjectDefAddItem(closeHuntID, cUnitTypeBoar, xsRandInt(3, 4));
   }
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidImpassableLand20);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(closeHuntID, avoidBonusIsland);
   addObjectDefPlayerLocConstraint(closeHuntID, 60.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeHuntID, false, 1, 60.0, 80.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(closeHuntID, false, 1, 60.0, 100.0, avoidHuntMeters);
   }

   // Far hunt.
   float farHuntFloat = xsRandFloat(0.0, 1.0);
   int farHuntID = rmObjectDefCreate("far hunt");
   if(closeHuntFloat < 1.0 / 3.0)
   {
      rmObjectDefAddItem(farHuntID, cUnitTypeElk, xsRandInt(5, 8));
   }
   else if(closeHuntFloat < 2.0 / 3.0)
   {
      rmObjectDefAddItem(farHuntID, cUnitTypeCaribou, xsRandInt(5, 8));
   }
   else
   {
      rmObjectDefAddItem(farHuntID, cUnitTypeBoar, xsRandInt(3, 4));
   }
   rmObjectDefAddConstraint(farHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(farHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(farHuntID, vDefaultAvoidImpassableLand20);
   rmObjectDefAddConstraint(farHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(farHuntID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(farHuntID, avoidBonusIsland);
   addObjectDefPlayerLocConstraint(farHuntID, 80.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(farHuntID, false, 1, 80.0, 100.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(farHuntID, false, 1, 80.0, 120.0, avoidHuntMeters);
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
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeCaribou, xsRandInt(5, 9));
            if (xsRandBool(0.5) == true)
            {
               rmObjectDefAddItem(largeMapHuntID, cUnitTypeBoar, xsRandInt(1, 3));
            }
         }
         else if(largeMapHuntFloat < 2.0 / 3.0)
         {
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeElk, xsRandInt(3, 8));
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeCaribou, xsRandInt(2, 7));
         }
         else
         {
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeAurochs, xsRandInt(2, 5));
         }

         rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidEdge);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidAll);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidImpassableLand20);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidTowerLOS);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidSettlementRange);
         rmObjectDefAddConstraint(largeMapHuntID, avoidBonusIsland);
         addObjectDefPlayerLocConstraint(largeMapHuntID, 80.0);
         addObjectLocsPerPlayer(largeMapHuntID, false, 1, 100.0, -1.0, avoidHuntMeters);
      }
   }

   generateLocs("hunt locs");

   rmSetProgress(0.6);

   // Berries.
   float avoidBerriesMeters = 50.0;

   int berriesID = rmObjectDefCreate("berries");
   rmObjectDefAddItem(berriesID, cUnitTypeBerryBush, xsRandInt(6, 11), cBerryClusterRadius);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(berriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidImpassableLand20);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(berriesID, avoidBonusIsland);
   addObjectDefPlayerLocConstraint(berriesID, 70.0);
   addObjectLocsPerPlayer(berriesID, false, 1 * getMapSizeBonusFactor(), 80.0, -1.0, avoidBerriesMeters);

   generateLocs("berries locs");

   // Herdables.
   float avoidHerdMeters = 50.0;
  
   int closeHerdID = rmObjectDefCreate("close herd");
   rmObjectDefAddItem(closeHerdID, cUnitTypeCow, 2);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidWater);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHerdID, avoidBonusIsland);
   addObjectDefPlayerLocConstraint(closeHerdID, 50.0);
   addObjectLocsPerPlayer(closeHerdID, false, 2, 50.0, 70.0, avoidHerdMeters);

   int bonusHerdID = rmObjectDefCreate("bonus herd");
   rmObjectDefAddItem(bonusHerdID, cUnitTypeCow, 2);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidWater);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHerdID, avoidBonusIsland);
   addObjectDefPlayerLocConstraint(bonusHerdID, 70.0);
   addObjectLocsPerPlayer(bonusHerdID, false, xsRandInt(2, 3) * getMapSizeBonusFactor(), 70.0, -1.0, avoidHerdMeters);

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
   rmObjectDefAddConstraint(predatorID, avoidBonusIsland);
   addObjectDefPlayerLocConstraint(predatorID, 80.0);
   addObjectLocsPerPlayer(predatorID, false, xsRandInt(1, 2) * getMapAreaSizeFactor(), 80.0, -1.0, avoidPredatorMeters);

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
   rmObjectDefAddConstraint(relicID, avoidBonusIsland);
   addObjectDefPlayerLocConstraint(relicID, 70.0);
   addObjectLocsPerPlayer(relicID, false, 1 * getMapAreaSizeFactor(), 80.0, -1.0, avoidRelicMeters); // Only 1 relic due to bonus relics in corner

   generateLocs("relic locs");

   rmSetProgress(0.7);

   // Forests.
   float avoidForestMeters = 30.0;

   int forestDefID = rmAreaDefCreate("forest");
   rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(60), rmTilesToAreaFraction(90));
   rmAreaDefSetForestType(forestDefID, cForestTundraLateAutumn);
   rmAreaDefSetAvoidSelfDistance(forestDefID, avoidForestMeters);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidWater12);
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
   buildAreaDefInTeamAreas(forestDefID, 13 * getMapAreaSizeFactor());

   // Stragglers.
   placeStartingStragglers(cUnitTypeTreeTundra);

   rmSetProgress(0.8);

   // Fish.
   if(gameIs1v1() == true && cMapSizeCurrent == cMapSizeStandard) 
   {
      // Get closest distance to water and then place some player fish there, then some more random (but mirrored).
      int fishAvoidLand = rmCreatePassabilityDistanceConstraint(cPassabilityLand, true, 10.0);
      int fishForceNearLand = rmCreatePassabilityMaxDistanceConstraint(cPassabilityLand, true, 16.0);

      rmAddClosestLocConstraint(fishAvoidLand);
      rmAddClosestLocConstraint(fishForceNearLand);

      vector player1Loc = rmGetPlayerLoc(1);

      vector closestLoc = rmGetClosestLoc(player1Loc, rmXFractionToMeters(1.0));

      float minDist = player1Loc.distance(closestLoc);
      float minDistMeters = rmXFractionToMeters(minDist);

      float fishDistMeters = 20.0;

      int playerFishID = rmObjectDefCreate("1v1 player fish");
      rmObjectDefAddItem(playerFishID, cUnitTypeSalmon, 3, 5.0);
      rmObjectDefAddConstraint(playerFishID, fishAvoidLand, cObjectConstraintBufferNone);
      rmObjectDefAddConstraint(playerFishID, fishForceNearLand, cObjectConstraintBufferNone);
      rmObjectDefAddConstraint(playerFishID, rmCreateTypeDistanceConstraint(cUnitTypeFishResource, fishDistMeters));

      addSimObjectLocsPerPlayerPair(playerFishID, false, 2, minDistMeters, minDistMeters + 15.0, fishDistMeters, cBiasAggressive,
                          cInAreaNone, cLocSideSame);
     
      int fishID = rmObjectDefCreate("1v1 fish");
      rmObjectDefAddItem(fishID, cUnitTypeSalmon, 3, 5.0);
      rmObjectDefAddConstraint(fishID, fishAvoidLand, cObjectConstraintBufferNone);
      //rmObjectDefAddConstraint(fishID, fishForceNearLand);
      rmObjectDefAddConstraint(fishID, rmCreateTypeDistanceConstraint(cUnitTypeFishResource, fishDistMeters));
      
      addSimObjectLocsPerPlayerPair(fishID, false, xsRandInt(3, 4), 50.0, rmXFractionToMeters(0.5), fishDistMeters, cBiasNone,
                          cInAreaNone, cLocSideSame);
      
      generateLocs("fish locs");
   }
   else
   {
      // TODO Grant a spot towards 0.75/0.25 instead.

      // Just place them anywhere and without checking.
      float fishDistMeters = 25.0;

      int fishID = rmObjectDefCreate("fish");
      rmObjectDefAddItem(fishID, cUnitTypeSalmon, 3, 5.0);
      rmObjectDefAddConstraint(fishID, rmCreatePassabilityDistanceConstraint(cPassabilityLand, true, 10.0));
      rmObjectDefAddConstraint(fishID, rmCreateTypeDistanceConstraint(cUnitTypeFishResource, fishDistMeters));

      rmObjectDefPlaceAnywhere(fishID, 0, 6 * cNumberPlayers * getMapAreaSizeFactor());
   }

   rmSetProgress(0.9);
   
   // Embellishment.
   buildAreaUnderObjectDef(startingGoldID, cTerrainTundraGrassRocks2, cTerrainTundraGrassRocks1, 6.0);
   buildAreaUnderObjectDef(closeGoldID, cTerrainTundraGrassRocks2, cTerrainTundraGrassRocks1, 6.0);
   buildAreaUnderObjectDef(farGoldID, cTerrainTundraGrassRocks2, cTerrainTundraGrassRocks1, 6.0);
   buildAreaUnderObjectDef(bonusGoldID, cTerrainTundraGrassRocks2, cTerrainTundraGrassRocks1, 6.0);
   buildAreaUnderObjectDef(bonusIslandGoldID, cTerrainTundraGrassRocks2, cTerrainTundraSnowGrassRocks1, 6.0);

   buildAreaUnderObjectDef(startingBerriesID, cTerrainTundraGrass2, cTerrainTundraGrass1, 10.0);
   buildAreaUnderObjectDef(berriesID, cTerrainTundraGrass2, cTerrainTundraGrass1, 10.0);

   // Rocks.
   int rockTinyID = rmObjectDefCreate("rock tiny");
   rmObjectDefAddItem(rockTinyID, cUnitTypeRockTundraTiny, 1);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockTinyID, vDefaultAvoidImpassableLand8);
   rmObjectDefPlaceAnywhere(rockTinyID, 0, 50 * cNumberPlayers * getMapAreaSizeFactor());

   int rockSmallID = rmObjectDefCreate("rock small");
   rmObjectDefAddItem(rockSmallID, cUnitTypeRockTundraSmall, 1);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockSmallID, vDefaultAvoidImpassableLand8);
   rmObjectDefPlaceAnywhere(rockSmallID, 0, 50 * cNumberPlayers * getMapAreaSizeFactor());

   // Plants.
   int avoidTundraSnowGrass2 = rmCreateTerrainTypeDistanceConstraint(cTerrainTundraSnowGrass2, 1.0);
   int avoidTundraSnowGrass3 = rmCreateTerrainTypeDistanceConstraint(cTerrainTundraSnowGrass3, 1.0);

   int grassID = rmObjectDefCreate("grass");
   rmObjectDefAddItem(grassID, cUnitTypePlantTundraGrass, 1);
   rmObjectDefAddConstraint(grassID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(grassID, vDefaultAvoidWater8);
   rmObjectDefAddConstraint(grassID, avoidTundraSnowGrass2);
   rmObjectDefAddConstraint(grassID, avoidTundraSnowGrass3);
   rmObjectDefPlaceAnywhere(grassID, 0, 50 * cNumberPlayers * getMapAreaSizeFactor());

   int weedsID = rmObjectDefCreate("weeds");
   rmObjectDefAddItem(weedsID, cUnitTypePlantTundraWeeds, 1);
   rmObjectDefAddConstraint(weedsID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(weedsID, vDefaultAvoidWater8);
   rmObjectDefAddConstraint(weedsID, avoidTundraSnowGrass2);
   rmObjectDefAddConstraint(weedsID, avoidTundraSnowGrass3);
   rmObjectDefPlaceAnywhere(weedsID, 0, 50 * cNumberPlayers * getMapAreaSizeFactor());
   
   int shrubID = rmObjectDefCreate("shrub");
   rmObjectDefAddItem(shrubID, cUnitTypePlantTundraShrub, 1);
   rmObjectDefAddConstraint(shrubID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(shrubID, vDefaultAvoidWater8);
   rmObjectDefAddConstraint(shrubID, avoidTundraSnowGrass2);
   rmObjectDefAddConstraint(shrubID, avoidTundraSnowGrass3);
   rmObjectDefPlaceAnywhere(shrubID, 0, 50 * cNumberPlayers * getMapAreaSizeFactor());
   
   int bushID = rmObjectDefCreate("bush");
   rmObjectDefAddItem(bushID, cUnitTypePlantTundraBush, 1);
   rmObjectDefAddConstraint(bushID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(bushID, vDefaultAvoidWater8);
   rmObjectDefAddConstraint(bushID, avoidTundraSnowGrass2);
   rmObjectDefAddConstraint(bushID, avoidTundraSnowGrass3);
   rmObjectDefPlaceAnywhere(bushID, 0, 50 * cNumberPlayers * getMapAreaSizeFactor());

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeHawk, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   rmSetProgress(1.0);
}
