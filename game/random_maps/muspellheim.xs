include "lib2/rm_core.xs";
include "lib2/rm_connections.xs";

void generate()
{
   rmSetProgress(0.0);

   // Define mixes.
   int baseMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.1, 5, 0.5);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainHadesDirt1, 2.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainHadesDirt2, 1.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainHadesDirtRocks1, 2.0);

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
   float placementRadius = 0.35;
   rmSetTeamSpacingModifier(0.875);
   rmPlacePlayersOnCircle(placementRadius);

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCivFromCulture(cCultureNorse);

   // Lighting.
   rmSetLighting(cLightingSetRmMuspelheim01);

   rmSetProgress(0.1);

   // Global elevation.
   rmAddGlobalHeightNoise(cNoiseFractalSum, 10.0, 0.025, 4, 0.5);

   // Create blocking center.
   int centerID = rmAreaCreate("center");
   rmAreaSetSize(centerID, 0.4);
   rmAreaSetLoc(centerID, cCenterLoc);
   rmAreaBuild(centerID);

   int avoidCenter = rmCreateAreaDistanceConstraint(centerID, 1.0);
   int forceInCenter = rmCreateAreaConstraint(centerID);

   // Create center mountain.
   int fakeMountainID = rmAreaCreate("fake mountain");
   rmAreaSetSize(fakeMountainID, rmRadiusToAreaFraction(rmXFractionToMeters(placementRadius) - 35.0));
   rmAreaSetLoc(fakeMountainID, cCenterLoc);
   rmAreaAddConstraint(fakeMountainID, createPlayerLocDistanceConstraint(35.0));
   rmAreaBuild(fakeMountainID);

   rmSetProgress(0.2);

   // Paths.
   int pathClassID = rmClassCreate();

   int pathAreaDefID = rmAreaDefCreate("path area def");
   rmAreaDefSetHeight(pathAreaDefID, 0.0);
   rmAreaDefAddHeightConstraint(pathAreaDefID, rmCreateAreaConstraint(fakeMountainID));
   int blendIdx = rmAreaDefAddHeightBlend(pathAreaDefID, cBlendAll, cFilter5x5Box, 5, 3, false, true);
   rmAreaDefAddHeightBlendConstraint(pathAreaDefID, blendIdx, rmCreateAreaEdgeConstraint(fakeMountainID));
   rmAreaDefAddHeightBlendExpansionConstraint(pathAreaDefID, blendIdx, vDefaultAvoidImpassableLand);
   rmAreaDefSetHeightNoise(pathAreaDefID, cNoiseFractalSum, 5.0, 0.15);
   rmAreaDefAddToClass(pathAreaDefID, pathClassID);

   int pathDefID = rmPathDefCreate("path def");
   rmPathDefSetCostNoise(pathDefID, 0.0, 15.0);

   createPlayerToAreaConnections("player connection", pathDefID, pathAreaDefID, fakeMountainID, 30.0 + (5.0 * getMapSizeBonusFactor()));

   // Fill up the fake mountain area with cliffs until we have no more space.
   int mountainClassID = rmClassCreate();

   int mountainDefID = rmAreaDefCreate("mountain area");
   rmAreaDefSetSize(mountainDefID, 1.0);

   rmAreaDefSetCoherence(mountainDefID, 0.5);

   rmAreaDefSetHeightRelative(mountainDefID, 5.0);
   rmAreaDefAddHeightBlend(mountainDefID, cBlendAll, cFilter5x5Gaussian);

   rmAreaDefAddConstraint(mountainDefID, rmCreateClassDistanceConstraint(pathClassID, 1.0));
   rmAreaDefAddConstraint(mountainDefID, rmCreateClassDistanceConstraint(mountainClassID, 1.0));
   rmAreaDefAddConstraint(mountainDefID, rmCreateAreaConstraint(fakeMountainID));
   rmAreaDefAddToClass(mountainDefID, mountainClassID);

   rmAreaDefSetCliffType(mountainDefID, cCliffHadesLava);
   // rmAreaDefSetCliffSideRadius(mountainDefID, 0, 2);
   // rmAreaDefSetCliffLayerPaint(mountainDefID, cCliffLayerInside, false);
   rmAreaDefSetCliffLayerPaint(mountainDefID, cCliffLayerInnerSideClose, false);
   rmAreaDefSetCliffLayerPaint(mountainDefID, cCliffLayerInnerSideFar, false);
   // Inside is fire, outside are rocks.
   rmAreaDefSetCliffLayerEmbellishmentDensity(mountainDefID, cCliffLayerInside, 0.2);
   rmAreaDefSetCliffLayerEmbellishmentDensity(mountainDefID, cCliffLayerOuterSideClose, 0.2);
   rmAreaDefSetCliffLayerEmbellishmentDensity(mountainDefID, cCliffLayerOuterSideFar, 0.2);

   while(true)
   {
      int mountainID = rmAreaDefCreateArea(mountainDefID);
      if(rmAreaFindOriginLoc(mountainID) == false)
      {
         rmAreaSetFailed(mountainID);
         break;
      }

      rmAreaBuild(mountainID);
   }

   // KotH.
   placeKotHObjects();

   rmSetProgress(0.3);

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
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidImpassableLand);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidCorner40);

   int secondSettlementID = rmObjectDefCreate("second settlement");
   rmObjectDefAddItem(secondSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidImpassableLand);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidCorner40);

   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(firstSettlementID, false, 1, 60.0, 80.0, cSettlementDist1v1, cBiasBackward);
      addSimObjectLocsPerPlayerPair(secondSettlementID, false, 1, 80.0, 120.0, cSettlementDist1v1, cBiasAggressive);
   }
   else
   {
      addObjectLocsPerPlayer(firstSettlementID, false, 1, 60.0, 80.0, cCloseSettlementDist, cBiasBackward | cBiasAllyInside);
      addObjectLocsPerPlayer(secondSettlementID, false, 1, 70.0, 90.0, cFarSettlementDist, cBiasAggressive | cBiasAllyOutside);
   }

   // Other map sizes settlements.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      int bonusSettlementID = rmObjectDefCreate("bonus settlement");
      rmObjectDefAddItem(bonusSettlementID, cUnitTypeSettlement, 1);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidEdge);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidImpassableLand);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidCorner40);
      addObjectLocsPerPlayer(bonusSettlementID, false, 1 * getMapAreaSizeFactor(), 90.0, -1.0, 80.0);
   }

   generateLocs("settlement locs");

   rmSetProgress(0.4);

   // Create random pits.
   int pitAvoidBuildings = rmCreateTypeDistanceConstraint(cUnitTypeBuilding, 20.0);

   int pitDefID = rmAreaDefCreate("pit def");

   rmAreaDefSetCliffType(pitDefID, cCliffHadesLava);
   rmAreaDefSetCliffSideRadius(pitDefID, 0, 2);

   // We only want lava inside, do not paint inner side.
   rmAreaDefSetCliffLayerPaint(pitDefID, cCliffLayerInnerSideClose, false);
   rmAreaDefSetCliffLayerPaint(pitDefID, cCliffLayerInnerSideFar, false);
   // Inside is fire, outside are rocks.
   rmAreaDefSetCliffLayerEmbellishmentDensity(pitDefID, cCliffLayerInside, 0.5);
   rmAreaDefSetCliffLayerEmbellishmentDensity(pitDefID, cCliffLayerOuterSideClose, 0.2);
   rmAreaDefSetCliffLayerEmbellishmentDensity(pitDefID, cCliffLayerOuterSideFar, 0.2);

   rmAreaDefSetHeightNoise(pitDefID, cNoiseFractalSum, 20.0, 0.2, 1);

   int numGlobalPits = 3 * cNumberPlayers * getMapAreaSizeFactor();
   float pitMinSize = rmTilesToAreaFraction(75);
   float pitMaxSize = rmTilesToAreaFraction(150);

   for(int i = 1; i <= numGlobalPits; i++)
   {
      int pitID = rmAreaDefCreateArea(pitDefID);
      rmAreaSetSize(pitID, xsRandFloat(pitMinSize, pitMaxSize));

      rmAreaSetHeightRelative(pitID, 10.0);

      rmAreaAddConstraint(pitID, avoidCenter);
      rmAreaAddConstraint(pitID, pitAvoidBuildings);
      rmAreaAddConstraint(pitID, vDefaultAvoidImpassableLand16);

      rmAreaSetOriginConstraintBuffer(pitID, 10.0);

      rmAreaBuild(pitID);
   }

   // Build some more as center embellishment.
   int numCenterPits = 2 * cNumberPlayers * cNumberPlayers * getMapAreaSizeFactor();
   int centerPitClassID = rmClassCreate();
   int centerPitForceInImpassableLand = rmCreatePassabilityDistanceConstraint(cPassabilityLand, true, 5.0);
   int centerPitAvoidSelf = rmCreateClassDistanceConstraint(centerPitClassID, 1.0);

   for(int i = 1; i <= numCenterPits; i++)
   {
      int pitID = rmAreaDefCreateArea(pitDefID);
      rmAreaSetSize(pitID, 2.0 * xsRandFloat(pitMinSize, pitMaxSize));

      rmAreaSetHeightRelative(pitID, 5.0);

      rmAreaSetCliffLayerPaint(pitID, cCliffLayerOuterSideClose, false);
      rmAreaSetCliffLayerPaint(pitID, cCliffLayerOuterSideFar, false);

      rmAreaAddConstraint(pitID, forceInCenter);
      rmAreaAddConstraint(pitID, centerPitForceInImpassableLand);
      rmAreaAddConstraint(pitID, centerPitAvoidSelf);
      rmAreaAddToClass(pitID, centerPitClassID);

      rmAreaBuild(pitID);
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
   addObjectLocsPerPlayer(startingGoldID, false, 1, cStartingGoldMinDist, cStartingGoldMaxDist, cStartingObjectAvoidanceMeters, cBiasNotAggressive);

   generateLocs("starting gold locs");

   // Starting hunt.
   int startingHuntID = rmObjectDefCreate("starting hunt");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeAurochs, xsRandInt(3, 4));
   }
   else
   {
      rmObjectDefAddItem(startingHuntID, cUnitTypeBoar, xsRandInt(4, 5));
   }
   rmObjectDefAddConstraint(startingHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(startingHuntID, vDefaultForceInTowerLOS);
   addObjectLocsPerPlayer(startingHuntID, false, 1, cStartingHuntMinDist, cStartingHuntMaxDist, cStartingObjectAvoidanceMeters);

   // Chicken.
   int startingChickenID = rmObjectDefCreate("starting chicken");
   rmObjectDefAddItem(startingChickenID, cUnitTypeChickenEvil, xsRandInt(6, 10));
   rmObjectDefAddConstraint(startingChickenID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidImpassableLand);
   addObjectLocsPerPlayer(startingChickenID, false, 1, cStartingChickenMinDist, cStartingChickenMaxDist, cStartingObjectAvoidanceMeters);

   // Herdables.
   int startingHerdID = rmObjectDefCreate("starting herd");
   rmObjectDefAddItem(startingHerdID, cUnitTypeGoat, xsRandInt(2, 3));
   rmObjectDefAddConstraint(startingHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidImpassableLand);
   addObjectLocsPerPlayer(startingHerdID, true, 1, cStartingHerdMinDist, cStartingHerdMaxDist);

   generateLocs("starting food locs");

   rmSetProgress(0.6);

   // Gold.
   float avoidGoldMeters = 50.0;

   // Close gold.
   int closeGoldID = rmObjectDefCreate("close gold");
   rmObjectDefAddItem(closeGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeGoldID, 50.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeGoldID, false, 1, 50.0, 60.0, avoidGoldMeters, cBiasForward);
   }
   else
   {
      addObjectLocsPerPlayer(closeGoldID, false, 1, 50.0, 60.0, avoidGoldMeters);
   }

   // Bonus gold.
   int bonusGoldID = rmObjectDefCreate("bonus gold");
   rmObjectDefAddItem(bonusGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidCorner40);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(bonusGoldID, 70.0);

   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusGoldID, false, xsRandInt(2, 3) * getMapAreaSizeFactor(), 70.0, -1.0, avoidGoldMeters);
   }
   else
   {
      addObjectLocsPerPlayer(bonusGoldID, false, xsRandInt(2, 3) * getMapAreaSizeFactor(), 70.0, -1.0, avoidGoldMeters);
   }

   generateLocs("gold locs");

   // Hunt.
   float avoidHuntMeters = 30.0;

   // Close hunt 1.
   int closeHunt1ID = rmObjectDefCreate("close hunt 1");
   rmObjectDefAddItem(closeHunt1ID, cUnitTypeDeer, xsRandInt(4, 8));
   rmObjectDefAddConstraint(closeHunt1ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHunt1ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHunt1ID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHunt1ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHunt1ID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeHunt1ID, 50.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeHunt1ID, false, 1, 50.0, 80.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(closeHunt1ID, false, 1, 50.0, 80.0, avoidHuntMeters);
   }

   // Close hunt 2.
   int closeHunt2ID = rmObjectDefCreate("close hunt 2");
   rmObjectDefAddItem(closeHunt2ID, cUnitTypeBoar, xsRandInt(2, 5));
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(closeHunt2ID, cUnitTypeAurochs, xsRandInt(2, 4));
   }
   rmObjectDefAddConstraint(closeHunt2ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHunt2ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHunt2ID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHunt2ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHunt2ID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeHunt2ID, 50.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeHunt2ID, false, 1, 50.0, 80.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(closeHunt2ID, false, 1, 50.0, 80.0, avoidHuntMeters);
   }

   // Bonus hunt.
   int bonusHuntID = rmObjectDefCreate("bonus hunt");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(bonusHuntID, cUnitTypeAurochs, xsRandInt(2, 4));
   }
   else
   {
      rmObjectDefAddItem(bonusHuntID, cUnitTypeBoar, xsRandInt(2, 5));
   }
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(bonusHuntID, 75.0);
   addObjectLocsPerPlayer(bonusHuntID, false, 1, 80.0, -1.0, avoidHuntMeters);

   // Other map sizes hunt.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      float largeMapHuntFloat = xsRandFloat(0.0, 1.0);
      int largeMapHuntID = rmObjectDefCreate("large map hunt");
      if(largeMapHuntFloat < 1.0 / 3.0)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeDeer, xsRandInt(6, 12));
      }
      else if(largeMapHuntFloat < 2.0 / 3.0)
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeAurochs, xsRandInt(2, 4));
      }
      else
      {
         rmObjectDefAddItem(largeMapHuntID, cUnitTypeBoar, xsRandInt(2, 5));
      }

      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidImpassableLand);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidSettlementRange);
      addObjectDefPlayerLocConstraint(largeMapHuntID, 100.0);
      addObjectLocsPerPlayer(largeMapHuntID, false, 1 * getMapSizeBonusFactor(), 100.0, -1.0, avoidHuntMeters);
   }

   generateLocs("hunt locs");

   rmSetProgress(0.7);

   // Herdables.
   float avoidHerdMeters = 50.0;

   int closeHerdID = rmObjectDefCreate("close herd");
   rmObjectDefAddItem(closeHerdID, cUnitTypeGoat, xsRandInt(1, 2));
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidTowerLOS);
   addObjectLocsPerPlayer(closeHerdID, false, 1, 50.0, 70.0, avoidHerdMeters);

   int bonusHerdID = rmObjectDefCreate("bonus herd");
   rmObjectDefAddItem(bonusHerdID, cUnitTypeGoat, xsRandInt(1, 3));
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidTowerLOS);
   addObjectLocsPerPlayer(bonusHerdID, false, xsRandInt(2, 3) * getMapAreaSizeFactor(), 70.0, -1.0, avoidHerdMeters);

   generateLocs("herd locs");

   // Predators.
   float avoidPredatorMeters = 40.0;

   int predatorID = objectDefCreateTracked("predator");
   rmObjectDefAddItem(predatorID, cUnitTypeBear, xsRandInt(2, 3));
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidImpassableLand);
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
   rmObjectDefAddConstraint(relicID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(relicID, 70.0);
   addObjectLocsPerPlayer(relicID, false, 2 * getMapAreaSizeFactor(), 70.0, -1.0, avoidRelicMeters);

   generateLocs("relic locs");

   rmSetProgress(0.8);

   // Forests.
   float avoidForestMeters = 20.0;

   int forestDefID = rmAreaDefCreate("forest");
   rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(60), rmTilesToAreaFraction(80));
   rmAreaDefSetForestType(forestDefID, cForestHades);
   rmAreaDefSetAvoidSelfDistance(forestDefID, avoidForestMeters);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidImpassableLand16);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidTownCenter);

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
   buildAreaDefInTeamAreas(forestDefID, 10 * getMapAreaSizeFactor());

   // Stragglers.
   placeStartingStragglers(cUnitTypeTreeHades);

   rmSetProgress(0.9);

   // Embellishment.
   buildAreaUnderObjectDef(startingGoldID, cTerrainHadesDirtRocks2, cTerrainHadesDirtRocks1, 6.0);
   buildAreaUnderObjectDef(closeGoldID, cTerrainHadesDirtRocks2, cTerrainHadesDirtRocks1, 6.0);
   buildAreaUnderObjectDef(bonusGoldID, cTerrainHadesDirtRocks2, cTerrainHadesDirtRocks1, 6.0);

   // Random trees.
   int randomTreeID = rmObjectDefCreate("random tree");
   rmObjectDefAddItem(randomTreeID, cUnitTypeTreeHades, 1);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidImpassableLand);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidTree);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefAddConstraint(randomTreeID, avoidCenter);
   rmObjectDefPlaceAnywhere(randomTreeID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   // Stalagmites.
   int stalagmiteAvoidAll = rmCreateTypeDistanceConstraint(cUnitTypeAll, 10.0);
   int stalagmiteAvoidBuilding = rmCreateTypeDistanceConstraint(cUnitTypeBuilding, 15.0);

   int stalagmiteID = rmObjectDefCreate("stalagmite");
   rmObjectDefAddItem(stalagmiteID, cUnitTypeStalagmite, 1);
   rmObjectDefAddConstraint(stalagmiteID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(stalagmiteID, vDefaultAvoidImpassableLand8);
   rmObjectDefAddConstraint(stalagmiteID, stalagmiteAvoidBuilding);
   rmObjectDefPlaceAnywhere(stalagmiteID, 0, 20 * cNumberPlayers * getMapAreaSizeFactor());

   int bushID = rmObjectDefCreate("bush");
   rmObjectDefAddItem(bushID, cUnitTypePlantHadesBush, 1);
   rmObjectDefAddConstraint(bushID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(bushID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefPlaceAnywhere(bushID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());

   int shrubID = rmObjectDefCreate("shrub");
   rmObjectDefAddItem(shrubID, cUnitTypePlantHadesShrub, 1);
   rmObjectDefAddConstraint(shrubID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(shrubID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefPlaceAnywhere(shrubID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());

   int fernID = rmObjectDefCreate("fern");
   rmObjectDefAddItem(fernID, cUnitTypePlantHadesFern, 1);
   rmObjectDefAddConstraint(fernID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(fernID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefPlaceAnywhere(fernID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   int weedsID = rmObjectDefCreate("weeds");
   rmObjectDefAddItem(weedsID, cUnitTypePlantHadesWeeds, 1);
   rmObjectDefAddConstraint(weedsID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(weedsID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefPlaceAnywhere(weedsID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeHarpy, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   rmSetProgress(1.0);
}
