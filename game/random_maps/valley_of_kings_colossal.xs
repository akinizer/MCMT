include "lib2/rm_core.xs";

void generate()
{
   rmSetProgress(0.0);

   // Define mixes.
   int baseMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.1, 5, 0.5);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptDirt1, 1.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptSand1, 1.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptSand2, 1.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptSand3, 1.0);

   // Map size and terrain init.
   float baseHeight = 5.0;
 // Set size.
   int playerTiles=20000;
   int cNumberNonGaiaPlayers = 10;
   if(cMapSizeCurrent == 1)
   {
      playerTiles = 30000;
   }
   int size=2.0*sqrt(cNumberNonGaiaPlayers*playerTiles/0.9);
   rmSetMapSize(size, size);
   rmInitializeMix(baseMixID, baseHeight);

   // Player placement.
   rmSetTeamSpacingModifier(0.9);
   rmPlacePlayersOnSquare(0.275, 0.275);

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCivFromCulture(cCultureEgyptian);

   // KotH.
   placeKotHObjects();

   // Lighting.
   rmSetLighting(cLightingSetRmValleyOfKings01);

   rmSetProgress(0.1);

   // Global elevation.
   rmAddGlobalHeightNoise(cNoiseFractalSum, 4.0, 0.005, 5, 1.0);

   // Valley.
   // int valleyID = rmAreaCreate("valley");
   // rmAreaSetSize(valleyID, rmRadiusToAreaFraction(smallerFractionToMeters(0.4)));
   // rmAreaSetLoc(valleyID, cCenterLoc);
   // rmAreaSetCoherenceSquare(valleyID, true);
   // rmAreaSetHeightRelative(valleyID, 1.0 - baseHeight - 1.0);
   // rmAreaAddHeightBlend(valleyID, cBlendAll, cFilter5x5Gaussian, 9, 10);
   // rmAreaBuild(valleyID);

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
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidCorner40);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidKotH);
      addObjectLocsPerPlayer(bonusSettlementID, false, 1 * getMapAreaSizeFactor(), 90.0, -1.0, 90.0);
   }

   generateLocs("settlement locs");

   rmSetProgress(0.2);

   // Cliffs.
   int cliffClassID = rmClassCreate();
   int cliffAvoidBuildings = rmCreateTypeDistanceConstraint(cUnitTypeBuilding, 25.0);

   int cliffDefID = rmAreaDefCreate("cliff def");
   rmAreaDefSetSize(cliffDefID, rmRadiusToAreaFraction(20.0));

   rmAreaDefSetBlobs(cliffDefID, 4, 8);
   rmAreaDefSetBlobDistance(cliffDefID, 10.0, 20.0);

   rmAreaDefSetCoherence(cliffDefID, 0.25);

   rmAreaDefSetHeightRelative(cliffDefID, 4.0);
   rmAreaDefSetHeightNoise(cliffDefID, cNoiseFractalSum, 10.0, 0.2, 2, 0.5);
   rmAreaDefSetHeightNoiseBias(cliffDefID, 1.0);
   rmAreaDefAddHeightBlend(cliffDefID, cBlendAll, cFilter3x3Gaussian);

   rmAreaDefSetCliffType(cliffDefID, cCliffEgyptSand);
   rmAreaDefSetCliffSideRadius(cliffDefID, 0, 2);
   rmAreaDefSetCliffEmbellishmentDensity(cliffDefID, 0.25);
   rmAreaDefSetCliffPaintInsideAsSide(cliffDefID, true);
   // rmAreaDefSetCliffRamps(cliffDefID, xsRandInt(1, 4), 0.2);

   rmAreaDefAddConstraint(cliffDefID, cliffAvoidBuildings);
   rmAreaDefAddConstraint(cliffDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefSetOriginConstraintBuffer(cliffDefID, 25.0);
   rmAreaDefSetConstraintBuffer(cliffDefID, 0.0, 8.0);
   rmAreaDefAddToClass(cliffDefID, cliffClassID);

   // Side cliffs.
   int sideCliffAvoidCliff = rmCreateClassDistanceConstraint(cliffClassID, 60.0);
   int sideCliffForceToEdge = rmCreateBoxDistanceConstraint(vectorXZ(0.1, 0.1), vectorXZ(0.9, 0.9), 1.0);
   int numSideCliffs = (10 * sqrt(max(cNumberPlayers, 1) - 1) * getMapAreaSizeFactor());

   for(int i = 0; i < numSideCliffs; i++)
   {
      int cliffID = rmAreaDefCreateArea(cliffDefID, "side cliff " + i);

      rmAreaAddOriginConstraint(cliffID, sideCliffForceToEdge);
      rmAreaAddConstraint(cliffID, sideCliffAvoidCliff);
   }

   // Inner cliffs.
   int innerCliffAvoidCliff = rmCreateClassDistanceConstraint(cliffClassID, 50.0);
   int numInnerCliffs = (6 * sqrt(max(cNumberPlayers, 1) - 1) * getMapAreaSizeFactor());

   for(int i = 0; i < numInnerCliffs; i++)
   {
      int cliffID = rmAreaDefCreateArea(cliffDefID, "inner cliff " + i);

      rmAreaAddConstraint(cliffID, innerCliffAvoidCliff);
   }

   // Build all of them concurrently.
   rmAreaBuildAll();

   rmSetProgress(0.3);

   // Starting objects.
   // Starting gold.
   int startingGoldID = rmObjectDefCreate("starting gold");
   rmObjectDefAddItem(startingGoldID, cUnitTypeMineGoldMedium, 1);
   rmObjectDefAddConstraint(startingGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(startingGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(startingGoldID, vDefaultStartingGoldAvoidTower);
   rmObjectDefAddConstraint(startingGoldID, vDefaultForceStartingGoldNearTower);
   addObjectLocsPerPlayer(startingGoldID, false, 1, cStartingGoldMinDist, cStartingGoldMaxDist, cStartingObjectAvoidanceMeters);

   generateLocs("starting gold locs");

   // Starting hunt.
   int startingHuntID = rmObjectDefCreate("starting hunt");
   rmObjectDefAddItem(startingHuntID, cUnitTypeGazelle, xsRandInt(8, 10));
   rmObjectDefAddConstraint(startingHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(startingHuntID, vDefaultForceInTowerLOS);
   addObjectLocsPerPlayer(startingHuntID, false, 1, cStartingHuntMinDist, cStartingHuntMaxDist, cStartingObjectAvoidanceMeters);

   // Berries.
   int startingBerriesID = rmObjectDefCreate("starting berries");
   rmObjectDefAddItem(startingBerriesID, cUnitTypeBerryBush, xsRandInt(6, 9), cBerryClusterRadius);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidImpassableLand);
   addObjectLocsPerPlayer(startingBerriesID, false, 1, cStartingBerriesMinDist, cStartingBerriesMaxDist, cStartingObjectAvoidanceMeters);

   // Chicken.
   int startingChickenID = rmObjectDefCreate("starting chicken");
   rmObjectDefAddItem(startingChickenID, cUnitTypeChicken, xsRandInt(6, 9));
   rmObjectDefAddConstraint(startingChickenID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingChickenID, vDefaultFoodAvoidImpassableLand);
   addObjectLocsPerPlayer(startingChickenID, false, 1, cStartingChickenMinDist, cStartingChickenMaxDist, cStartingObjectAvoidanceMeters);

   // Herdables.
   int startingHerdID = rmObjectDefCreate("starting herd");
   rmObjectDefAddItem(startingHerdID, cUnitTypeGoat, xsRandInt(2, 4));
   rmObjectDefAddConstraint(startingHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidImpassableLand);
   addObjectLocsPerPlayer(startingHerdID, true, 1, cStartingHerdMinDist, cStartingHerdMaxDist);

   generateLocs("starting food locs");

   rmSetProgress(0.4);

   // Gold.
   float avoidGoldMeters = 50.0;

   // Medium gold.
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
      addSimObjectLocsPerPlayerPair(closeGoldID, false, 2, 50.0, 70.0, avoidGoldMeters);
   }
   else
   {
      addObjectLocsPerPlayer(closeGoldID, false, 2, 50.0, 70.0, avoidGoldMeters);
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
   addObjectDefPlayerLocConstraint(bonusGoldID, 80.0);

   if(gameIs1v1() == true)
   {
      addObjectLocsPerPlayer(bonusGoldID, false, 2 * getMapAreaSizeFactor(), 80.0, -1.0, avoidGoldMeters);
   }
   else
   {
      addObjectLocsPerPlayer(bonusGoldID, false, 2 * getMapAreaSizeFactor(), 80.0, -1.0, avoidGoldMeters);
   }

   generateLocs("gold locs");

   // Hunt.
   float avoidHuntMeters = 50.0;

   // Close hunt.
   int closeHuntID = rmObjectDefCreate("close hunt");
   rmObjectDefAddItem(closeHuntID, cUnitTypeBoar, xsRandInt(4, 6));
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeHuntID, 50.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeHuntID, false, 1, 50.0, 70.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(closeHuntID, false, 1, 50.0, 70.0, avoidHuntMeters);
   }

   // Bonus hunt 1.
   int bonusHunt1ID = rmObjectDefCreate("bonus hunt 1");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(bonusHunt1ID, cUnitTypeElephant, xsRandInt(2, 3));
   }
   else
   {
      rmObjectDefAddItem(bonusHunt1ID, cUnitTypeBoar, xsRandInt(5, 7));
   }
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHunt1ID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(bonusHunt1ID, 70.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusHunt1ID, false, 1, 70.0, -1.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(bonusHunt1ID, false, 1, 70.0, -1.0, avoidHuntMeters);
   }

   // Bonus hunt 2.
   int bonusHunt2ID = rmObjectDefCreate("bonus hunt 2");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(bonusHunt2ID, cUnitTypeGazelle, xsRandInt(10, 12));
   }
   else
   {
      rmObjectDefAddItem(bonusHunt2ID, cUnitTypeRhinoceros, xsRandInt(3, 4));
   }
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHunt2ID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(bonusHunt2ID, 70.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusHunt2ID, false, 1, 70.0, -1.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(bonusHunt2ID, false, 1, 70.0, -1.0, avoidHuntMeters);
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
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeRhinoceros, xsRandInt(2, 4));
            if (xsRandBool(0.5) == true)
            {
               rmObjectDefAddItem(largeMapHuntID, cUnitTypeGazelle, xsRandInt(1, 4));
            }
         }
         else if(largeMapHuntFloat < 2.0 / 3.0)
         {
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeElephant, xsRandInt(1, 3));
         }
         else
         {
            rmObjectDefAddItem(largeMapHuntID, cUnitTypeBoar, xsRandInt(3, 5));
         }

         rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidEdge);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidAll);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultFoodAvoidImpassableLand);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidTowerLOS);
         rmObjectDefAddConstraint(largeMapHuntID, vDefaultAvoidSettlementRange);
         addObjectDefPlayerLocConstraint(largeMapHuntID, 100.0);
         addObjectLocsPerPlayer(largeMapHuntID, false, 1, 100.0, -1.0, avoidHuntMeters);
      }
   }

   generateLocs("hunt locs");

   rmSetProgress(0.5);

   // Herdables.
   float avoidHerdMeters = 50.0;

   int closeHerdID = rmObjectDefCreate("close herd");
   rmObjectDefAddItem(closeHerdID, cUnitTypeGoat, 2);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidTowerLOS);
   addObjectLocsPerPlayer(closeHerdID, false, 2, 50.0, 70.0, avoidHerdMeters);

   int bonusHerdID = rmObjectDefCreate("bonus herd");
   rmObjectDefAddItem(bonusHerdID, cUnitTypeGoat, 2);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidTowerLOS);
   addObjectLocsPerPlayer(bonusHerdID, false, 3 * getMapAreaSizeFactor(), 70.0, -1.0, avoidHerdMeters);

   generateLocs("herd locs");

   // Predators.
   float avoidPredatorMeters = 50.0;

   int predatorID = rmObjectDefCreate("predator");
   rmObjectDefAddItem(predatorID, cUnitTypeLion, xsRandInt(2, 3));
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(predatorID, 80.0);
   addObjectLocsPerPlayer(predatorID, false, xsRandInt(1, 2) * getMapAreaSizeFactor(), 80.0, -1.0, avoidPredatorMeters);

   generateLocs("predator locs");

   rmSetProgress(0.6);

   // Relics.
   float avoidRelicMeters = 80.0;

   int relicNumPerPlayer = 3 * getMapAreaSizeFactor();
   int numRelicsPerPlayer = min(relicNumPerPlayer * cNumberPlayers, cMaxRelics) / cNumberPlayers;

   int relicSiteID = rmObjectDefCreate("shrine site");
   rmObjectDefAddConstraint(relicSiteID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(relicSiteID, vDefaultAvoidCollideable8); // Don't avoid cliff embellishment stuff.
   rmObjectDefAddConstraint(relicSiteID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(relicSiteID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(relicSiteID, rmCreatePassabilityDistanceConstraint(cPassabilityLand, false, 3.0), cObjectConstraintBufferNone);
   rmObjectDefAddConstraint(relicSiteID, rmCreatePassabilityMaxDistanceConstraint(cPassabilityLand, false, 5.0), cObjectConstraintBufferNone);
   addObjectDefPlayerLocConstraint(relicSiteID, 80.0);
   addObjectLocsPerPlayer(relicSiteID, false, numRelicsPerPlayer, 80.0, -1.0, avoidRelicMeters);

   generateLocs("relic locs", true, false, false, false);

   // Go full tryhard and compare against each cliff's origin tile to get the center.
   int numRelics = rmLocGenGetNumberLocs();

   int[] cliffAreaIDs = rmAreaDefGetCreatedAreas(cliffDefID);
   int numCliffAreas = cliffAreaIDs.size();

   if(numCliffAreas > 0)
   {
      for(int i = 0; i < numRelics; i++)
      {
         vector objectLoc = rmLocGenGetLoc(i);

         // Find the nearest cliff area.
         float closestDistSqr = cMaxFloat;
         int closestAreaID = cInvalidID;
         for(int c = 0; c < numCliffAreas; c++) // You wish this was C++.
         {
            vector closestLoc = rmAreaGetClosestLoc(cliffAreaIDs[c], objectLoc);
            float distSqr = closestLoc.distanceSqr(objectLoc);
            if(distSqr < closestDistSqr)
            {
               closestDistSqr = distSqr;
               // Usually we would do this through the index but it's XS so we can't declare it before the loop.
               // (And I don't want to use while().)
               closestAreaID = cliffAreaIDs[c];
            }
         }

         vector cliffLoc = rmAreaGetLoc(closestAreaID);

         // Get the direction.
         vector dir = objectLoc - cliffLoc;
         float angle = atan2(dir.z, dir.x);

         // TODO Define as object def outside of the loop.
         int shrineID = rmObjectCreate("shrine " + i);
         rmObjectAddItem(shrineID, cUnitTypeShrine);
         rmObjectSetItemRotation(shrineID, 0, cItemRotateCustom, angle);
         rmObjectPlaceAtLoc(shrineID, 0, objectLoc);

         // Take the actual loc we placed the shrine at.
         objectLoc = rmObjectGetCentroidLoc(shrineID);

         vector shrineMeters = rmFractionToMeters(objectLoc);
         
         vector rightStatueMeters = shrineMeters.translateXZ(5.0, angle + 0.5 * cPi);
         vector leftStatueMeters = shrineMeters.translateXZ(5.0, angle - 0.5 * cPi);

         int statueID = rmObjectDefCreate("statue " + i);
         rmObjectDefAddItem(statueID, cUnitTypeStatueMajorGod);
         // Those are rotated differently so we need to offset slightly.
         rmObjectDefSetItemRotation(statueID, 0, cItemRotateCustom, angle - cPiOver2);
         rmObjectDefPlaceAtLoc(statueID, 0, rmMetersToFraction(rightStatueMeters));
         rmObjectDefPlaceAtLoc(statueID, 0, rmMetersToFraction(leftStatueMeters));

         vector relicMeters = shrineMeters.translateXZ(5.0, angle + xsRandFloat(-0.2, 0.2) * cPi);

         int relicID = rmObjectDefCreate("relic " + i);
         rmObjectDefAddItem(relicID, cUnitTypeRelic, 1);
         rmObjectDefPlaceAtLoc(relicID, 0, rmMetersToFraction(relicMeters));
      }
   }

   resetLocGen();

   rmSetProgress(0.7);

// Forests.
   float avoidForestMeters = 30.0;

   int forestDefID = rmAreaDefCreate("forest");
   rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(50), rmTilesToAreaFraction(60));
   rmAreaDefSetForestType(forestDefID, cForestEgyptPalmMix);
   rmAreaDefSetAvoidSelfDistance(forestDefID, avoidForestMeters);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidCollideable8);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidImpassableLand);
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
   // Force near cliffs.
   rmAreaDefAddConstraint(forestDefID, rmCreatePassabilityMaxDistanceConstraint(cPassabilityLand, false, 10.0));

   // Avoid the owner paths to prevent forests from closing off resources.
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidOwnerPaths, 0.0);
   // rmAreaDefSetConstraintBuffer(forestDefID, 0.0, 6.0);

   // Build for each player in the team area.
   buildAreaDefInTeamAreas(forestDefID, 9 * getMapAreaSizeFactor());

   // Stragglers.
   placeStartingStragglers(cUnitTypeTreePalm);

   rmSetProgress(0.8);

   // Beautification.
   // Gold areas.
   buildAreaUnderObjectDef(startingGoldID, cTerrainEgyptDirtRocks2, cTerrainEgyptDirtRocks1, 6.0);
   buildAreaUnderObjectDef(closeGoldID, cTerrainEgyptDirtRocks2, cTerrainEgyptDirtRocks1, 6.0);
   buildAreaUnderObjectDef(bonusGoldID, cTerrainEgyptDirtRocks2, cTerrainEgyptDirtRocks1, 6.0);

   // Berries areas.
   buildAreaUnderObjectDef(startingBerriesID, cTerrainEgyptGrass2, cTerrainEgyptGrassDirt2, 10.0);
   
   rmSetProgress(0.9);

   // Random trees.
   int randomTreeID = rmObjectDefCreate("random tree");
   rmObjectDefAddItem(randomTreeID, cUnitTypeTreePalm, 1);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidImpassableLand);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidTree);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefPlaceAnywhere(randomTreeID, 0, 5 * cNumberPlayers * getMapAreaSizeFactor());

   // Plants.
   int plantBushID = rmObjectDefCreate("plant bush");
   rmObjectDefAddItem(plantBushID, cUnitTypePlantDeadBush, 1);
   rmObjectDefAddConstraint(plantBushID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantBushID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefPlaceAnywhere(plantBushID, 0, 40 * cNumberPlayers * getMapAreaSizeFactor());

   int plantShrubID = rmObjectDefCreate("plant shrub");
   rmObjectDefAddItem(plantShrubID, cUnitTypePlantDeadShrub, 1);
   rmObjectDefAddConstraint(plantShrubID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantShrubID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefPlaceAnywhere(plantShrubID, 0, 40 * cNumberPlayers * getMapAreaSizeFactor());

   int plantFernID = rmObjectDefCreate("plant fern");
   rmObjectDefAddItemRange(plantFernID, cUnitTypePlantDeadFern, 1);
   rmObjectDefAddConstraint(plantFernID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantFernID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefPlaceAnywhere(plantFernID, 0, 40 * cNumberPlayers * getMapAreaSizeFactor());

   int plantWeedsID = rmObjectDefCreate("plant weeds");
   rmObjectDefAddItemRange(plantWeedsID, cUnitTypePlantDeadWeeds, 1);
   rmObjectDefAddConstraint(plantWeedsID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantWeedsID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefPlaceAnywhere(plantWeedsID, 0, 40 * cNumberPlayers * getMapAreaSizeFactor());

   // Rocks.
   int rockTinyID = rmObjectDefCreate("rock tiny");
   rmObjectDefAddItemRange(rockTinyID, cUnitTypeRockEgyptTiny, 1);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefPlaceAnywhere(rockTinyID, 0, 50 * cNumberPlayers * getMapAreaSizeFactor());

   int rockSmallID = rmObjectDefCreate("rock small");
   rmObjectDefAddItemRange(rockSmallID, cUnitTypeRockEgyptSmall, 1);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefPlaceAnywhere(rockSmallID, 0, 50 * cNumberPlayers * getMapAreaSizeFactor());
   
   // Sand VFX.
   int sandDriftPlainID = rmObjectDefCreate("sand drift plain");
   rmObjectDefAddItem(sandDriftPlainID, cUnitTypeVFXSandDriftPlain, 1);
   rmObjectDefAddConstraint(sandDriftPlainID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(sandDriftPlainID, vDefaultAvoidTowerLOS);
   rmObjectDefPlaceAnywhere(sandDriftPlainID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeVulture, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   rmSetProgress(1.0);
}
