include "lib2/rm_core.xs";
include "lib2/rm_connections.xs";
include "lib2/rm_biomes.xs";
include "lib2/util/WeightedRandomizer.xs";

extern bool cAllowWater = true;

Biome cBiome;

const int cTilesPerPlayer = 8192;
const int cPlayerEdgeMinTiles = 15;

const int cTerrainNone = -1;
const int cTerrainLand = 0;
const int cTerrainShallowWater = 1;
const int cTerrainHybridWater = 2;
const int cTerrainDeepWater = 3;
const int cTerrainForest = 4;
const int cTerrainImpassable = 5;
// const int cTerrainUnbuildable = 6; // Not yet available beyond ice.

const int cMapShapeNone = -1;
const int cMapShapeSquare = 0;
const int cMapShapeRectangular = 1;

const int cPlacementTypeNone = -1;
const int cPlacementTypeCircular = 0;
const int cPlacementTypeSquare = 1;

const int cCenterNone = -1;
const int cCenterSubAreas = 0;
const int cCenterSubAreasPaths = 1;
const int cCenterSingleArea = 2;

// Globals. Could also move them into structs and then pass those arounds but who's got the time anyway.
// Map shape.
int cMapShape = cMapShapeNone;

// Placement.
int cPlacementType = cPlacementTypeNone;
float cPlacementRadiusFraction = 0.0;

// Edge stuff.
int cEdgeType = cTerrainNone;
int cEdgeSeparatorType = cTerrainNone;
int cEdgeSeparatorSecondaryType = cTerrainNone;
// Width of the edge in tiles.
int cEdgeTiles = 0;
// Bonus tiles that will be used to stretch the axes (may be using cEdgeTiles to compute).
int cEdgeBonusTiles = 0;
// Separator between the edge and the "non-edge" playable area, can be 0.
int cEdgeSeparatorTiles = 0;

int cEdgeClassID = cInvalidID;
int cEdgeAreaPathClassID = cInvalidID;
int cNonEdgeAreaID = cInvalidID;

int cEdgeSeparatorOuterAreaID = cInvalidID;
int cEdgeSeparatorInnerAreaID = cInvalidID;

// Center.
int cCenterVariationType = cCenterNone;
int cCenterType = cTerrainNone;
// Note that this is also used between player/team areas (even if we have no center).
int cCenterSeparatorType = cTerrainNone;
int cCenterPlayerSeparatorTiles = 0;

int cCenterFakeClassID = cInvalidID;
int cCenterFakeAreaID = cInvalidID;
int cCenterAreaClassID = cInvalidID;
int cCenterPathClassID = cInvalidID;
int cCenterSeparatorClassID = cInvalidID;

// Player/team areas.
bool cPlayerTeamAreaMakeSeparator = false;
bool cPlayerTeamAreaMakeTeamAreas = false;
int cPlayerTeamAreaClassID = cInvalidID;

// Global donut.
int cGlobalDonutType = cTerrainNone;

int cGlobalDonutPathClassID = cInvalidID;
int cGlobalDonutOuterAreaID = cInvalidID;
int cGlobalDonutInnerAreaID = cInvalidID;

// Random area features (cliffs, ponds, ...).
int cValidFeatureAreaClassID = cInvalidID;

// We paint cliffs last to make sure the embellishment doesn't get overpainted.
int[] cCliffAreasToPaint = default;

void initGlobalClasses()
{
   // Initialize all the classes here for convenience so we don't have to do it later on.
   cEdgeClassID = rmClassCreate();
   cEdgeAreaPathClassID = rmClassCreate();

   cCenterFakeClassID = rmClassCreate();
   cCenterAreaClassID = rmClassCreate();
   cCenterPathClassID = rmClassCreate();
   cCenterSeparatorClassID = rmClassCreate();

   cPlayerTeamAreaClassID = rmClassCreate();

   cGlobalDonutPathClassID = rmClassCreate();

   cValidFeatureAreaClassID = rmClassCreate();
}

bool isTerrainPassable(int terrainType = cTerrainNone)
{
   switch(terrainType)
   {
      case cTerrainShallowWater:
      case cTerrainHybridWater:
      case cTerrainLand:
      {
         return true;
      }
      case cTerrainForest:
      case cTerrainDeepWater:
      case cTerrainImpassable:
      {
         return false;
      }
   }

   // If no terrain was selected, we assume it's not passable.
   return false;
}

int randomizeMapShape()
{
   WeightedIntRandomizer randomizer;
   randomizer.addOption(cMapShapeSquare, 5);
   // Maybe some day.
   // randomizer.addOption(cMapShapeRectangular, 1);

   return randomizer.roll();
}

int randomizePlayerPlacement()
{
   WeightedIntRandomizer randomizer;
   randomizer.addOption(cPlacementTypeCircular, 5);
   // Maybe some day.
   // randomizer.addOption(cPlacementTypeSquare, 1);

   return randomizer.roll();
}

int randomizeEdgeType(bool allowImpassable = true)
{
   WeightedIntRandomizer randomizer;

   if(allowImpassable == true)
   {
      randomizer.addOption(cTerrainLand, 1);
      randomizer.addOption(cTerrainShallowWater, 1);
      if(cAllowWater == true)
      {
         randomizer.addOption(cTerrainHybridWater, 1);
         randomizer.addOption(cTerrainDeepWater, 1);
      }
      randomizer.addOption(cTerrainForest, 2);
      randomizer.addOption(cTerrainImpassable, 2);
   }
   else
   {
      randomizer.addOption(cTerrainLand, 2);
      randomizer.addOption(cTerrainShallowWater, 1);
      if(cAllowWater == true)
      {
         randomizer.addOption(cTerrainHybridWater, 1);
      }
   }

   return randomizer.roll();
}

int randomizeEdgeSeparatorType()
{
   // TODO If our primary and/or secondary edge type are impassable, this probably should be passable.
   WeightedIntRandomizer randomizer;

   randomizer.addOption(cTerrainLand, 1);
   randomizer.addOption(cTerrainShallowWater, 1);
   if(cAllowWater == true)
   {
      randomizer.addOption(cTerrainHybridWater, 1);
      randomizer.addOption(cTerrainDeepWater, 1);
   }
   randomizer.addOption(cTerrainForest, 2);
   randomizer.addOption(cTerrainImpassable, 2);

   return randomizer.roll();
}

int randomizeCenterType(bool allowLand = true)
{
   WeightedIntRandomizer randomizer;

   if(allowLand == true)
   {
      randomizer.addOption(cTerrainLand, 1);
   }
   randomizer.addOption(cTerrainShallowWater, 1);
   if(cAllowWater == true)
   {
      randomizer.addOption(cTerrainHybridWater, 1);
      randomizer.addOption(cTerrainDeepWater, 1);
   }
   randomizer.addOption(cTerrainForest, 2);
   randomizer.addOption(cTerrainImpassable, 2);

   return randomizer.roll();
}

int randomizeCenterVariation()
{
   WeightedIntRandomizer randomizer;

   randomizer.addOption(cCenterSubAreas, 1);
   randomizer.addOption(cCenterSubAreasPaths, 1);
   randomizer.addOption(cCenterSingleArea, 1);

   return randomizer.roll();
}

int randomizeCenterSeparatorType()
{
   WeightedIntRandomizer randomizer;

   randomizer.addOption(cTerrainShallowWater, 1);
   if(cAllowWater == true)
   {
      randomizer.addOption(cTerrainHybridWater, 1);
      randomizer.addOption(cTerrainDeepWater, 1);
   }
   randomizer.addOption(cTerrainForest, 2);
   randomizer.addOption(cTerrainImpassable, 2);

   return randomizer.roll();
}

int randomizeGlobalDonutType()
{
   WeightedIntRandomizer randomizer;

   randomizer.addOption(cTerrainShallowWater, 1);
   if(cAllowWater == true)
   {
      randomizer.addOption(cTerrainHybridWater, 1);
      randomizer.addOption(cTerrainDeepWater, 1);
   }
   randomizer.addOption(cTerrainForest, 2);
   randomizer.addOption(cTerrainImpassable, 2);

   return randomizer.roll();
}

int randomizeAreaFeatureType()
{
   WeightedIntRandomizer randomizer;

   // randomizer.addOption(cTerrainLand, 2);
   randomizer.addOption(cTerrainShallowWater, 1);
   if(cAllowWater == true)
   {
      randomizer.addOption(cTerrainHybridWater, 1);
      randomizer.addOption(cTerrainDeepWater, 1);
   }
   randomizer.addOption(cTerrainForest, 2);
   randomizer.addOption(cTerrainImpassable, 2);

   return randomizer.roll();
}

float getWaterDepth(int terrainType = cTerrainNone)
{
   switch(terrainType)
   {
      case cTerrainShallowWater:
      {
         return cWaterDepthShallow;
      }
      case cTerrainHybridWater:
      {
         return cWaterDepthHybrid;
      }
      case cTerrainDeepWater:
      {
         return cWaterDepthDeep;
      }
   }

   return 0.0;
}

void initTerrain()
{
   // Size.
   int totalTiles = cTilesPerPlayer * cNumberPlayers * getMapAreaSizeFactor();
   
   // If we have edge stuff, we need to account for it.
   if(xsRandBool(0.5) == true)
   {
      cEdgeType = randomizeEdgeType();

      if(isTerrainPassable(cEdgeType) == true && xsRandBool(0.5) == true)
      {
         cEdgeSeparatorType = randomizeEdgeSeparatorType();
      }

      int minEdgeTiles = 0;
      int maxEdgeTiles = 0;

      if(gameIs1v1() == true)
      {
         maxEdgeTiles = 0.15 * sqrt(totalTiles);
      }
      else
      {
         maxEdgeTiles = 0.1 * sqrt(totalTiles);
      }

      switch(cEdgeType)
      {
         case cTerrainShallowWater:
         case cTerrainHybridWater:
         case cTerrainDeepWater:
         {
            minEdgeTiles = 8;
            break;
         }
         case cTerrainLand:
         case cTerrainForest:
         case cTerrainImpassable:
         {
            minEdgeTiles = 4;
            break;
         }
      }

      cEdgeTiles = xsRandInt(minEdgeTiles, maxEdgeTiles);

      if(cEdgeSeparatorType != cTerrainNone)
      {
         cEdgeSeparatorTiles = 0;

         switch(cEdgeSeparatorType)
         {
            case cTerrainShallowWater:
            case cTerrainHybridWater:
            case cTerrainDeepWater:
            {
               cEdgeSeparatorTiles = 8;
               break;
            }
            case cTerrainLand:
            case cTerrainForest:
            case cTerrainImpassable:
            {
               cEdgeSeparatorTiles = 4;
               break;
            }
         }
      }
   }

   // if(gameIs1v1() == true || xsRandBool(0.5) == true)
   {
      if(isTerrainPassable(cEdgeSeparatorType) == false)
      {
         cEdgeBonusTiles += 1.0 * cEdgeSeparatorTiles;
      }
      else
      {
         cEdgeBonusTiles += 0.5 * cEdgeSeparatorTiles;
      }

      if(isTerrainPassable(cEdgeType) == false)
      {
         // cEdgeBonusTiles += cEdgeTiles;
         cEdgeBonusTiles += 1.0 * cEdgeTiles;
      }
      else
      {
         cEdgeBonusTiles += 0.5 * cEdgeTiles;
      }

      //if(gameIs1v1() == false)
      //{
      //   cEdgeBonusTiles /= 2;
      //}
   }

   cMapShape = randomizeMapShape();
   
   // See if we need to scale the axes.
   float xAxisFactor = 1.0;
   if(cMapShape == cMapShapeRectangular)
   {
      // The smaller axis between 0.8 and 1.0 for rectangular (-> [0.8, 1.25] for the x axis).
      xAxisFactor = 0.8 + 0.05 * xsRandInt(0, 9);
   }

   int axisTiles = sqrt(totalTiles);
   int xAxisTiles = xAxisFactor * axisTiles;
   int zAxisTiles = totalTiles / xAxisTiles;

   xAxisTiles += 2 * cEdgeBonusTiles;
   zAxisTiles += 2 * cEdgeBonusTiles;

   // Make axes uneven as this brings advantages when it comes to correctness and precision stuff.
   if(xAxisTiles % 2 == 0)
   {
      xAxisTiles--;
   }

   if(zAxisTiles % 2 == 0)
   {
      zAxisTiles--;
   }

   // Set size.
   float sclr=2;
   if(cMapSizeCurrent == 1)
   {
      sclr=3;
   }

   rmSetMapSize(xAxisTiles * sclr, zAxisTiles * sclr);
   rmInitializeMix(cBiome.getDefaultMix(), 0.5);

   rmGenerationAddLogLine("Edge tiles: " + cEdgeTiles);
   rmGenerationAddLogLine("Edge separator tiles: " + cEdgeSeparatorTiles);
   rmGenerationAddLogLine("Edge bonus tiles: " + cEdgeBonusTiles);
   rmGenerationAddLogLine("Map tiles: " + rmGetMapXTiles() + "/" + rmGetMapZTiles());
}

void placePlayers()
{
   cPlacementType = randomizePlayerPlacement();

   if(cMapShape == cMapShapeRectangular)
   {
      cPlacementType = cPlacementTypeSquare;
   }

   rmSetTeamSpacingModifier(xsRandFloat(0.8, 1.0));

   int minEdgePlayerTileDist = cPlayerEdgeMinTiles + cEdgeTiles + cEdgeSeparatorTiles;

   // Account for large edges and scale down properly.
   float maxFractionFirst = 0.375 * (1.0 - 2.0 * smallerTilesToFraction(cEdgeTiles + cEdgeSeparatorTiles));
   float maxFractionSecond = 0.5 - smallerTilesToFraction(minEdgePlayerTileDist);
   float maxPlacementRadiusFraction = min(maxFractionFirst, maxFractionSecond);

   // Offset by the edge so we can still scale properly.
   float minPlacementRadiusFraction = 0.0;
   if(gameIs1v1() == true)
   {
      // TODO Chance for 30 or 20 with guaranteed separator?
      // TODO Increase to 40? 35 can be quite close.
      minPlacementRadiusFraction = largerTilesToFraction(35);
   }
   else
   {
      // Cap both ends of the minimum like the maximum for teamgames.
      float minFractionFirst = 0.275 * (1.0 - 2.0 * largerTilesToFraction(cEdgeTiles + cEdgeSeparatorTiles));
      float minFractionSecond = largerTilesToFraction(60);
      minPlacementRadiusFraction = max(minFractionFirst, minFractionSecond);
   }

   // Sanitize.
   minPlacementRadiusFraction = min(minPlacementRadiusFraction, maxPlacementRadiusFraction);

   cPlacementRadiusFraction = xsRandFloat(minPlacementRadiusFraction, maxPlacementRadiusFraction);

   switch(cPlacementType)
   {
      case cPlacementTypeCircular:
      {
         rmPlacePlayersOnCircle(cPlacementRadiusFraction);
         break;
      }
      case cPlacementTypeSquare:
      {
         // Scale distance properly if we have a rectangular map.
         if(cMapShape == cMapShapeRectangular)
         {
            float edgeDistMeters = smallerFractionToMeters(0.5 - cPlacementRadiusFraction);
            rmPlacePlayersOnSquare(0.5 - rmXMetersToFraction(edgeDistMeters), 0.5 - rmZMetersToFraction(edgeDistMeters));
         }
         else
         {
            rmPlacePlayersOnSquare(cPlacementRadiusFraction);
         }
         break;
      }
   }

   rmGenerationAddLogLine("Player radius: " + cPlacementRadiusFraction + " in [" + minPlacementRadiusFraction + ", " + maxPlacementRadiusFraction + "]");
}

int createAreaDefForGenericType(string name = cEmptyString, int type = cTerrainNone, bool allowPassableCliff = false, bool onlyBlendShallows = false)
{
   int areaDefID = rmAreaDefCreate(name);
   if(areaDefID == cInvalidID)
   {
      return cInvalidID;
   }

   switch(type)
   {
      case cTerrainNone:
      {
         // Nothing to do.
         break;
      }
      case cTerrainLand:
      {
         rmAreaDefSetMix(areaDefID, cBiome.getDefaultMix());
         rmAreaDefSetHeight(areaDefID, 0.5);
         if(onlyBlendShallows == false)
         {
            rmAreaDefAddHeightBlend(areaDefID, cBlendEdge, cFilter5x5Box, 1, 2, false, true);
         }
         else
         {
            rmAreaDefAddHeightConstraint(areaDefID, vDefaultAvoidLand);
            int blendIdx = rmAreaDefAddHeightBlend(areaDefID, cBlendEdge, cFilter5x5Box, 1, 2, false, false);
            rmAreaDefAddHeightBlendConstraint(areaDefID, blendIdx, vDefaultAvoidLand);
         }
         break;
      }
      case cTerrainForest:
      {
         rmAreaDefSetMix(areaDefID, cBiome.getDefaultMix());
         rmAreaDefSetForestType(areaDefID, cBiome.getRandomForest());
         rmAreaDefAddForestConstraint(areaDefID, vDefaultAvoidImpassableLand);
         // rmAreaDefSetForestUnderbrushDensity(areaDefID, 1.0);
         rmAreaDefSetHeight(areaDefID, 0.5);
         if(onlyBlendShallows == false)
         {
            rmAreaDefAddHeightBlend(areaDefID, cBlendEdge, cFilter5x5Box, 1, 2, false, true);
         }
         else
         {
            rmAreaDefAddHeightConstraint(areaDefID, vDefaultAvoidLand);
            int blendIdx = rmAreaDefAddHeightBlend(areaDefID, cBlendEdge, cFilter5x5Box, 1, 2, false, false);
            rmAreaDefAddHeightBlendConstraint(areaDefID, blendIdx, vDefaultAvoidLand);
         }
         break;
      }
      case cTerrainImpassable:
      {
         // TODO Implement this (and remove false from the stmt below).
         if(allowPassableCliff == true && false)
         {
            rmAreaDefSetCliffType(areaDefID, cBiome.getRandomCliff(cCliffInsidePassable));

            rmAreaDefSetHeightRelative(areaDefID, xsRandFloat(6.0, 6.0));
            // TODO Syscalls to apply noise last.
            // rmAreaDefSetHeightNoise(areaDefID, cNoiseFractalSum, xsRandFloat(2.0, 3.0), 0.1, 5, 0.5);
            // rmAreaDefSetHeightNoiseBias(areaDefID, 1.0);

            float rampFraction = 0.5;
            int numRamps = 2;
            float rampSize = rampFraction / numRamps;
            rmAreaDefSetCliffRamps(areaDefID, numRamps, rampSize, 0.0, 1.0);
            rmAreaDefSetCliffRampSteepness(areaDefID, 10.0);
            rmAreaDefSetEdgeSmoothDistance(areaDefID, 10);
            // Do the height blending instead of ramp steepness, and do that after painting to ignore impassable land.
            int blendIdx = rmAreaDefAddHeightBlend(areaDefID, cBlendCliffInside, cFilter5x5Gaussian, 10, 10, true, true);
            rmAreaDefAddHeightBlendExpansionConstraint(areaDefID, blendIdx, vDefaultAvoidImpassableLand);
         }
         else
         {
            // Either get a passable or impassable; if passable, paint inside as side.
            if(xsRandBool(0.5) == true || cBiome.mCliffImpassableCandidates.size() == 0)
            {
               rmAreaDefSetCliffType(areaDefID, cBiome.getRandomCliff(cCliffInsidePassable));
               rmAreaDefSetCliffPaintInsideAsSide(areaDefID, true);
            }
            else
            {
               rmAreaDefSetCliffType(areaDefID, cBiome.getRandomCliff(cCliffInsideImpassable));
            }

            rmAreaDefAddHeightBlend(areaDefID, cBlendAll, cFilter3x3Gaussian, 2, 2);

            rmAreaDefSetHeightRelative(areaDefID, xsRandFloat(3.0, 10.0));
            rmAreaDefSetHeightNoise(areaDefID, cNoiseFractalSum, xsRandFloat(5.0, 20.0), 0.1, 5, 0.5);
            rmAreaDefSetHeightNoiseBias(areaDefID, 1.0);

            // If we're blending cliffs into each other...
            // ...don't overwrite each other with outer layering.
            rmAreaDefAddCliffOuterLayerConstraint(areaDefID, vDefaultAvoidImpassableLand);
            // ...don't paint the outer layer too close to water (due to post-gen beaches overriding that).
            rmAreaDefAddCliffOuterLayerConstraint(areaDefID, vDefaultAvoidWater4);
            // ...don't do the inner layers.
            rmAreaDefSetCliffLayerPaint(areaDefID, cCliffLayerInnerSideClose, false);
            rmAreaDefSetCliffLayerPaint(areaDefID, cCliffLayerInnerSideFar, false);
         }

         // Side radius of 2 is good for higher cliffs.
         rmAreaDefSetCliffSideRadius(areaDefID, 0, 2);
         rmAreaDefSetCliffEmbellishmentDensity(areaDefID, xsRandFloat(0.25, 1.0));
         break;
      }
      case cTerrainShallowWater:
      case cTerrainHybridWater:
      case cTerrainDeepWater:
      {
         rmAreaDefSetWaterType(areaDefID, cBiome.getDefaultWater());
         rmAreaDefSetWaterDepth(areaDefID, getWaterDepth(type));

         // Since we know our layout, we can be sure that we'll never need a buffer (to prevent flooding the entire map).
         // Note that this requires careful height noise (if you go below water level, this will flood).
         rmAreaDefSetWaterEdgeHeight(areaDefID, 0.0, 0.0);

         // TODO Figure out what's best here.
         rmAreaDefAddHeightBlend(areaDefID, cBlendEdge, cFilter5x5Box, 1, 2, false, true);
         // rmAreaDefSetWaterHeightBlend(areaDefID, cBlendNone, 0, 0);
         // rmAreaDefSetWaterPaintTerrain(areaDefID, true);

         break;
      }
   }

   return areaDefID;
}

void makeEdge()
{
   // If we have no edge, still build the edge area since other stuff expects this to exist.
   if(cEdgeTiles == 0)
   {
      return;
   }

   int nonEdgeClassID = rmClassCreate();
   int edgeAreaClassID = rmClassCreate();

   float nonEdgeXMeters = rmGetMapXMeters() - 2 * rmTilesToMeters(cEdgeTiles);
   float nonEdgeZMeters = rmGetMapZMeters() - 2 * rmTilesToMeters(cEdgeTiles);

   float fakeNonEdgeSize = xsRandFloat(0.775, 0.875) * rmSquareMetersToAreaFraction(nonEdgeXMeters * nonEdgeZMeters, true, false);
   int forceInBox = createSymmetricBoxConstraint(rmXTileIndexToFraction(cEdgeTiles), rmZTileIndexToFraction(cEdgeTiles));

   // Set up a fake area as playable area and blocker.
   int fakeNonEdgeAreaID = rmAreaCreate("fake non-edge area");
   rmAreaSetLoc(fakeNonEdgeAreaID, cCenterLoc);
   rmAreaSetSize(fakeNonEdgeAreaID, fakeNonEdgeSize);
   rmAreaSetCoherenceSquare(fakeNonEdgeAreaID, xsRandBool(0.25));
   rmAreaAddConstraint(fakeNonEdgeAreaID, forceInBox);
   rmAreaAddToClass(fakeNonEdgeAreaID, nonEdgeClassID);
   rmAreaBuild(fakeNonEdgeAreaID);

   // Also create player connections to the center just to be su8re we get the space around players we need.
   int fakeNonEdgePlayerAreaDefID = rmAreaDefCreate("fake non-edge player area");
   rmAreaDefAddConstraint(fakeNonEdgePlayerAreaDefID, forceInBox);
   rmAreaDefAddToClass(fakeNonEdgePlayerAreaDefID, nonEdgeClassID);
   
   int playerNonEdgeAreaPathDefID = rmPathDefCreate("fake non-edge player path");

   createPlayerToLocConnections("fake non-edge connection", playerNonEdgeAreaPathDefID, fakeNonEdgePlayerAreaDefID, cCenterLoc,
                                rmTilesToMeters(cPlayerEdgeMinTiles), 0.5 * rmTilesToMeters(cPlayerEdgeMinTiles));

   // Rebuild the center edge based on the stuff we built, this is the actual non-edge area.
   int forceNearNonEdgeAreaEdge = rmCreateClassMaxDistanceConstraint(nonEdgeClassID, 0.0);

   // Area was created before already, now build it.
   cNonEdgeAreaID = rmAreaCreate("non-edge area");
   rmAreaSetLoc(cNonEdgeAreaID, cCenterLoc);
   rmAreaSetSize(cNonEdgeAreaID, 1.0);
   rmAreaAddConstraint(cNonEdgeAreaID, forceNearNonEdgeAreaEdge);
   rmAreaBuild(cNonEdgeAreaID);

   // Now build the edge stuff.
   int avoidNonEdgeArea = rmCreateAreaDistanceConstraint(cNonEdgeAreaID, 1.0);

   // Go from both sides so we don't enclose and override the center.
   int fakeEdgeAreaDefID = rmAreaDefCreate("fake edge area");
   rmAreaDefSetSize(fakeEdgeAreaDefID, 1.0);
   rmAreaDefAddConstraint(fakeEdgeAreaDefID, avoidNonEdgeArea);
   rmAreaDefAddToClass(fakeEdgeAreaDefID, cEdgeClassID);
   rmAreaDefSetAvoidSelfDistance(fakeEdgeAreaDefID, 1.0);

   // Since the edge forms a donut, build an area from each side.
   int northernFakeEdgeArea = rmAreaDefCreateArea(fakeEdgeAreaDefID);
   rmAreaSetLoc(northernFakeEdgeArea, vectorXZ(1.0, 1.0));
   int southernFakeEdgeArea = rmAreaDefCreateArea(fakeEdgeAreaDefID);
   rmAreaSetLoc(southernFakeEdgeArea, vectorXZ(0.0, 0.0));

   // One of the few places in this script where it's okay to build all.
   rmAreaBuildAll();

   // Build the edge areas that we'll paint.
   // TODO Could compute this based on size.
   int targetNumEdgeAreas = 2;
   if(xsRandBool(0.8) == true)
   {
      if(xsRandBool(0.25) == true)
      {
         targetNumEdgeAreas = 4;
      }
      else
      {
         targetNumEdgeAreas = 2 * xsRandInt(1, 5 * cNumberPlayers);
      }
   }

   int numAreaTiles = rmGetMapTiles() - rmAreaGetTileCount(cNonEdgeAreaID);
   int numTilesPerArea = numAreaTiles / targetNumEdgeAreas;
   float areaSize = rmTilesToAreaFraction(numTilesPerArea);

   // bool allowImpassable = (isTerrainPassable(cEdgeType) == false);
   int secondaryEdgeType = (targetNumEdgeAreas > 2) ? randomizeEdgeType(true) : cTerrainNone;

   // This is left at 0 for now even for 2 areas, difficult to get this working properly (imagine).
   // Would likely also need paths in case we ever made this.
   int areaSeparatorBufferTiles = 0;
   int avoidEdgeArea = rmCreateClassDistanceConstraint(edgeAreaClassID, 1.0);
   int edgeAreaAvoidSelf = rmCreateClassDistanceConstraint(edgeAreaClassID, 3.0 + rmTilesToMeters(areaSeparatorBufferTiles));
   int forceToEdge = createSymmetricBoxDistanceConstraint(rmXTileIndexToFraction(1), rmXTileIndexToFraction(1), 1.0);
   int forceInEdgeArea = rmCreateAreaDistanceConstraint(cNonEdgeAreaID, 1.0);

   int numEdgeAreaDefs = 0;

   // Also create paths to prevent awkward situations where an edge area also builds "in front" of another.
   int edgePathClassID = rmClassCreate();
   int avoidEdgePath = rmCreateClassDistanceConstraint(edgePathClassID, 1.0);

   int edgePathID = rmPathDefCreate("edge area path");
   rmPathDefSetIgnoreStartEndConstraints(edgePathID, true);

   int[] areasToBuild = new int(0, 0);
   bool allowForFeatures = xsRandBool(0.5);

   while(true)
   {
      // TODO Randomize differently?
      // If we don't have a secondary edge type take the first one, otherwise alternate.
      int edgeType = ((secondaryEdgeType == cTerrainNone) || (numEdgeAreaDefs % 2 == 0)) ? cEdgeType : secondaryEdgeType;

      int edgeAreaDefID = createAreaDefForGenericType("edge area " + numEdgeAreaDefs, edgeType);
      rmAreaDefSetSize(edgeAreaDefID, xsRandFloat(0.5, 1.5) * areaSize);

      rmAreaDefAddConstraint(edgeAreaDefID, forceInEdgeArea);
      rmAreaDefAddConstraint(edgeAreaDefID, avoidEdgePath);
      rmAreaDefAddConstraint(edgeAreaDefID, edgeAreaAvoidSelf, 0.0, rmTilesToMeters(areaSeparatorBufferTiles));
      rmAreaDefAddOriginConstraint(edgeAreaDefID, edgeAreaAvoidSelf, 10.0);
      rmAreaDefAddOriginConstraint(edgeAreaDefID, forceToEdge);
      rmAreaDefAddToClass(edgeAreaDefID, edgeAreaClassID);
      if(allowForFeatures == true)
      {
         rmAreaDefAddToClass(edgeAreaDefID, cValidFeatureAreaClassID);
      }

      int edgeAreaID = rmAreaDefCreateArea(edgeAreaDefID);
      if(rmAreaFindOriginLoc(edgeAreaID) == false)
      {
         rmAreaSetFailed(edgeAreaID);
         break;
      }

      vector edgeLoc = rmAreaGetLoc(edgeAreaID);
      vector mirroredEdgeLoc= vectorXZ(1.0 - edgeLoc.x, 1.0 - edgeLoc.z);
      
      // Also build the mirrored one.
      int mirroredEdgeAreaID = rmAreaDefCreateArea(edgeAreaDefID);
      if(rmAreaFindOriginLocClosestToLoc(mirroredEdgeAreaID, mirroredEdgeLoc, smallerFractionToMeters(0.25)) == false)
      {
         rmAreaSetFailed(edgeAreaID);
         rmAreaSetFailed(mirroredEdgeAreaID);
         break;
      }

      // Now connect them to the center so the future areas can avoid the paths.
      int pathID = rmPathDefCreatePath(edgePathID);
      rmPathAddWaypoint(pathID, cCenterLoc);
      rmPathAddWaypoint(pathID, edgeLoc);
      rmPathAddConstraint(pathID, avoidEdgeArea, 1000.0);
      rmPathBuild(pathID);
      
      int mirroredPathID = rmPathDefCreatePath(edgePathID);
      rmPathAddWaypoint(mirroredPathID, cCenterLoc);
      rmPathAddWaypoint(mirroredPathID, rmAreaGetLoc(mirroredEdgeAreaID));
      rmPathAddConstraint(mirroredPathID, avoidEdgeArea, 1000.0);
      rmPathBuild(mirroredPathID);

      areasToBuild.add(edgeAreaID);
      areasToBuild.add(mirroredEdgeAreaID);

      // Cliffs are painted later on.
      if(edgeType == cTerrainImpassable)
      {
         cCliffAreasToPaint.add(edgeAreaID);
         cCliffAreasToPaint.add(mirroredEdgeAreaID);
         rmAreaBuildMany(areasToBuild, false);
      }
      else
      {
         rmAreaBuildMany(areasToBuild, true);
      }

      rmPathAddToClass(pathID, edgePathClassID);
      rmPathAddToClass(mirroredPathID, edgePathClassID);

      // Reset the areas we just built (and possibly painted).
      areasToBuild.clear();

      numEdgeAreaDefs++;
   }
   
   // We could also use rmAreaGetClosestLoc() against all player areas instead of the origin.
   int[] edgeAreaIDs = rmClassGetAreas(edgeAreaClassID);
   int numEdgeAreas = edgeAreaIDs.size();
   float edgeAreaPathMinSize = 20.0;
   float edgeAreaPathMaxSize = 10.0 + 5.0 * cNumberPlayers + (30.0 / numEdgeAreas);
   float edgeAreaPathSize = 0.0;

   int edgeAreaPlayerPathID = rmPathDefCreate("egde area player path");
   // rmPathDefSetCostNoise(edgeAreaPlayerPathID, 0.0, 1.0);

   int edgeAreaPlayerPathAreaID = rmAreaDefCreate("edge area player path area");
   // TODO We could probably go crazy and make this shallow (since we'll redo the player area anyway).
   // rmAreaDefSetMix(edgeAreaPlayerPathAreaID, cBiome.getDefaultMix());
   // TODO This is probably not even needed.
   // rmAreaDefAddHeightBlend(edgeAreaPlayerPathAreaID, cBlendAll, cFilter5x5Gaussian);
   rmAreaDefAddToClass(edgeAreaPlayerPathAreaID, cEdgeAreaPathClassID);

   int[] edgeAreaConstraintIDs = new int(numEdgeAreas, cInvalidID);
   for(int i = 0; i < numEdgeAreas; i++)
   {
      edgeAreaConstraintIDs[i] = rmCreateAreaDistanceConstraint(edgeAreaIDs[i], 1.0);
   }

   for(int i = 0; i < numEdgeAreas; i++)
   {
      if(i % 2 == 0)
      {
         // Since we always create them in pairs, we re-randomize this every other area.
         edgeAreaPathSize = xsRandFloat(edgeAreaPathMinSize, edgeAreaPathMaxSize);
      }

      int edgeAreaID = edgeAreaIDs[i];
      vector edgeAreaLoc = rmAreaGetLoc(edgeAreaID);

      // Ignore those that failed.
      if(isLocValid(edgeAreaLoc) == false)
      {
         // Could also break here, but maybe I'm forgetting something so continue it is.
         continue;
      }

      vector minDistPlayerLoc = cInvalidVector;
      float minDistSqr = cMaxFloat;

      for(int j = 1; j <= cNumberPlayers; j++)
      {
         int p = vDefaultTeamPlayerOrder[j];
         vector playerLoc = rmGetPlayerLoc(p);

         float distSqr = playerLoc.distanceSqr(edgeAreaLoc);
         if(distSqr < minDistSqr)
         {
            minDistSqr = distSqr;
            minDistPlayerLoc = playerLoc;
         }
      }

      int pathID = rmPathDefCreatePath(edgeAreaPlayerPathID);
      // This path should not go through any other edge area or we might run into issues later (blocked for one, but not the other player).
      for(int j = 0; j < numEdgeAreas; j++)
      {
         if(i != j)
         {
            rmPathAddConstraint(pathID, edgeAreaConstraintIDs[j], 1000.0);
         }
      }
      rmPathAddWaypoint(pathID, edgeAreaLoc);
      rmPathAddWaypoint(pathID, minDistPlayerLoc);
      rmPathSetIgnoreStartEndConstraints(pathID, true);

      if(rmPathBuild(pathID) == true)
      {
         // Derive an area from the area def and build it around the path.
         int connectionAreaID = rmAreaDefCreateArea(edgeAreaPlayerPathAreaID);

         rmAreaSetPath(connectionAreaID, pathID, 0.5 * edgeAreaPathSize, 0.5 * edgeAreaPathSize);
         rmAreaBuild(connectionAreaID);
      }
   }

   // Random bonus paths.
   if(numEdgeAreas < 4)
   {
      int numBonusPaths = 2;
      
      for(int i = 0; i < numBonusPaths; i++)
      {
         float locAngle = randRadian();
         vector edgeLoc = getLocOnEdgeAtAngle(locAngle);

         int pathID = rmPathDefCreatePath(edgeAreaPlayerPathID);
         rmPathAddWaypoint(pathID, edgeLoc);
         rmPathAddWaypoint(pathID, vectorXZ(1.0 - edgeLoc.x, 1.0 - edgeLoc.z));

         if(rmPathBuild(pathID) == true)
         {
            // Derive an area from the area def and build it around the path.
            int connectionAreaID = rmAreaDefCreateArea(edgeAreaPlayerPathAreaID);

            rmAreaSetPath(connectionAreaID, pathID, 0.5 * edgeAreaPathSize, 0.5 * edgeAreaPathSize);
            rmAreaBuild(connectionAreaID);
         }
      }
   }
}

void makeDonutInnerArea(int outerAreaID = cInvalidID, int innerAreaID = cInvalidID, int minTiles = 0, int bufferTiles = 0, bool squareCoherence = false)
{
   static int sAvoidEdge = cInvalidID;
   if(sAvoidEdge == cInvalidID)
   {
      // Only do this once, then recycle.
      sAvoidEdge = createSymmetricBoxConstraint(rmXTileIndexToFraction(0), rmZTileIndexToFraction(0));
   }

   int avoidOuterEdge = rmCreateAreaEdgeDistanceConstraint(outerAreaID, 1.0);

   float actualSize = 1.0;

   if(bufferTiles > 0)
   {
      static int fakeInnerDonutAreaDefID = cInvalidID;
      if(fakeInnerDonutAreaDefID == cInvalidID)
      {
         fakeInnerDonutAreaDefID = rmAreaDefCreate("fake inner donut area");
         rmAreaDefSetLoc(fakeInnerDonutAreaDefID, cCenterLoc);
         rmAreaDefSetSize(fakeInnerDonutAreaDefID, 1.0);
      }

      int fakeInnerDonutMinAreaID = rmAreaDefCreateArea(fakeInnerDonutAreaDefID);
      rmAreaAddConstraint(fakeInnerDonutMinAreaID, avoidOuterEdge, rmTilesToMeters(minTiles + bufferTiles));
      rmAreaAddConstraint(fakeInnerDonutMinAreaID, sAvoidEdge, rmTilesToMeters(minTiles + bufferTiles));
      rmAreaBuild(fakeInnerDonutMinAreaID);

      int fakeInnerDonutMaxAreaID = rmAreaDefCreateArea(fakeInnerDonutAreaDefID);
      rmAreaAddConstraint(fakeInnerDonutMaxAreaID, avoidOuterEdge, rmTilesToMeters(minTiles));
      rmAreaBuild(fakeInnerDonutMaxAreaID);

      int actualMinTiles = rmAreaGetTileCount(fakeInnerDonutMinAreaID);
      int actualMaxTiles = rmAreaGetTileCount(fakeInnerDonutMaxAreaID);
      int actualTiles = actualMinTiles + 0.5 * (actualMaxTiles - actualMinTiles);
      actualSize = rmTilesToAreaFraction(actualTiles);
   }

   rmAreaSetLoc(innerAreaID, cCenterLoc);
   rmAreaSetSize(innerAreaID, actualSize);
   rmAreaAddConstraint(innerAreaID, avoidOuterEdge, rmTilesToMeters(minTiles));
   rmAreaAddConstraint(innerAreaID, sAvoidEdge, rmTilesToMeters(minTiles));
   rmAreaBuild(innerAreaID);
}

void makeEdgeSeparator()
{
   int avoidEdge = rmCreateClassDistanceConstraint(cEdgeClassID, 1.0);

   // Create and build the outer separator area (donut).
   cEdgeSeparatorOuterAreaID = rmAreaCreate("edge separator outer donut");
   rmAreaSetLoc(cEdgeSeparatorOuterAreaID, cCenterLoc);
   rmAreaSetSize(cEdgeSeparatorOuterAreaID, 1.0);
   rmAreaAddConstraint(cEdgeSeparatorOuterAreaID, avoidEdge);
   rmAreaBuild(cEdgeSeparatorOuterAreaID);

   // Create the inner separator area (donut).
   cEdgeSeparatorInnerAreaID = rmAreaCreate("edge separator inner donut");

   // Build it based on some params.
   makeDonutInnerArea(cEdgeSeparatorOuterAreaID, cEdgeSeparatorInnerAreaID, cEdgeSeparatorTiles, cEdgeSeparatorTiles / 2);
}

void fillEdgeSeparator()
{
   // If we have no separator type, we're already done.
   if(cEdgeSeparatorType == cTerrainNone)
   {
      return;
   }

   int separatorDefID = createAreaDefForGenericType("separator area", cEdgeSeparatorType);
   rmAreaDefSetSize(separatorDefID, 1.0);

   // TODO Variation in distance; might not want to build the areas concurrently if we have constraints of > 1.0.
   rmAreaDefAddConstraint(separatorDefID, rmCreateAreaDistanceConstraint(cEdgeSeparatorInnerAreaID, 1.0));
   rmAreaDefAddConstraint(separatorDefID, rmCreateAreaMaxDistanceConstraint(cEdgeSeparatorOuterAreaID, 0.0));
   // TODO Variation in distance; might want to also keep the edges clear from (WH-like) blockers.
   rmAreaDefAddConstraint(separatorDefID, rmCreateClassDistanceConstraint(cEdgeAreaPathClassID, 1.0));
   rmAreaDefAddConstraint(separatorDefID, createPlayerLocDistanceConstraint(30.0));
   rmAreaDefSetAvoidSelfDistance(separatorDefID, 1.0);
   // TODO Figure this out.
   rmAreaDefSetOriginConstraintBuffer(separatorDefID, 10.0);

   int[] areasToBuild = new int(0, 0);

   while(true)
   {
      int separatorAreaID = rmAreaDefCreateArea(separatorDefID);
      if(rmAreaFindOriginLoc(separatorAreaID) == false)
      {
         rmAreaSetFailed(separatorAreaID);
         break;
      }

      vector separatorLoc = rmAreaGetLoc(separatorAreaID);
      vector mirroredSeparatorLoc= vectorXZ(1.0 - separatorLoc.x, 1.0 - separatorLoc.z);
      
      // Also build the mirrored one.
      int mirroredSeparatorAreaID = rmAreaDefCreateArea(separatorDefID);
      if(rmAreaFindOriginLocClosestToLoc(mirroredSeparatorAreaID, mirroredSeparatorLoc) == false)
      {
         rmAreaSetFailed(separatorAreaID);
         rmAreaSetFailed(mirroredSeparatorAreaID);
         break;
      }
      
      areasToBuild.add(separatorAreaID);
      areasToBuild.add(mirroredSeparatorAreaID);

      // Cliffs are painted later on.
      if(cEdgeSeparatorType == cTerrainImpassable)
      {
         cCliffAreasToPaint.add(separatorAreaID);
         cCliffAreasToPaint.add(mirroredSeparatorAreaID);
         rmAreaBuildMany(areasToBuild, false);
      }
      else
      {
         rmAreaBuildMany(areasToBuild, true);
      }

      // Reset the areas we just built (and possibly painted).
      areasToBuild.clear();
   }
}

// The paths made here are respected by the center AND the center/player separator.
void makeRandomCenterPaths()
{
   const int cCenterBlockerNone = 0;
   const int cCenterBlockerPlayerPaths = 1;
   const int cCenterBlockerTeamPaths = 2;
   const int cNumberCenterBlockerTypes = 3;
   
   int centerBlockerType = cCenterBlockerNone;

   bool makeAllyPaths = false;
   bool makeEnemyPaths = false;
   int numRandomPaths = 0;

   if(cCenterVariationType != cCenterNone)
   {
      if(cCenterVariationType == cCenterSubAreasPaths)
      {
         // If we have this, force some center paths so we can build areas around them.
         if(xsRandBool(0.5) == true)
         {
            // Either force-connect all players to the center.
            centerBlockerType = cCenterBlockerPlayerPaths;
         }
         else
         {
            // Or force-connect all teams to the center, and then connect all allies.
            centerBlockerType = cCenterBlockerTeamPaths;
            if(cPlayerTeamAreaMakeTeamAreas == false)
            {
               makeAllyPaths = true;
            }
         }

         // Also pepper in some random ones.
         numRandomPaths = xsRandInt(min(2, cNumberPlayers / 2), cNumberPlayers);
      }
      else if(cCenterSeparatorType != cTerrainNone)
      {
         // We have a center and a center separator.
         if(isTerrainPassable(cCenterSeparatorType) == false)
         {
            // If the separator is impassable, we need to force connections.
            if(xsRandBool(0.5) == true)
            {
               // Either force-connect all players to the center.
               centerBlockerType = cCenterBlockerPlayerPaths;
            }
            else
            {
               // Or force-connect all teams to the center, and then connect all allies.
               centerBlockerType = cCenterBlockerTeamPaths;
               if(cPlayerTeamAreaMakeTeamAreas == false)
               {
                  makeAllyPaths = true;
               }
            }
         }
      }
   }

   if(isTerrainPassable(cCenterType) == false && cPlayerTeamAreaMakeSeparator == true &&
      isTerrainPassable(cCenterSeparatorType) == false)
   {
      // If we can't pass through the center and the player/center separator, force something.
      float separatorChance = xsRandFloat(0.0, 1.0);
      if(separatorChance < 1.0 / 3.0)
      {
         // Either force-connect all players to the center.
         centerBlockerType = cCenterBlockerPlayerPaths;
      }
      else if(separatorChance < 2.0 / 3.0)
      {
         // Or force-connect all teams to the center, and then connect all allies.
         centerBlockerType = cCenterBlockerTeamPaths;
         makeAllyPaths = true;
      }
      else
      {
         // Or force-connect all players.
         makeAllyPaths = true;
         makeEnemyPaths = true;
      }
   }

   // If we have a global donut, account for that.
   if(cGlobalDonutType != cTerrainNone && isTerrainPassable(cGlobalDonutType) == false)
   {
      // Just built some paths through the center so we have some passages.
      if(xsRandBool(0.5) == true)
      {
         centerBlockerType = (xsRandBool(0.5) == true) ? cCenterBlockerPlayerPaths : cCenterBlockerTeamPaths;
      }
      else if(numRandomPaths == 0)
      {
         numRandomPaths = xsRandInt(min(2, cNumberPlayers / 2), cNumberPlayers);
      }
   }

   // If we didn't force stuff already, randomize things.   
   if(centerBlockerType == cCenterBlockerNone && ((xsRandBool(1.0 / 3.0) == true) || (gameIsKotH() == true)))
   {
      centerBlockerType = xsRandInt(1, cNumberCenterBlockerTypes - 1);
   }

   if(makeAllyPaths == false)
   {
      makeAllyPaths = xsRandBool(0.25);
   }

   if(makeEnemyPaths == false)
   {
      makeEnemyPaths = xsRandBool(0.25);
   }

   if(numRandomPaths == 0)
   {
      // TODO Probably want to scale this based on how many things we're alredy building?
      numRandomPaths = (gameIs1v1() == true) ? 1 : xsRandInt(1, cNumberPlayers / 2);
   }

   // TODO Possibly also force something if the center is impassable and large.

   int pathDefID = rmPathDefCreate("center blocker path");
   rmPathDefSetCostNoise(pathDefID, 0.0, 0.0);
   rmPathDefAddToClass(pathDefID, cCenterPathClassID);

   switch(centerBlockerType)
   {
      case cCenterBlockerPlayerPaths:
      {
         for(int i = 1; i <= cNumberPlayers; i++)
         {
            int p = vDefaultTeamPlayerOrder[i];

            // Get the player angle, then stretch to the border so we always get a sufficiently long path.
            float playerAngle = vPlayerAngles[p];
            vector loc = getLocOnEdgeAtAngle(playerAngle);
            vector playerLoc = rmGetPlayerLoc(p);

            int pathID = rmPathDefCreatePath(pathDefID);
            rmPathAddWaypoint(pathID, playerLoc);
            rmPathAddWaypoint(pathID, cCenterLoc);
            rmPathBuild(pathID);
         }

         break;
      }
      case cCenterBlockerTeamPaths:
      {
         for(int i = 1; i <= cNumberTeams; i++)
         {
            // Get the team angle, then stretch to the border so we always get a sufficiently long path.
            float teamAngle = vTeamAngles[i];
            vector loc = getLocOnEdgeAtAngle(teamAngle);

            int pathID = rmPathDefCreatePath(pathDefID);
            rmPathAddWaypoint(pathID, loc);
            rmPathAddWaypoint(pathID, cCenterLoc);
            rmPathBuild(pathID);
         }
         break;
      }
   }

   // In a 1v1, don't build ally/enemy paths if we already have any other form of center paths.
   if((gameIs1v1() == false || centerBlockerType == cCenterBlockerNone) && (makeAllyPaths == true || makeEnemyPaths == true))
   {
      int p1 = vTeamPlayerOrderPlaced[cNumberPlayers];
      vector p1Loc = rmGetPlayerLoc(p1);

      for(int i = 1; i < cNumberPlayers; i++)
      {
         int p2 = vTeamPlayerOrderPlaced[i];
         vector p2Loc = rmGetPlayerLoc(p2);

         bool makePath = false;
         if(makeAllyPaths == true && rmGetPlayerTeam(p1) == rmGetPlayerTeam(p2))
         {
            makePath = true;
         }
         else if(makeEnemyPaths == true && rmGetPlayerTeam(p1) != rmGetPlayerTeam(p2))
         {
            makePath = true;
         }

         if(makePath == true)
         {
            int pathID = rmPathDefCreatePath(pathDefID);
            rmPathAddWaypoint(pathID, p1Loc);
            rmPathAddWaypoint(pathID, p2Loc);
            rmPathBuild(pathID);

            if(gameIs1v1() == true)
            {
               // For 1v1, we will never need more than 1 of these.
               break;
            }
         }

         p1 = p2;
         p1Loc = p2Loc;
      }
   }

   for(int i = 0; i < numRandomPaths; i++)
   {
      // Get a random angle, then stretch to the border so we always get a sufficiently long path.
      float angle = 0.0;
      if(gameIs1v1() == true)
      {
         angle = vPlayerAngles[1] + xsRandFloat(0.25, 0.75) * cPi;
      }
      else
      {
         angle = randRadian();
      }

      vector loc = getLocOnEdgeAtAngle(angle);
      vector otherLoc = vectorXZ(1.0 - loc.x, 1.0 - loc.z);

      int pathID = rmPathDefCreatePath(pathDefID);
      rmPathAddWaypoint(pathID, loc);
      rmPathAddWaypoint(pathID, otherLoc);
      rmPathSetCostNoise(pathID, 0.0);
      rmPathBuild(pathID);
   }
}

void makeCenter()
{
   // Decide if we want to build a center.
   float centerDist = getShortestPlayerLocDistanceToLoc(cCenterLoc);

   rmGenerationAddLogLine("Player center distance: " + centerDist);

   // Require at least some meters distance, otherwise it might get very small and pointless.
   if(centerDist <= 70.0)
   {
      return;
   }

   int centerEdgeSeparatorTiles = 30;
   int playerBufferTiles = 20;
   if(xsRandBool(0.25) == true)
   {
      cCenterPlayerSeparatorTiles = xsRandInt(4, 6);
   }

   // Randomize stuff.
   cCenterVariationType = randomizeCenterVariation();
   cCenterSeparatorType = randomizeCenterSeparatorType();
   // Only allow a land center if we have a separator, build a single area, and the separator is not already land.
   bool allowLandCenter = (cCenterPlayerSeparatorTiles > 0) && (cCenterSeparatorType != cTerrainLand) &&
                          (cCenterVariationType == cCenterSingleArea);
   cCenterType = randomizeCenterType(allowLandCenter);

   // Try to see how much space our center can take.
   float playerSeparatorMeters = rmTilesToMeters(cCenterPlayerSeparatorTiles);
   float edgeSeparatorMeters = rmTilesToMeters(centerEdgeSeparatorTiles);
   float playerBufferMeters = rmTilesToMeters(playerBufferTiles);

   int avoidPlayerCores = createPlayerLocDistanceConstraint(1.0 + playerBufferMeters + playerSeparatorMeters);
   int avoidPlayerExtension = rmCreateClassDistanceConstraint(vPlayerLocEdgePathClass, 1.0 + playerBufferMeters + playerSeparatorMeters);
   
   int edgeBufferTiles = 0;

   int avoidMapEdge = createSymmetricBoxConstraint(rmXTilesToFraction(centerEdgeSeparatorTiles), rmZTilesToFraction(centerEdgeSeparatorTiles));

   // Restrict the center so we never overshoot.
   int maxCenterFakeAreaID = rmAreaCreate("max fake center");
   rmAreaSetLoc(maxCenterFakeAreaID, cCenterLoc); 
   rmAreaSetSize(maxCenterFakeAreaID, 1.0);
   // rmAreaSetTerrainType(maxCenterFakeAreaID, cTerrainDefaultBlack);
   rmAreaAddConstraint(maxCenterFakeAreaID, avoidPlayerCores, 0.0, 10.0);
   rmAreaAddConstraint(maxCenterFakeAreaID, avoidPlayerExtension);
   rmAreaAddConstraint(maxCenterFakeAreaID, avoidMapEdge);
   if(cNonEdgeAreaID != cInvalidID)
   {
      int forceInNonEdgeArea = rmCreateAreaConstraint(cNonEdgeAreaID);
      int avoidNonEdgeAreaEdge = rmCreateAreaEdgeDistanceConstraint(cNonEdgeAreaID, edgeSeparatorMeters);
      rmAreaAddConstraint(maxCenterFakeAreaID, forceInNonEdgeArea);
      rmAreaAddConstraint(maxCenterFakeAreaID, avoidNonEdgeAreaEdge);
   }
   if(cEdgeSeparatorInnerAreaID != cInvalidID)
   {
      int forceInInnerEdgeSeparator = rmCreateAreaConstraint(cEdgeSeparatorInnerAreaID);
      int avoidInnerEdgeSeparatorEdge = rmCreateAreaEdgeDistanceConstraint(cEdgeSeparatorInnerAreaID, edgeSeparatorMeters);
      rmAreaAddConstraint(maxCenterFakeAreaID, forceInInnerEdgeSeparator);
      rmAreaAddConstraint(maxCenterFakeAreaID, avoidInnerEdgeSeparatorEdge);
   }

   rmAreaBuild(maxCenterFakeAreaID);

   // Scaled fake center area.
   float minCenterArea = rmRadiusToAreaFraction(20.0 * sqrt(cNumberPlayers));
   int minCenterTiles = rmFractionToAreaTiles(minCenterArea);
   int maxCenterTiles = rmAreaGetTileCount(maxCenterFakeAreaID);
   minCenterTiles = min(minCenterTiles, maxCenterTiles);
   int tileDelta =  maxCenterTiles - minCenterTiles;

   int numCenterTiles = 0;
   if(cCenterVariationType == cCenterSingleArea)
   {
      numCenterTiles = xsRandInt(minCenterTiles, minCenterTiles + 0.5 * tileDelta);
   }
   else
   {
      numCenterTiles = xsRandInt(0.5 * tileDelta, maxCenterTiles);
   }

   float fakeCenterSize = rmTilesToAreaFraction(numCenterTiles);
   int forceInMaxFakeCenter = rmCreateAreaConstraint(maxCenterFakeAreaID);

   cCenterFakeAreaID = rmAreaCreate("fake center");
   rmAreaSetLoc(cCenterFakeAreaID, cCenterLoc); 
   rmAreaSetSize(cCenterFakeAreaID, fakeCenterSize);
   rmAreaSetHeightNoise(cCenterFakeAreaID, cNoiseFractalSum, 4.0, 0.1, 4, 0.5);
   rmAreaSetHeightNoiseBias(cCenterFakeAreaID, 1.0);
   rmAreaAddHeightBlend(cCenterFakeAreaID, cBlendAll, cFilter5x5Box, 1, 2, false, true);
   rmAreaAddConstraint(cCenterFakeAreaID, forceInMaxFakeCenter);
   rmAreaAddToClass(cCenterFakeAreaID, cCenterFakeClassID);
   rmAreaBuild(cCenterFakeAreaID);
}

void fillCenter()
{
   if(cCenterFakeAreaID == cInvalidID)
   {
      return;
   }

   // TODO Verify this.
   int avoidCenterPaths = rmCreateClassDistanceConstraint(cCenterPathClassID, xsRandFloat(6.0, 10.0));
   int forceInFakeCenter = rmCreateAreaConstraint(cCenterFakeAreaID);

   int[] areasToBuild = new int(0, 0);
   int[] areasToPaint = new int(0, 0);

   switch(cCenterVariationType)
   {
      case cCenterSubAreas:
      {
         int maxAreaTiles = 1500;
         int totalTiles = rmAreaGetTileCount(cCenterFakeAreaID);
         int maxAreas = max(2, totalTiles / maxAreaTiles);
         float areaMaxSize = rmTilesToAreaFraction(maxAreaTiles);
         int centerAreaAvoidSelf = rmCreateClassDistanceConstraint(cCenterAreaClassID, 1.0);

         // TODO Buffer based on type? Water/cliff might need bit more.
         int areaDefID = createAreaDefForGenericType("center area", cCenterType, true);
         rmAreaDefSetSize(areaDefID, areaMaxSize);
         // We need this if we have an impassable player separator.
         if((cPlayerTeamAreaMakeSeparator == true && isTerrainPassable(cCenterSeparatorType) == false) || (gameIsKotH() == true))
         {
            rmAreaDefAddConstraint(areaDefID, avoidCenterPaths, 0.0, 10.0);
         }
         rmAreaDefAddConstraint(areaDefID, forceInFakeCenter, 0.0, 10.0);
         rmAreaDefAddToClass(areaDefID, cCenterAreaClassID);

         bool randomizeBonusBuffer = xsRandBool(0.5);
         float maxBuffer = smallerFractionToMeters(0.075);
         float bonusBuffer = (randomizeBonusBuffer == false) ? xsRandFloat(0.0, maxBuffer) : 0.0;

         for(int i = 0; i < maxAreas; i++)
         {
            int centerSubAreaID = rmAreaDefCreateArea(areaDefID);
            if(i == 0 && xsRandBool(0.25) == true)
            {
               rmAreaSetLoc(centerSubAreaID, cCenterLoc);
            }

            if(randomizeBonusBuffer == true)
            {
               bonusBuffer = xsRandFloat(0.0, 15.0 + 2.5 * cNumberPlayers);
            }

            // Always make the first one avoid center paths so we never block.
            // Particularly useful in 1v1 where the area might fully block the center if it's small. 
            if(gameIs1v1() == true)
            {
               rmAreaAddConstraint(centerSubAreaID, avoidCenterPaths, 10.0);
            }

            if(cCenterType == cTerrainImpassable || cCenterType == cTerrainForest)
            {
               rmAreaAddConstraint(centerSubAreaID, centerAreaAvoidSelf, 22.5 + bonusBuffer, 42.5 + bonusBuffer);
            }
            else
            {
               rmAreaAddConstraint(centerSubAreaID, centerAreaAvoidSelf, 15.0 + bonusBuffer, 35.0 + bonusBuffer);
            }

            if(rmAreaFindOriginLoc(centerSubAreaID) == false)
            {
               // Can't find starting loc, so we're already done.
               rmAreaSetFailed(centerSubAreaID);
               break;
            }

            areasToBuild.add(centerSubAreaID);

            // Cliffs are painted later on.
            if(cCenterType == cTerrainImpassable)
            {
               cCliffAreasToPaint.add(centerSubAreaID);
            }
         }

         if(cCenterType == cTerrainImpassable)
         {
            rmAreaBuildMany(areasToBuild, false);
         }
         else
         {
            rmAreaBuildMany(areasToBuild, true);
         }

         break;
      }
      case cCenterSubAreasPaths:
      case cCenterSingleArea:
      {
         float fakeCenterSize = rmTilesToAreaFraction(rmAreaGetTileCount(cCenterFakeAreaID));
         int areaDefID = createAreaDefForGenericType("center area", cCenterType, true);
         rmAreaDefSetSize(areaDefID, fakeCenterSize);
         rmAreaDefAddConstraint(areaDefID, forceInFakeCenter);
         // Check if want to respect the center paths. We have to do so if we do...
         // ...the path variation.
         // ...the single area variation if we hit the rng.
         // ...if we have a non-pathable center and a non-pathable separator.
         if((cCenterVariationType == cCenterSubAreasPaths) || (fakeCenterSize >= 0.075 && xsRandBool(0.75) == true) ||
            (isTerrainPassable(cCenterType) == false && isTerrainPassable(cCenterSeparatorType) == false) || (gameIsKotH() == true))
         {
            // Water/cliff gaps have to be larger as they grow slightly beyond their area radius.
            // We also give forests a 50% chance to avoid by more.
            // TODO Randomize the max buffer?
            if(cCenterType != cTerrainForest || (xsRandBool(0.5) == true) || (gameIsKotH() == true))
            {
               rmAreaDefAddConstraint(areaDefID, avoidCenterPaths, 10.0, 20.0);
            }
            else
            {
               rmAreaDefAddConstraint(areaDefID, avoidCenterPaths, 0.0, 10.0);
            }
         }
         rmAreaDefSetAvoidSelfDistance(areaDefID, 1.0);
         rmAreaDefAddToClass(areaDefID, cCenterAreaClassID);

         // Build as many as we can.
         int[] createdAreas = rmAreaDefCreateAndBuildAreas(areaDefID, 100, false);

         if(cCenterType == cTerrainImpassable)
         {
            int numAreas = createdAreas.size();
            for(int i = 0; i < numAreas; i++)
            {
               cCliffAreasToPaint.add(createdAreas[i]);
            }
         }
         else
         {
            rmAreaPaintMany(createdAreas);
         }

         break;
      }
   }
}

// Also responsible for team areas.
void makePlayerAreas()
{
   // TODO Plateau variation.
   cPlayerTeamAreaMakeTeamAreas = xsRandBool(0.75);

   float minSeparatorWidth = 10.0;
   float playerTeamSeparatorWidth = (cPlayerTeamAreaMakeSeparator == true) ? xsRandFloat(minSeparatorWidth, 15.0 + 2.5 * cNumberPlayers) : 0.0;

   int playerAreaAvoidFakeCenter = rmCreateClassDistanceConstraint(cCenterFakeClassID, 1.0 + rmTilesToMeters(cCenterPlayerSeparatorTiles));
   int playerAreaAvoidEdgeClass = rmCreateClassDistanceConstraint(cEdgeClassID, 1.0);

   int areaDefID = (cPlayerTeamAreaMakeTeamAreas == true) ? createAreaDefForGenericType("team area", cTerrainLand) : createAreaDefForGenericType("player area", cTerrainLand);
   rmAreaDefSetSize(areaDefID, 1.0);

   if(playerTeamSeparatorWidth > 1.0)
   {
      // Add some buffer and scale the width around that.
      // Example: Separator of 20, use half as buffer, use 15 (+ [0, 10] from the buffer) to get 20 avg.
      float actualSeparatorWidth = max(minSeparatorWidth, 0.75 * playerTeamSeparatorWidth);
      rmAreaDefSetAvoidSelfDistance(areaDefID, actualSeparatorWidth, 0.5 * playerTeamSeparatorWidth);
   }
   else
   {
      // We still need to avoid ourselves or badness ensues.
      rmAreaDefSetAvoidSelfDistance(areaDefID, 1.0);
   }

   rmAreaDefAddConstraint(areaDefID, playerAreaAvoidEdgeClass);
   // rmAreaDefAddConstraint(areaDefID, playerAreaAvoidCenter, 0.0, 20.0);
   rmAreaDefAddConstraint(areaDefID, playerAreaAvoidFakeCenter, 0.0, rmTilesToMeters(cCenterPlayerSeparatorTiles / 2));
   if(cNonEdgeAreaID != cInvalidID)
   {
      int playerAreaForceInNonEdgeArea = rmCreateAreaMaxDistanceConstraint(cNonEdgeAreaID, 0.0);
      rmAreaDefAddConstraint(areaDefID, playerAreaForceInNonEdgeArea);
   }
   if(cEdgeSeparatorInnerAreaID != cInvalidID)
   {
      int playerAreaForceInEdgeSeparator = rmCreateAreaEdgeDistanceConstraint(cEdgeSeparatorInnerAreaID, 1.0);
      rmAreaDefAddConstraint(areaDefID, playerAreaForceInEdgeSeparator);
   }
   rmAreaDefAddToClass(areaDefID, cPlayerTeamAreaClassID);
   rmAreaDefAddToClass(areaDefID, cValidFeatureAreaClassID);

   // TODO Should be a method.
   // Note that these were created in the order the players were placed.
   int[] playerCenterExtensionPathIDs = rmPathDefGetCreatedPaths(vPlayerLocEdgePathDef);
   int[] playerExtensionConstraints = new int(cNumberPlayersPlusNature, cInvalidID);
   for(int i = 1; i <= cNumberPlayers; i++)
   {
      int pathID = playerCenterExtensionPathIDs[i - 1];
      int pathOwnerID = rmPathGetOwnerID(pathID);
      playerExtensionConstraints[pathOwnerID] = rmCreatePathDistanceConstraint(pathID, 1.0);
   }

   float avoidPlayerExtensionMeters = 10.0;
   int totalAreas = (cPlayerTeamAreaMakeTeamAreas == true) ? cNumberTeams : cNumberPlayers;

   for(int i = 1; i <= totalAreas; i++)
   {
      int areaID = cInvalidID;
      if(cPlayerTeamAreaMakeTeamAreas == true)
      {
         areaID = rmAreaDefCreateArea(areaDefID, "team area " + i);
         rmAreaSetLocTeam(areaID, i);

         // Avoid extension paths so we don't accidentally enclose another player's area and get better shapes.
         for(int j = 1; j <= cNumberPlayers; j++)
         {
            int playerID = vDefaultTeamPlayerOrder[j];

            // Add all paths that are not in our own team as constraint.
            if(rmGetPlayerTeam(playerID) != i)
            {
               rmAreaAddConstraint(areaID, playerExtensionConstraints[playerID], avoidPlayerExtensionMeters);            
            }
         }
      }
      else
      {
         int p = vDefaultTeamPlayerOrder[i];

         areaID = rmAreaDefCreateArea(areaDefID, "player area " + p);
         rmAreaSetLocPlayer(areaID, p);

         // Avoid extension paths so we don't accidentally enclose another player's area and get better shapes.
         for(int j = 1; j <= cNumberPlayers; j++)
         {
            int playerID = vDefaultTeamPlayerOrder[j];

            // Add all paths that are not our own as constraint.
            if(playerID != p)
            {
               rmAreaAddConstraint(areaID, playerExtensionConstraints[playerID], avoidPlayerExtensionMeters);            
            }
         }
      }
   }

   rmAreaBuildAll();
}

void fillPlayerCenterSeparator()
{
   int centerSeparatorDefID = createAreaDefForGenericType("center separator area", cCenterSeparatorType);
   rmAreaDefSetSize(centerSeparatorDefID, 1.0);
   rmAreaDefAddToClass(centerSeparatorDefID, cCenterSeparatorClassID);

   // Okay so here we have to avoid pretty much everything that we did so far.
   rmAreaDefAddConstraint(centerSeparatorDefID, rmCreateClassDistanceConstraint(cCenterFakeClassID, 1.0));
   rmAreaDefAddConstraint(centerSeparatorDefID, rmCreateClassDistanceConstraint(cPlayerTeamAreaClassID, 1.0));
   // TODO Verify distances.
   rmAreaDefAddConstraint(centerSeparatorDefID, rmCreateClassDistanceConstraint(cCenterPathClassID, xsRandFloat(15.0, 25.0)), 0.0, 10.0);
   if(cEdgeSeparatorInnerAreaID != cInvalidID)
   {
      rmAreaDefAddConstraint(centerSeparatorDefID, rmCreateAreaEdgeDistanceConstraint(cEdgeSeparatorInnerAreaID, 1.0));
      rmAreaDefAddConstraint(centerSeparatorDefID, rmCreateAreaConstraint(cEdgeSeparatorInnerAreaID));
   }
   if(cNonEdgeAreaID != cInvalidID)
   {
      rmAreaDefAddConstraint(centerSeparatorDefID, rmCreateAreaMaxDistanceConstraint(cNonEdgeAreaID, 0.0));
   }
   rmAreaDefSetAvoidSelfDistance(centerSeparatorDefID, 1.0);

   int[] areasToBuild = new int(0, 0);

   while(true)
   {
      int centerSeparatorAreaID = rmAreaDefCreateArea(centerSeparatorDefID);
      if(rmAreaFindOriginLoc(centerSeparatorAreaID) == false)
      {
         rmAreaSetFailed(centerSeparatorAreaID);
         break;
      }

      vector centerSeparatorLoc = rmAreaGetLoc(centerSeparatorAreaID);
      vector mirroredCenterSeparatorLoc = vectorXZ(1.0 - centerSeparatorLoc.x, 1.0 - centerSeparatorLoc.z);
      
      // Also build the mirrored one.
      int mirroredCenterSeparatorAreaID = rmAreaDefCreateArea(centerSeparatorDefID);
      if(rmAreaFindOriginLocClosestToLoc(mirroredCenterSeparatorAreaID, mirroredCenterSeparatorLoc) == false)
      {
         rmAreaSetFailed(centerSeparatorAreaID);
         rmAreaSetFailed(mirroredCenterSeparatorAreaID);
         break;
      }

      areasToBuild.add(centerSeparatorAreaID);
      areasToBuild.add(mirroredCenterSeparatorAreaID);

      // Cliffs are painted later on.
      if(cCenterSeparatorType == cTerrainImpassable)
      {
         cCliffAreasToPaint.add(centerSeparatorAreaID);
         cCliffAreasToPaint.add(mirroredCenterSeparatorAreaID);
         rmAreaBuildMany(areasToBuild, false);
      }
      else
      {
         rmAreaBuildMany(areasToBuild, true);
      }

      // Reset the areas we just built (and possibly painted).
      areasToBuild.clear();
   }
}

void makeGlobalDonut()
{
   // Rules:
   // 1. Radius at most player placement radius.
   // 2. Avoid the player extension paths so we never accidentally enclose a player.
   // 3. Avoid the edge donut.

   int avoidPlayerPaths = rmCreateClassDistanceConstraint(vPlayerLocEdgePathClass, 10.0);

   // TODO For now we use the shortest player range -- could be changed/different.
   float outerMaxRadiusMeters = getShortestPlayerLocDistanceToLoc(cCenterLoc);
   float outerMinRadiusMeters = outerMaxRadiusMeters;
   float outerRadiusMeters = xsRandFloat(outerMinRadiusMeters, outerMinRadiusMeters);
   bool squareCoherence = xsRandBool(0.25);
   rmGenerationAddLogLine("Global donut radius range: [" + outerMinRadiusMeters + ", " + outerMaxRadiusMeters + "]");

   cGlobalDonutOuterAreaID = rmAreaCreate("global outer donut");
   rmAreaSetLoc(cGlobalDonutOuterAreaID, cCenterLoc);
   if(squareCoherence == true)
   {
      rmAreaSetCoherenceSquare(cGlobalDonutOuterAreaID, true);
      rmAreaSetSize(cGlobalDonutOuterAreaID, rmSquareMetersToAreaFraction((2.0 * outerRadiusMeters) * (2.0 * outerRadiusMeters)));
   }
   else
   {
      rmAreaSetSize(cGlobalDonutOuterAreaID, rmRadiusToAreaFraction(outerRadiusMeters));
   }
   rmAreaAddConstraint(cGlobalDonutOuterAreaID, avoidPlayerPaths);
   if(cEdgeSeparatorInnerAreaID != cInvalidID)
   {
      int avoidEdgeDonut = rmCreateAreaEdgeDistanceConstraint(cEdgeSeparatorInnerAreaID, 40.0);
      rmAreaAddConstraint(cGlobalDonutOuterAreaID, avoidEdgeDonut, 0.0, 10.0);
   }
   rmAreaBuild(cGlobalDonutOuterAreaID);

   // Create the inner separator area (donut).
   cGlobalDonutInnerAreaID = rmAreaCreate("global inner donut");

   // Build it based on some params.
   makeDonutInnerArea(cGlobalDonutOuterAreaID, cGlobalDonutInnerAreaID, 4, 2);

   // Paths.
   // TODO Chance for 1. player paths and 2. random additional paths?
   int pathDefID = rmPathDefCreate("global donut path");
   // rmPathDefSetCostNoise(pathDefID, 0.0, 2.0);

   // Trivial area to surround the path.
   int pathAreaDefID = rmAreaDefCreate("global donut path area");
   rmAreaDefAddToClass(pathAreaDefID, cGlobalDonutPathClassID);

   // Recompute outer radius.
   int numTiles = rmAreaGetTileCount(cGlobalDonutOuterAreaID);
   float radiusTiles = sqrt(numTiles / cPi);
   // We only use half of the circumference here since we mirror stuff.
   float circumferenceTiles = radiusTiles * cPi;
   
   // Some ranges for the filled and skipped arcs of the donut.
   // TODO Tweak these; could e.g. also cap i to <= 1 for 1v1 with a chance for only 2 openings.
   float minSkippedSegmentTiles = 10.0;
   float maxSkippedSegmentTiles = circumferenceTiles / 4.0;
   float minFilledSegmentTiles = 20.0;
   float maxFilledSegmentTiles = circumferenceTiles / 2.0;

   float angle = randRadian();
   int i = 0;

   while(circumferenceTiles > 0.0)
   {
      float segmentSize = 0.0;

      if(i % 2 == 0)
      {
         // Even: Skipped segment, build paths to block.
         segmentSize = xsRandFloat(minSkippedSegmentTiles, maxSkippedSegmentTiles);

         if(circumferenceTiles - segmentSize <= 0.0)
         {
            // If we overshoot, we're done.
            break;
         }

         vector loc = getLocOnEdgeAtAngle(angle);
         
         int pathID = rmPathDefCreatePath(pathDefID);
         rmPathAddWaypoint(pathID, cCenterLoc);
         rmPathAddWaypoint(pathID, loc);

         if(rmPathBuild(pathID) == true)
         {
            int pathAreaID = rmAreaDefCreateArea(pathAreaDefID);
            rmAreaSetPath(pathAreaID, pathID, segmentSize / 2.0, segmentSize / 2.0);
            rmAreaBuild(pathAreaID);
         }

         vector mirroredLoc = vectorXZ(1.0 - loc.x, 1.0 - loc.z);
         
         int mirroredPathID = rmPathDefCreatePath(pathDefID);
         rmPathAddWaypoint(mirroredPathID, cCenterLoc);
         rmPathAddWaypoint(mirroredPathID, mirroredLoc);

         if(rmPathBuild(mirroredPathID) == true)
         {
            int mirroredPathAreaID = rmAreaDefCreateArea(pathAreaDefID);
            rmAreaSetPath(mirroredPathAreaID, mirroredPathID, segmentSize / 2.0, segmentSize / 2.0);
            rmAreaBuild(mirroredPathAreaID);
         }
      }
      else
      {
         // Uneven: Skip by some size (do nothing so it gets painted).
         segmentSize = xsRandFloat(minFilledSegmentTiles, maxFilledSegmentTiles);
      }

      // Advance by the angle.
      angle += segmentSize / radiusTiles;
      circumferenceTiles -= segmentSize;
      i++;
   }
}

void fillGlobalDonut()
{
   int donutDefID = createAreaDefForGenericType("donut area", cGlobalDonutType);
   rmAreaDefSetSize(donutDefID, 1.0);

   float donutPathDistance = xsRandFloat(8.0, 8.0 + 2.0 * cNumberPlayers);

   rmAreaDefAddConstraint(donutDefID, rmCreateClassDistanceConstraint(cGlobalDonutPathClassID, donutPathDistance));
   rmAreaDefAddConstraint(donutDefID, rmCreateAreaDistanceConstraint(cGlobalDonutInnerAreaID, 1.0));
   rmAreaDefAddConstraint(donutDefID, rmCreateAreaMaxDistanceConstraint(cGlobalDonutOuterAreaID, 0.0));
   rmAreaDefAddConstraint(donutDefID, createPlayerLocDistanceConstraint(40.0));
   // TODO Verify this.
   rmAreaDefAddConstraint(donutDefID, rmCreateClassDistanceConstraint(cCenterSeparatorClassID, 1.0));
   rmAreaDefAddConstraint(donutDefID, rmCreateClassDistanceConstraint(cCenterPathClassID, 15.0));
   rmAreaDefAddConstraint(donutDefID, rmCreateClassDistanceConstraint(cCenterAreaClassID, 1.0));
   rmAreaDefSetAvoidSelfDistance(donutDefID, 1.0);

   int[] areasToBuild = new int(0, 0);

   while(true)
   {
      int donutAreaID = rmAreaDefCreateArea(donutDefID);
      if(rmAreaFindOriginLoc(donutAreaID) == false)
      {
         rmAreaSetFailed(donutAreaID);
         break;
      }

      vector donutLoc = rmAreaGetLoc(donutAreaID);
      vector mirroredDonutLoc = vectorXZ(1.0 - donutLoc.x, 1.0 - donutLoc.z);
      
      // Also build the mirrored one.
      int mirroredDonutAreaID = rmAreaDefCreateArea(donutDefID);
      if(rmAreaFindOriginLocClosestToLoc(mirroredDonutAreaID, mirroredDonutLoc) == false)
      {
         rmAreaSetFailed(donutAreaID);
         rmAreaSetFailed(mirroredDonutAreaID);
         break;
      }

      areasToBuild.add(donutAreaID);
      areasToBuild.add(mirroredDonutAreaID);

      // Cliffs are painted later on.
      if(cGlobalDonutType == cTerrainImpassable)
      {
         cCliffAreasToPaint.add(donutAreaID);
         cCliffAreasToPaint.add(mirroredDonutAreaID);
         rmAreaBuildMany(areasToBuild, false);
      }
      else
      {
         rmAreaBuildMany(areasToBuild, true);
      }

      // Reset the areas we just built (and possibly painted).
      areasToBuild.clear();
   }
}

void paintCliffAreas()
{
   int numCliffAreas = cCliffAreasToPaint.size();
   for(int i = 0; i < numCliffAreas; i++)
   {
      rmAreaAddRemoveType(cCliffAreasToPaint[i], cUnitTypeAll);
   }

   // We do this last, so take the array of cliff stuff and paint it.
   rmAreaPaintMany(cCliffAreasToPaint);
}

void makeRandomAreaFeatures()
{
   // TODO Improve this. This is currently suuuuper simplistic.
   // TODO Possibly prevent these from spawning on edge areas (at least non-water into hybrid/deep water).

   // Assess how many tiles we have that are even eligible for this at all.
   // We want to avoid all separators that we have.
   int forceInValidAreas = rmCreateClassMaxDistanceConstraint(cValidFeatureAreaClassID, 0.0);
   int avoidBuildings = rmCreateTypeDistanceConstraint(cUnitTypeBuilding, 20.0);

   int[] constraintIDs = new int(0, 0);
   constraintIDs.add(vDefaultAvoidImpassableLand16);
   constraintIDs.add(vDefaultAvoidAll16);
   constraintIDs.add(avoidBuildings);
   constraintIDs.add(forceInValidAreas);

   int numAcceptableTiles = getNumberAcceptableTilesForConstraints(constraintIDs);

   // TODO Scale up with more players.
   int maxAreaTiles = 300;
   float maxSize = rmTilesToAreaFraction(maxAreaTiles);
   int maxAreasPerPlayer = numAcceptableTiles / (4 * maxAreaTiles * cNumberPlayers);
   maxAreasPerPlayer = max(2, maxAreasPerPlayer);

   int areasPerPlayer = xsRandInt(2, maxAreasPerPlayer);

   // TODO Implement this.
   bool allowPassableCliff = xsRandBool(0.0);

   for(int i = 0; i < areasPerPlayer; i++)
   {
      // TODO Should probably only give cliffs or ponds.
      int areaDefID = createAreaDefForGenericType("feature area " + i, randomizeAreaFeatureType(), allowPassableCliff, true);
      rmAreaDefSetSize(areaDefID, maxSize);
      rmAreaDefAddConstraint(areaDefID, vDefaultAvoidImpassableLand16);
      rmAreaDefAddConstraint(areaDefID, vDefaultAvoidAll16);
      rmAreaDefAddConstraint(areaDefID, avoidBuildings);
      rmAreaDefAddConstraint(areaDefID, forceInValidAreas);
      rmAreaDefAddConstraint(areaDefID, vDefaultAvoidKotH);
      rmAreaDefSetOriginConstraintBuffer(areaDefID, 10.0);
      rmAreaDefSetBlobs(areaDefID, 1, 5);
      rmAreaDefSetBlobDistance(areaDefID, 20.0);
      rmAreaDefSetConstraintBuffer(areaDefID, 0.0, 10.0);
      rmAreaDefSetAvoidSelfDistance(areaDefID, 40.0);

      for(int j = 1; j <= cNumberPlayers; j++)
      {
         int p = vDefaultTeamPlayerOrder[j];

         int teamAreaID = vTeamAreaIDs[rmGetPlayerTeam(p)];
         int areaID = rmAreaDefCreateArea(areaDefID);
         rmAreaSetParent(areaID, teamAreaID);

         if(rmAreaFindOriginLoc(areaID) == false)
         {
            break;
         }
      }

      // Mark them all as failed.
      int numCreatedAreas = rmAreaDefGetNumberCreatedAreas(areaDefID);
      if(numCreatedAreas != cNumberPlayers)
      {
         for(int k = 0; k < numCreatedAreas; k++)
         {
            int failedAreaID = rmAreaDefGetCreatedArea(areaDefID, k);
            rmAreaSetFailed(failedAreaID);
         }

         break;
      }

      // At this point, we allow cliffs to be painted since we're actually avoiding impassable land from here on.
      rmAreaBuildAll();
   }
}

void placeWaterEmbellishment(string name = cEmptyString, ref WeightedIntRandomizer randomizer, ref int[] constraints, float fractionOfTotalTiles = 0.1)
{
   int numConstraints = constraints.size();
   int numAcceptableEmbellishmentTiles = getNumberAcceptableTilesForConstraints(constraints);

   if(numAcceptableEmbellishmentTiles > 0)
   {
      // Educated guess about how much we can place at most.
      int maxEmbellishment = numAcceptableEmbellishmentTiles * fractionOfTotalTiles;
      int totalPlacedEmbellishment = 0;

      int maxNumEmbellishment = randomizer.size();
      int minNumEmbellishment = min(1, maxNumEmbellishment);
      int numEmbellishment = xsRandInt(minNumEmbellishment, maxNumEmbellishment);

      float[] weights = createNormalizedFractions(numEmbellishment);

      for(int i = 0; i < numEmbellishment; i++)
      {
         int maxClusterSize = xsRandInt(2, 3);
         float avgClusterSize = 0.5 * (maxClusterSize + 1);

         int remainingObjects = maxEmbellishment - totalPlacedEmbellishment;
         int numObjects = min(remainingObjects, maxEmbellishment * weights[i]);
         int embellishmentProtoID = randomizer.rollAndRemove();

         int embellishmentID = rmObjectDefCreate(name + " " + i);
         rmObjectDefAddItemRange(embellishmentID, embellishmentProtoID, 1, maxClusterSize);
         // Also add the constraints.
         for(int j = 0; j < numConstraints; j++)
         {
            rmObjectDefAddConstraint(embellishmentID, constraints[j]);
         }

         int actualNumObjects = numObjects / avgClusterSize;
         rmObjectDefPlaceAnywhere(embellishmentID, 0, actualNumObjects);

         totalPlacedEmbellishment += actualNumObjects;
         if(totalPlacedEmbellishment > maxEmbellishment)
         {
            break;
         }
      }
   }
}

void generateInternal()
{
   rmSetProgress(0.0);

   cBiome = getRandomBiome();

   initTerrain();

   initGlobalClasses();

   // If we force a specific civ for that biome do that, otherwise randomize.
   rmSetLighting(cBiome.getRandomLighting());
   if(cBiome.getCivID() == cInvalidID)
   {
      rmSetNatureCivFromCulture(cBiome.getCultureID());
   }
   else
   {
      rmSetNatureCiv(cBiome.getCivID());
   }

   placePlayers();

   postPlayerPlacement();

   // Do NEVER alter this order unless you understand each of these functions.
   // Better chance for player/team separators if we have none or a buildable center.
   // cPlayerTeamAreaMakeSeparator = (cCenterFakeAreaID == cInvalidID || isTerrainPassable(cCenterType) == true) ? xsRandBool(0.5) : xsRandBool(0.25);
   cPlayerTeamAreaMakeSeparator = (getShortestPlayerLocDistance() >= 80.0) && (xsRandBool(0.75) == true);

   rmSetProgress(0.1);

   // The edge is randomized in terrain initialization, so always call these.
   makeEdge();
   makeEdgeSeparator();
   fillEdgeSeparator();

   if(xsRandBool(0.8) == true)
   {
      makeCenter();
   }

   if(cCenterFakeAreaID != cInvalidID)
   {
      // If we have a center, only make the global donut if it's small enough.
      int centerFakeAreaTiles = rmAreaGetTileCount(cCenterFakeAreaID);
      if(rmTilesToAreaFraction(centerFakeAreaTiles) < 0.2)
      {
         if(xsRandBool(0.5) == true)
         {
            cGlobalDonutType = randomizeGlobalDonutType();
         }
      }
   }
   else
   {
      // Otherwise, randomize as usual.
      if(xsRandBool(0.5) == true)
      {
         cGlobalDonutType = randomizeGlobalDonutType();
      }
   }

   rmSetProgress(0.2);

   // This is stuff we always do.
   makePlayerAreas();
   makeRandomCenterPaths();

   // Same with this.
   fillCenter();
   fillPlayerCenterSeparator();

   rmSetProgress(0.3);

   if(cGlobalDonutType != cInvalidID)
   {
      makeGlobalDonut();
      fillGlobalDonut();
   }

   // Done with global area stuff, paint any cliff areas last due to the edges.
   paintCliffAreas();

   // Paint some height noise areas.
   int heightNoiseClassID = rmClassCreate();
   
   int heightNoiseDefID = rmAreaDefCreate("height noise");
   rmAreaDefSetSize(heightNoiseDefID, 1.0);
   rmAreaDefSetHeightNoise(heightNoiseDefID, cNoiseFractalSum, 4.0, 0.1, 4, 0.5);
   rmAreaDefSetHeightNoiseBias(heightNoiseDefID, 1.0);
   rmAreaDefAddHeightBlend(heightNoiseDefID, cBlendAll, cFilter5x5Gaussian, 2, 3);
   rmAreaDefAddConstraint(heightNoiseDefID, vDefaultAvoidWater8);
   rmAreaDefAddConstraint(heightNoiseDefID, vDefaultAvoidImpassableLand4);
   rmAreaDefAddOriginConstraint(heightNoiseDefID, rmCreateClassDistanceConstraint(heightNoiseClassID, 20.0));
   rmAreaDefAddConstraint(heightNoiseDefID, rmCreateClassDistanceConstraint(heightNoiseClassID, 1.0));
   rmAreaDefAddToClass(heightNoiseDefID, heightNoiseClassID);

   int numHeightNoiseAreas = 0;
   while(true)
   {
      numHeightNoiseAreas++;
      int heightNoiseAreaID = rmAreaDefCreateArea(heightNoiseDefID);
      if(rmAreaFindOriginLoc(heightNoiseAreaID) == false)
      {
         rmAreaSetFailed(heightNoiseAreaID);
         break;
      }
   }

   int[] heightNoiseAreas = rmAreaDefGetCreatedAreas(heightNoiseDefID);
   if(numHeightNoiseAreas > 0)
   {
      heightNoiseAreas.removeIndex(numHeightNoiseAreas - 1);
   }
   rmAreaBuildMany(heightNoiseAreas, true, true);

   rmSetProgress(0.4);

   // Build areas under everything.
   int islandDefID = rmAreaDefCreate("resource island");
   rmAreaDefSetMix(islandDefID, cBiome.getDefaultMix());
   rmAreaDefSetHeight(islandDefID, 0.5);
   rmAreaDefAddHeightConstraint(islandDefID, vDefaultAvoidLand);
   rmAreaDefAddConstraint(islandDefID, vDefaultAvoidImpassableLand4);
   rmAreaDefAddHeightBlend(islandDefID, cBlendAll, cFilter5x5Box, 1, 2);

   float resourceIslandSize = rmRadiusToAreaFraction(10.0);

   // KotH.
   placeKotHObjects();

   if(gameIsKotH() == true)
   {
      // This is always the map center, but in case it's not...
      vector kothLoc = rmAreaGetLoc(vKotHAreaID);
      float kothLocSize = rmRadiusToAreaFraction(15.0);

      int kothIslandAreaID = rmAreaDefCreateArea(islandDefID);
      rmAreaSetLoc(kothIslandAreaID, kothLoc);
      rmAreaSetSize(kothIslandAreaID, kothLocSize);
      rmAreaBuild(kothIslandAreaID);
   }

   // Starting town centers.
   placeStartingTownCenters();

   // Starting towers.
   int startingTowerID = rmObjectDefCreate("starting tower");
   rmObjectDefAddItem(startingTowerID, cUnitTypeSentryTower, 1);
   rmObjectDefAddConstraint(startingTowerID, vDefaultAvoidAll8);
   rmObjectDefAddConstraint(startingTowerID, vDefaultAvoidImpassableLand);
   addObjectLocsPerPlayer(startingTowerID, true, 4, cStartingTowerMinDist, cStartingTowerMaxDist, cStartingTowerAvoidanceMeters);
   generateLocs("starting tower locs");

   int firstSettlementID = rmObjectDefCreate("first settlement");
   rmObjectDefAddItem(firstSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultSettlementAvoidAllWithFarm);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidImpassableLand16);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(firstSettlementID, vDefaultAvoidKotH);

   int secondSettlementID = rmObjectDefCreate("second settlement");
   rmObjectDefAddItem(secondSettlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidEdge);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultSettlementAvoidAllWithFarm);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidImpassableLand16);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(secondSettlementID, vDefaultAvoidKotH);

   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(firstSettlementID, false, 1, 60.0, 80.0, cSettlementDist1v1, cBiasBackward);
      int secondBias = (xsRandBool(0.5) == true) ? cBiasForward : cBiasAggressive;
      // TODO Chance to bind locs for 1v1.
      addSimObjectLocsPerPlayerPair(secondSettlementID, false, 1, 60.0, 120.0, cSettlementDist1v1, secondBias);
   }
   else if(gameIsFair() == true)
   {
      // Randomize inside/outside.
      int allyBias = getRandomAllyBias();
      addMirroredObjectLocsPerPlayerPair(secondSettlementID, false, 1, 60.0, 100.0, cFarSettlementDist, cBiasForward);
      addMirroredObjectLocsPerPlayerPair(firstSettlementID, false, 1, 60.0, 80.0, cCloseSettlementDist, cBiasDefensive | getRandomAllyBias());
   }
   else
   {
      addObjectLocsPerPlayer(secondSettlementID, false, 1, 60.0, 100.0, cFarSettlementDist, cBiasForward);
      addObjectLocsPerPlayer(firstSettlementID, false, 1, 60.0, 80.0, cCloseSettlementDist, cBiasBackward);
   }

   // Large/giant settlements.
   if (cMapSizeCurrent > cMapSizeStandard)
   {
      // TODO Can probably be sim loc for 1v1.
      int bonusSettlementID = rmObjectDefCreate("bonus settlement");
      rmObjectDefAddItem(bonusSettlementID, cUnitTypeSettlement, 1);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidEdge);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultSettlementAvoidAllWithFarm);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidImpassableLand16);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(bonusSettlementID, vDefaultAvoidKotH);
      addObjectLocsPerPlayer(bonusSettlementID, false, 1 * getMapAreaSizeFactor(), 80.0, -1.0, cFarSettlementDist);
   }

   // Generate the locations, but don't place stuff yet.
   // This is so that we don't accidentally overpaint the erosion.
   bool settlementLocsGenerated = generateLocs("settlement locs", true, false, true, false);

   buildAreaDefUnderLocs(islandDefID, resourceIslandSize);

   // Finally place stuff and reset.
   if(settlementLocsGenerated == true)
   {
      applyGeneratedLocs();
   }

   resetLocGen();

   // TODO Possibly be smarter.
   if((cCenterType == cInvalidID && xsRandBool(0.8) == true) || (cCenterType != cInvalidID && xsRandBool(0.5) == true))
   {
      makeRandomAreaFeatures();
   }

   rmSetProgress(0.5);

   // Starting objects.
   // Starting gold.
   int startingGoldID = rmObjectDefCreate("starting gold");
   if(xsRandBool(0.1) == true)
   {
      rmObjectDefAddItem(startingGoldID, cUnitTypeMineGoldLarge, 1);
   }
   else
   {
      rmObjectDefAddItem(startingGoldID, cUnitTypeMineGoldMedium, 1);
   }
   rmObjectDefAddConstraint(startingGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(startingGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(startingGoldID, vDefaultStartingGoldAvoidTower);
   rmObjectDefAddConstraint(startingGoldID, vDefaultForceStartingGoldNearTower);
   addObjectLocsPerPlayer(startingGoldID, false, 1, cStartingGoldMinDist, cStartingGoldMaxDist, cStartingObjectAvoidanceMeters);

   generateLocs("starting gold locs");

   // Starting hunt.
   HuntContainer startingHuntContainer = cBiome.getRandomHunt(xsRandInt(900, 1600), cHuntFlagsDefaultBase);

   int startingHuntID = rmObjectDefCreate("starting hunt");
   startingHuntContainer.addToObjectDef(startingHuntID);
   rmObjectDefAddConstraint(startingHuntID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(startingHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingHuntID, vDefaultForceInTowerLOS);
   addObjectLocsPerPlayer(startingHuntID, false, 1, cStartingHuntMinDist, cStartingHuntMaxDist, cStartingObjectAvoidanceMeters);

   // Berries.
   int startingBerriesID = rmObjectDefCreate("starting berries");
   rmObjectDefAddItem(startingBerriesID, cUnitTypeBerryBush, xsRandInt(6, 12), cBerryClusterRadius);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(startingBerriesID, vDefaultBerriesAvoidImpassableLand);
   addObjectLocsPerPlayer(startingBerriesID, false, 1, cStartingBerriesMinDist, cStartingBerriesMaxDist, cStartingObjectAvoidanceMeters);

   // Chicken.
   HuntContainer startingDomesticatedContainer = cBiome.getRandomHunt(xsRandInt(500, 700), cHuntFlagDomesticated);

   int startingDomesticatedID = rmObjectDefCreate("starting chicken");
   startingDomesticatedContainer.addToObjectDef(startingDomesticatedID);
   rmObjectDefAddConstraint(startingDomesticatedID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingDomesticatedID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(startingDomesticatedID, vDefaultFoodAvoidImpassableLand);
   addObjectLocsPerPlayer(startingDomesticatedID, false, 1, cStartingChickenMinDist, cStartingChickenMaxDist, cStartingObjectAvoidanceMeters);

   // Herdables.
   int herdType = cBiome.getRandomHerdable();

   int startingHerdID = rmObjectDefCreate("starting herd");
   rmObjectDefAddItem(startingHerdID, herdType, xsRandInt(2, 6));
   rmObjectDefAddConstraint(startingHerdID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(startingHerdID, vDefaultHerdAvoidImpassableLand);
   addObjectLocsPerPlayer(startingHerdID, true, 1, cStartingHerdMinDist, cStartingHerdMaxDist);

   generateLocs("starting food locs");

   // Starting forests.
   float startingForestAvoidSelfDist = xsRandFloat(20.0, 30.0);
   // The tiles we're searching for the origin should avoid each other a bit more.
   // Otherwise, the forest might fail to build (or will remain very small).
   float startingForestOriginAvoidSelfDist = startingForestAvoidSelfDist + 5.0;

   int playerForestDefID = rmAreaDefCreate("player forest");
   rmAreaDefSetSize(playerForestDefID, rmTilesToAreaFraction(xsRandInt(40, 120)));
   rmAreaDefSetMix(playerForestDefID, cBiome.getDefaultMix());
   rmAreaDefSetForestType(playerForestDefID, cBiome.getRandomForest());
   rmAreaDefSetHeight(playerForestDefID, 0.5);
   rmAreaDefAddHeightBlend(playerForestDefID, cBlendEdge, cFilter5x5Box);
   rmAreaDefAddHeightConstraint(playerForestDefID, vDefaultAvoidLand);
   rmAreaDefSetBlobs(playerForestDefID, 4, 5);
   rmAreaDefSetBlobDistance(playerForestDefID, 10.0);
   rmAreaDefSetAvoidSelfDistance(playerForestDefID, startingForestAvoidSelfDist);
   rmAreaDefAddConstraint(playerForestDefID, rmCreateTypeDistanceConstraint(cUnitTypeTree, 16.0));
   rmAreaDefAddConstraint(playerForestDefID, vDefaultAvoidImpassableLand8);
   rmAreaDefAddConstraint(playerForestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(playerForestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddConstraint(playerForestDefID, vDefaultAvoidSettlementWithFarm);

   if(gameIs1v1() == true)
   {
      addSimAreaLocsPerPlayerPair(playerForestDefID, xsRandInt(2, 3), cStartingForestMinDist, cStartingForestMaxDist, startingForestOriginAvoidSelfDist);
   }
   else
   {
      addAreaLocsPerPlayer(playerForestDefID, xsRandInt(2, 3), cStartingForestMinDist, cStartingForestMaxDist, startingForestOriginAvoidSelfDist);
   }

   // If this fails it means we likely have plenty of nearby forests anyway.
   generateLocs("starting forest locs", cFinalBuild == false);

   // Stragglers.
   placeStartingStragglers(cBiome.getRandomTree());

   rmSetProgress(0.6);

   // Gold.
   float avoidGoldMeters = 10.0 * xsRandInt(3, 4);

   // Close gold.
   int closeGoldID = rmObjectDefCreate("close gold");
   rmObjectDefAddItem(closeGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(closeGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(closeGoldID, 50.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeGoldID, false, xsRandInt(1, 2), 50.0, 80.0, avoidGoldMeters);
   }
   else
   {
      addObjectLocsPerPlayer(closeGoldID, false, xsRandInt(1, 2), 50.0, 80.0, avoidGoldMeters);
   }

   // Bonus gold.
   int bonusGoldID = rmObjectDefCreate("bonus gold");
   rmObjectDefAddItem(bonusGoldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusGoldID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(bonusGoldID, 50.0);

   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(bonusGoldID, false, xsRandInt(2, 4) * getMapAreaSizeFactor(), 50.0, -1.0, avoidGoldMeters);
   }
   else
   {
      addObjectLocsPerPlayer(bonusGoldID, false, xsRandInt(2, 4) * getMapAreaSizeFactor(), 50.0, -1.0, avoidGoldMeters);
   }

   generateLocs("gold locs");

   buildAreaDefUnderObjectDef(closeGoldID, islandDefID, resourceIslandSize);
   buildAreaDefUnderObjectDef(bonusGoldID, islandDefID, resourceIslandSize);

   // Hunt.
   int[] huntDefs = new int(0, 0);
   float avoidHuntMeters = 10.0 * xsRandInt(3, 5);

   // Close hunt.
   int numCloseHunt = xsRandInt(1, 2);

   for(int i = 0; i < numCloseHunt; i++)
   {   
      int huntCapacity = (xsRandBool(0.5) == true) ? xsRandInt(900, 1800) : xsRandInt(900, 2700);
      HuntContainer huntContainer = cBiome.getRandomHunt(huntCapacity, cHuntFlagsDefault);

      int closeHuntID = rmObjectDefCreate("close hunt " + i);
      huntContainer.addToObjectDef(closeHuntID);
      rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidImpassableLand);
      rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidSettlementRange);
      addObjectDefPlayerLocConstraint(closeHuntID, 50.0);

      if(gameIs1v1() == true)
      {
         addSimObjectLocsPerPlayerPair(closeHuntID, false, 1, 50.0, 80.0, avoidHuntMeters);
      }
      else
      {
         addObjectLocsPerPlayer(closeHuntID, false, 1, 50.0, 80.0, avoidHuntMeters);
      }

      huntDefs.add(closeHuntID);
   }

   // Bonus hunt.
   int numBonusHunt = xsRandInt(1, 4) * getMapAreaSizeFactor();
   for(int i = 0; i < numBonusHunt; i++)
   {
      int huntCapacity = (xsRandBool(0.5) == true) ? xsRandInt(900, 1800) : xsRandInt(900, 2700);
      HuntContainer huntContainer = cBiome.getRandomHunt(huntCapacity, cHuntFlagsDefault);

      int bonusHuntID = rmObjectDefCreate("bonus hunt " + i);
      huntContainer.addToObjectDef(bonusHuntID);
      rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(bonusHuntID, vDefaultFoodAvoidImpassableLand);
      rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(bonusHuntID, vDefaultAvoidSettlementRange);
      addObjectDefPlayerLocConstraint(bonusHuntID, 50.0);

      if(gameIs1v1() == true)
      {
         addSimObjectLocsPerPlayerPair(bonusHuntID, false, 1, 50.0, -1.0, avoidHuntMeters);
      }
      else
      {
         addObjectLocsPerPlayer(bonusHuntID, false, 1, 50.0, -1.0, avoidHuntMeters);
      }

      huntDefs.add(bonusHuntID);
   }

   generateLocs("hunt locs");

   int numHuntDefs = huntDefs.size();
   for(int i = 0; i < numHuntDefs; i++)
   {
      buildAreaDefUnderObjectDef(huntDefs[i], islandDefID, resourceIslandSize);
   }

   // Berries.
   int[] berryDefs = new int(0, 0);

   // Don't place them if we have a Hades biome.
   if(cBiome.mID == cBiomeHadesID)
   {
      float avoidBerriesMeters = 30.0;
      int berriesAvoidCenterPaths = rmCreateClassDistanceConstraint(cCenterPathClassID, 5.0);

      int numBerries = xsRandInt(1, 3) * getMapAreaSizeFactor();
      for(int i = 0; i < numBerries; i++)
      {
         int berriesID = rmObjectDefCreate("berries " + i);
         rmObjectDefAddItem(berriesID, cUnitTypeBerryBush, xsRandInt(6, 12), cBerryClusterRadius);
         rmObjectDefAddConstraint(berriesID, vDefaultAvoidEdge);
         rmObjectDefAddConstraint(berriesID, vDefaultBerriesAvoidAll);
         rmObjectDefAddConstraint(berriesID, vDefaultBerriesAvoidImpassableLand);
         rmObjectDefAddConstraint(berriesID, vDefaultAvoidTowerLOS);
         rmObjectDefAddConstraint(berriesID, vDefaultAvoidSettlementRange);
         addObjectDefPlayerLocConstraint(berriesID, 70.0);
         // rmObjectDefAddConstraint(berriesID, berriesAvoidCenterPaths);

         addObjectLocsPerPlayer(berriesID, false, 1, 70.0, -1.0, avoidBerriesMeters);

         berryDefs.add(berriesID);
      }

      generateLocs("berries locs");
   }

   int numBerryDefs = berryDefs.size();
   for(int i = 0; i < numBerryDefs; i++)
   {
      buildAreaDefUnderObjectDef(berryDefs[i], islandDefID, resourceIslandSize);
   }

   // Herdables.
   int[] herdDefs = new int(0, 0);
   float avoidHerdMeters = 30.0;

   // Close herd.
   int numCloseHerd = xsRandInt(1, 2) * getMapAreaSizeFactor();
   for(int i = 0; i < numCloseHerd; i++)
   {
      int closeHerdID = rmObjectDefCreate("close herd " + i);
      rmObjectDefAddItem(closeHerdID, herdType, xsRandInt(1, 2));
      rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidAll);
      rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidImpassableLand);
      rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidTowerLOS);
      addObjectDefPlayerLocConstraint(closeHerdID, 50.0);

      addObjectLocsPerPlayer(closeHerdID, false, 1, 50.0, 70.0, avoidHerdMeters);

      herdDefs.add(closeHerdID);
   }

   // Bonus herd.
   int numBonusHerd = xsRandInt(1, 3) * getMapAreaSizeFactor();
   for(int i = 0; i < numBonusHerd; i++)
   {
      int bonusHerdID = rmObjectDefCreate("bonus herd " + i);
      rmObjectDefAddItem(bonusHerdID, herdType, xsRandInt(1, 3));
      rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidAll);
      rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidImpassableLand);
      rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidTowerLOS);
      addObjectDefPlayerLocConstraint(bonusHerdID, 70.0);

      addObjectLocsPerPlayer(bonusHerdID, false, 1, 70.0, -1.0, avoidHerdMeters);

      herdDefs.add(bonusHerdID);
   }

   generateLocs("herd locs");

   int numHerdDefs = herdDefs.size();
   for(int i = 0; i < numHerdDefs; i++)
   {
      buildAreaDefUnderObjectDef(herdDefs[i], islandDefID, resourceIslandSize);
   }

   // Predators.
   int[] predDefs = new int(0, 0);
   float avoidPredatorMeters = 30.0;

   int numPredators = xsRandInt(1, 3) * getMapAreaSizeFactor();
   for(int i = 0; i < numPredators; i++)
   {
      int predatorID = rmObjectDefCreate("predator " + i);
      rmObjectDefAddItem(predatorID, cBiome.getRandomPredator(), xsRandInt(1, 2));
      rmObjectDefAddConstraint(predatorID, vDefaultAvoidEdge);
      rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidImpassableLand);
      rmObjectDefAddConstraint(predatorID, vDefaultAvoidTowerLOS);
      rmObjectDefAddConstraint(predatorID, vDefaultAvoidSettlementRange);
      addObjectDefPlayerLocConstraint(predatorID, 70.0);

      addObjectLocsPerPlayer(predatorID, false, 1, 70.0, -1.0, avoidPredatorMeters);

      predDefs.add(predatorID);
   }

   generateLocs("predator locs");

   int numPredDefs = predDefs.size();
   for(int i = 0; i < numPredDefs; i++)
   {
      buildAreaDefUnderObjectDef(predDefs[i], islandDefID, resourceIslandSize);
   }

   // Relics.
   float avoidRelicMeters = 60.0;

   int numRelicsPerPlayer = (xsRandBool(0.9) == true) ? 2 * getMapAreaSizeFactor() : 3 * getMapAreaSizeFactor();
   int actualRelicsPerPlayer = min(numRelicsPerPlayer * cNumberPlayers, cMaxRelics) / cNumberPlayers;

   int relicSiteID = rmObjectDefCreate("relic site");
   rmObjectDefAddConstraint(relicSiteID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(relicSiteID, vDefaultRelicAvoidAll);
   rmObjectDefAddConstraint(relicSiteID, vDefaultRelicAvoidImpassableLand);
   rmObjectDefAddConstraint(relicSiteID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(relicSiteID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(relicSiteID, 50.0);

   addObjectLocsPerPlayer(relicSiteID, false, actualRelicsPerPlayer, 50.0, -1.0, avoidRelicMeters);

   generateLocs("relic site locs");

   int[] relicSiteIDs = rmObjectDefGetCreatedObjects(relicSiteID);
   int numRelicSites = relicSiteIDs.size();

   int relicID = rmObjectDefCreate("relic");
   rmObjectDefAddItem(relicID, cUnitTypeRelic, 1);

   bool fancyRelics = xsRandBool(0.5);

   if(fancyRelics == true)
   {
      // Shrines and potentially also statues.
      bool fancyStatues = xsRandBool(0.5);

      // Fancy relics.
      for(int i = 0; i < numRelicSites; i++)
      {
         vector siteLoc = rmObjectGetLoc(relicSiteIDs[i]);

         float shrineAngle = xsRandFloat(0.75, 1.75) * cPi;
         
         int shrineID = rmObjectCreate("shrine " + i);
         rmObjectAddItem(shrineID, cUnitTypeShrine);
         rmObjectSetItemRotation(shrineID, 0, cItemRotateCustom, shrineAngle);
         rmObjectPlaceAtLoc(shrineID, 0, siteLoc);

         // Take the actual loc we placed the shrine at.
         siteLoc = rmObjectGetCentroidLoc(shrineID);
         vector shrineMeters = rmFractionToMeters(siteLoc);

         if(fancyStatues == true)
         {
            if(xsRandBool(0.5) == true)
            {
               vector rightStatueMeters = shrineMeters.translateXZ(5.0, shrineAngle + 0.5 * cPi);
               vector leftStatueMeters = shrineMeters.translateXZ(5.0, shrineAngle - 0.5 * cPi);

               int statueID = rmObjectDefCreate("statue " + i);
               rmObjectDefAddItem(statueID, cUnitTypeStatueMajorGod);
               // Those are rotated differently so we need to offset slightly.
               rmObjectDefSetItemRotation(statueID, 0, cItemRotateCustom, shrineAngle - cPiOver2);
               rmObjectDefPlaceAtLoc(statueID, 0, rmMetersToFraction(rightStatueMeters));
               rmObjectDefPlaceAtLoc(statueID, 0, rmMetersToFraction(leftStatueMeters));
            }
            else
            {
               vector centerStatueMeters = shrineMeters.translateXZ(5.0, shrineAngle - 0.25 * cPi);

               int statueID = rmObjectDefCreate("statue " + i);
               rmObjectDefAddItem(statueID, cUnitTypeStatueMajorGod);
               // Those are rotated differently so we need to offset slightly.
               rmObjectDefSetItemRotation(statueID, 0, cItemRotateCustom, shrineAngle - cPiOver2);
               rmObjectDefPlaceAtLoc(statueID, 0, rmMetersToFraction(centerStatueMeters));
            }
         }
         
         vector relicMeters = shrineMeters.translateXZ(5.0, shrineAngle + xsRandFloat(-0.2, 0.2) * cPi);

         rmObjectDefPlaceAtLoc(relicID, 0, rmMetersToFraction(relicMeters));

         int numRelicEmbellishments = xsRandInt(0, 4);
         int siteEmbellishmentID = rmObjectCreate("site embellishment " + i);
         for(int j = 0; j < numRelicEmbellishments; j++)
         {
            int embellishmentItemIdx = rmObjectAddItem(siteEmbellishmentID, cBiome.mShrineEmbellishmentCandidates.roll(), 1, 6.0);
            rmObjectSetItemRotation(siteEmbellishmentID, embellishmentItemIdx, cItemRotateCustom, shrineAngle + 0.5 * cPi * xsRandInt(0, 3));
         }
         rmObjectPlaceAtLoc(siteEmbellishmentID, 0, siteLoc);
      }
   }
   else
   {
      // Simple relics.
      for(int i = 0; i < numRelicSites; i++)
      {
         vector siteLoc = rmObjectGetLoc(relicSiteIDs[i]);
         rmObjectDefPlaceAtLoc(relicID, 0, siteLoc);

         int numRelicEmbellishments = xsRandInt(3, 5);
         int siteEmbellishmentID = rmObjectCreate("site embellishment " + i);
         for(int j = 0; j < numRelicEmbellishments; j++)
         {
            int embellishmentItemIdx = rmObjectAddItem(siteEmbellishmentID, cBiome.mShrineEmbellishmentCandidates.roll(), 1, 4.0);
            rmObjectSetItemRotation(siteEmbellishmentID, embellishmentItemIdx, cItemRotateCardinal);
         }
         rmObjectPlaceAtLoc(siteEmbellishmentID, 0, siteLoc);
      }
   }

   buildAreaDefUnderObjectDef(relicSiteID, islandDefID, resourceIslandSize);

   rmSetProgress(0.7);

   int tileWithTreeConstraint = rmCreateTypeMaxDistanceConstraint(cUnitTypeTree, 0.0);
   int numTrees = getNumberAcceptableTilesForConstraint(tileWithTreeConstraint);
   int numTreesPerPlayer = numTrees / cNumberPlayers;
   bool hasSufficientWood = (numTreesPerPlayer >= 300);

   float minTreeDist = 0.0;

   int forestDefID = rmAreaDefCreate("global forest");
   if(hasSufficientWood == false)
   {
      // TODO Vary between rather large, rather small, and a mix of sizes.
      rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(40), rmTilesToAreaFraction(120));
      minTreeDist = xsRandFloat(25.0, 35.0);
   }
   else
   {
      rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(40), rmTilesToAreaFraction(60));
      minTreeDist = xsRandFloat(35.0, 45.0);
   }
   rmAreaDefSetAvoidSelfDistance(forestDefID, minTreeDist);
   rmAreaDefSetMix(forestDefID, cBiome.getDefaultMix());
   rmAreaDefSetForestType(forestDefID, cBiome.getRandomForest());
   rmAreaDefSetHeight(forestDefID, 0.5);
   rmAreaDefAddHeightBlend(forestDefID, cBlendEdge, cFilter5x5Box);
   rmAreaDefAddHeightConstraint(forestDefID, vDefaultAvoidLand);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidImpassableLand8);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(forestDefID, rmCreateTypeDistanceConstraint(cUnitTypeTree, minTreeDist));
   rmAreaDefAddConstraint(forestDefID, rmCreateClassDistanceConstraint(cCenterPathClassID, 6.0));

   // Avoid the owner paths to prevent forests from closing off resources.
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidOwnerPaths, 0.0);
   // rmAreaDefSetConstraintBuffer(forestDefID, 0.0, 6.0);

   // Build for each player in the team area.
   // Don't paint them yet so our tree constraint doesn't affect the new areas.
   buildAreaDefInTeamAreas(forestDefID, 10 * getMapAreaSizeFactor(), true, false, false);

   // Paint them.
   rmAreaPaintAll();

   rmSetProgress(0.8);

   // Fish.
   if(xsRandBool(1.0) == true)
   {
      // Find out how many water tiles we have.
      int fishMinWaterDepth = rmCreateMinWaterDepthConstraint(0.75);
      int fishAvoidLand = rmCreatePassabilityDistanceConstraint(cPassabilityWater, false, 6.0);

      int[] fishConstraints = new int(0, 0);
      fishConstraints.add(fishMinWaterDepth);
      fishConstraints.add(fishAvoidLand);
      fishConstraints.add(vDefaultAvoidEdge);

      int numAcceptableFishTiles = getNumberAcceptableTilesForConstraints(fishConstraints);

      rmGenerationAddLogLine("numAcceptableFishTiles = " + numAcceptableFishTiles);

      int fishID = rmObjectDefCreate("fish");

      int maxNumFishPerPlayer = min(7, numAcceptableFishTiles / (150 * cNumberPlayers));
      int minNumFishPerPlayer = maxNumFishPerPlayer;
      // int minNumFishPerPlayer = min(3, maxNumFishPerPlayer);
      float fishDistMeters = 20.0;

      if(gameIs1v1() == true)
      {
         rmObjectDefAddItem(fishID, cBiome.getRandomFish(), 3, 6.0);
         rmObjectDefAddConstraint(fishID, fishMinWaterDepth, cObjectConstraintBufferNone);
         rmObjectDefAddConstraint(fishID, fishAvoidLand, cObjectConstraintBufferNone);
         rmObjectDefAddConstraint(fishID, vDefaultAvoidEdge);
         addMirroredObjectLocsPerPlayerPair(fishID, false, xsRandInt(minNumFishPerPlayer, maxNumFishPerPlayer), 20.0, -1.0, fishDistMeters);

         generateLocs("fish locs", false, true, false);
      }
      else if(gameIsFair() == true)
      {
         rmObjectDefAddItem(fishID, cBiome.getRandomFish(), 3, 6.0);
         rmObjectDefAddConstraint(fishID, fishMinWaterDepth, cObjectConstraintBufferNone);
         rmObjectDefAddConstraint(fishID, fishAvoidLand, cObjectConstraintBufferNone);
         rmObjectDefAddConstraint(fishID, vDefaultAvoidEdge);
         addMirroredObjectLocsPerPlayerPair(fishID, false, xsRandInt(minNumFishPerPlayer, maxNumFishPerPlayer), 20.0, -1.0, fishDistMeters);

         generateLocs("fish locs", false, true, false);
      }
      else
      {
         rmObjectDefAddItem(fishID, cBiome.getRandomFish(), 3, 6.0);
         rmObjectDefAddConstraint(fishID, fishMinWaterDepth, cObjectConstraintBufferNone);
         rmObjectDefAddConstraint(fishID, fishAvoidLand, cObjectConstraintBufferNone);
         rmObjectDefAddConstraint(fishID, vDefaultAvoidEdge);
         rmObjectDefAddConstraint(fishID, rmCreateTypeDistanceConstraint(cUnitTypeFishResource, fishDistMeters));
         rmObjectDefPlaceAnywhere(fishID, 0, 5 * cNumberPlayers * getMapAreaSizeFactor());
      }

      // TODO Fish barrels.

      revealClosestObjectPerPlayer(fishID, 12.0, false);
   }

   // Beautification.
   int avoidDeepWater = rmCreateMaxWaterDepthConstraint(1.0);

   // Random trees (duplicates allowed).
   int numRandomTrees = xsRandInt(2, 8) * cNumberPlayers * getMapAreaSizeFactor();
   int numTreeTypes = xsRandInt(1, 4);
   int numTreesPerType = ceil(xsIntToFloat(numRandomTrees) / numTreeTypes);

   for(int i = 0; i < numTreeTypes; i++)
   {
      int randomTreeID = rmObjectDefCreate("random tree " + i);
      rmObjectDefAddItem(randomTreeID, cBiome.getRandomTree(), 1);
      rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidAll);
      rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidCollideable);
      rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidImpassableLand);
      rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidTree);
      rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidSettlementWithFarm);
      rmObjectDefAddConstraint(randomTreeID, avoidDeepWater);
      rmObjectDefPlaceAnywhere(randomTreeID, 0, numTreesPerType);
   }

   // Place all the embellishment.
   // Areas under stuff.
   // Gold.
   buildAreaUnderObjectDef(startingGoldID, cBiome.mInnerGoldTerrainID, cBiome.mOuterGoldTerrainID, 8.0);
   buildAreaUnderObjectDef(closeGoldID, cBiome.mInnerGoldTerrainID, cBiome.mOuterGoldTerrainID, 8.0);
   buildAreaUnderObjectDef(bonusGoldID, cBiome.mInnerGoldTerrainID, cBiome.mOuterGoldTerrainID, 8.0);

   // Berries.
   buildAreaUnderObjectDef(startingBerriesID, cBiome.mInnerBerryTerrainID, cBiome.mOuterBerryTerrainID, 8.0);
   for(int i = 0; i < numBerryDefs; i++)
   {
      buildAreaUnderObjectDef(berryDefs[i], cBiome.mInnerBerryTerrainID, cBiome.mOuterBerryTerrainID, 10.0);
   }

   // Rocks around gold.
   int goldRocksID = rmObjectDefCreate("gold rocks");
   rmObjectDefAddItemRange(goldRocksID, cUnitTypeRockGoldSmall, 2, 4, 2.0, 3.0);
   rmObjectDefAddItemRange(goldRocksID, cUnitTypeRockGoldTiny, 2, 4, 2.0, 3.0);

   placeObjectDefAtObjectDef(startingGoldID, goldRocksID);
   placeObjectDefAtObjectDef(closeGoldID, goldRocksID);
   placeObjectDefAtObjectDef(bonusGoldID, goldRocksID);

   // Relics.
   // Use road 2 for the edge
   if(fancyRelics == true)
   {
      buildAreaUnderObjectDef(relicSiteID, cBiome.mTerrainRoad2, cBiome.mTerrainRoad2, 8.0);
   }
   else
   {
      buildAreaUnderObjectDef(relicSiteID, cBiome.mTerrainRoad2, cBiome.mTerrainRoad2, 4.0);
   }

   // Make some random roads.
   if(xsRandBool(1.0 / 3.0) == true)
   {
      int pathDefID = rmPathDefCreate("embellishment road path");
      rmPathDefSetCostNoise(pathDefID, 0.0, 5.0);
      rmPathDefAddConstraint(pathDefID, vDefaultAvoidWater8);
      rmPathDefAddConstraint(pathDefID, vDefaultAvoidImpassableLand4);
      rmPathDefAddConstraint(pathDefID, rmCreateTypeDistanceConstraint(cUnitTypeFood, 4.0));
      rmPathDefAddConstraint(pathDefID, rmCreateTypeDistanceConstraint(cUnitTypeTree, 4.0));
      rmPathDefAddConstraint(pathDefID, rmCreateTypeDistanceConstraint(cUnitTypeGoldResource, 4.0));

      int pathAreaDefID = rmAreaDefCreate("embellishment road area");
      rmAreaDefSetTerrainType(pathAreaDefID, cBiome.mTerrainRoad2);

      for(int i = 0; i < cNumberPlayers; i++)
      {
         int pathID = rmPathDefCreatePath(pathDefID);
         // For now, always add two random waypoints.
         rmPathAddRandomWaypoint(pathID);
         rmPathAddRandomWaypoint(pathID);
         rmPathBuild(pathID);

         int areaID = rmAreaDefCreateArea(pathAreaDefID);
         rmAreaSetPath(areaID, pathID);
         rmAreaBuild(areaID);
      }
   }

   rmSetProgress(0.9);

   // Rare embellishment; choose some randomly (but not more than once).
   WeightedIntRandomizer rareRandomizer = copyWeightedIntRandomizer(cBiome.mRareEmbellishmentCandidates);
   int numRareEmbellishment = xsRandInt(0, rareRandomizer.size());

   for(int i = 0; i < numRareEmbellishment; i++)
   {
      int embellishmentProtoID = rareRandomizer.rollAndRemove();
      int embellishmentID = rmObjectDefCreate("rare embellishment " + i);
      rmObjectDefAddItem(embellishmentID, embellishmentProtoID, 1);
      rmObjectDefAddConstraint(embellishmentID, vDefaultEmbellishmentAvoidAll);
      rmObjectDefAddConstraint(embellishmentID, vDefaultAvoidImpassableLand);
      rmObjectDefAddConstraint(embellishmentID, vDefaultAvoidWater);
      rmObjectDefPlaceAnywhere(embellishmentID, 0, xsRandInt(0, 5) * cNumberPlayers * getMapAreaSizeFactor());
   }

   // Misc embellishment; choose some randomly (but not more than once).
   WeightedIntRandomizer miscRandomizer = copyWeightedIntRandomizer(cBiome.mMiscEmbellishmentCandidates);
   int numMiscEmbellishment = xsRandInt(0, miscRandomizer.size());

   for(int i = 0; i < numMiscEmbellishment; i++)
   {
      int embellishmentProtoID = miscRandomizer.rollAndRemove();
      int embellishmentID = rmObjectDefCreate("misc embellishment " + i);
      rmObjectDefAddItemRange(embellishmentID, embellishmentProtoID, 1, xsRandInt(1, 3), 0.0, 4.0);
      rmObjectDefAddConstraint(embellishmentID, vDefaultEmbellishmentAvoidAll);
      rmObjectDefAddConstraint(embellishmentID, vDefaultAvoidImpassableLand);
      rmObjectDefAddConstraint(embellishmentID, vDefaultAvoidWater);
      rmObjectDefPlaceAnywhere(embellishmentID, 0, xsRandInt(0, 40) * cNumberPlayers * getMapAreaSizeFactor());
   }

   // Plants and rocks. Place all of them, but heavily randomize quantities.
   int[] plantEmbellishments = cBiome.getPlantEmbellishments();
   int numPlantEmbellishments = plantEmbellishments.size();

   for(int i = 0; i < numPlantEmbellishments; i++)
   {
      int embellishmentID = rmObjectDefCreate("plant embellishment " + i);
      rmObjectDefAddItemRange(embellishmentID, plantEmbellishments[i], 1, xsRandInt(1, 3), 0.0, 4.0);
      rmObjectDefAddConstraint(embellishmentID, vDefaultEmbellishmentAvoidAll);
      rmObjectDefAddConstraint(embellishmentID, vDefaultAvoidImpassableLand);
      rmObjectDefAddConstraint(embellishmentID, vDefaultAvoidWater);
      rmObjectDefPlaceAnywhere(embellishmentID, 0, xsRandInt(0, 40) * cNumberPlayers * getMapAreaSizeFactor());
   }

   // Place all the rock embellishment.
   int[] rockEmbellishments = cBiome.getRockEmbellishments();
   int numRockEmbellishments = rockEmbellishments.size();

   for(int i = 0; i < numRockEmbellishments; i++)
   {
      int embellishmentID = rmObjectDefCreate("rock embellishment " + i);
      rmObjectDefAddItemRange(embellishmentID, rockEmbellishments[i], 1, xsRandInt(1, 3), 0.0, 4.0);
      rmObjectDefAddConstraint(embellishmentID, vDefaultEmbellishmentAvoidAll);
      rmObjectDefAddConstraint(embellishmentID, vDefaultAvoidImpassableLand);
      rmObjectDefAddConstraint(embellishmentID, avoidDeepWater);
      rmObjectDefPlaceAnywhere(embellishmentID, 0, xsRandInt(0, 40) * cNumberPlayers * getMapAreaSizeFactor());
   }

   // Water stuff.
   // Check if we have any water, otherwise don't do the expensive scanning.
   if(hasAnyWaterTiles() == true)
   {
      // Shallow constraints.
      int shallowMinDepthConstraintID = rmCreateMinWaterDepthConstraint(cFloatEpsilon);
      int shallowMaxDepthConstraintID = rmCreateMaxWaterDepthConstraint(1.0);

      // First, do shore stuff.
      if(cBiome.mShoreEmbellishmentCandidates.empty() == false)
      {
         // Yes we're too lazy to initialize this to the proper size and just do adds.
         int[] shoreConstraints = new int(0, 0);
         // shoreConstraints.add(vDefaultEmbellishmentAvoidAll);
         shoreConstraints.add(vDefaultAvoidImpassableLand);
         shoreConstraints.add(shallowMinDepthConstraintID);
         shoreConstraints.add(shallowMaxDepthConstraintID);
         // Also force this near land.
         shoreConstraints.add(rmCreateWaterMaxDistanceConstraint(false, 6.0));

         WeightedIntRandomizer shoreRandomizer = copyWeightedIntRandomizer(cBiome.mShoreEmbellishmentCandidates);

         placeWaterEmbellishment("shore embellishment", shoreRandomizer, shoreConstraints, xsRandFloat(0.1, 0.4));
      }

      // Then, do shallow stuff.
      if(cBiome.mShallowWaterEmbellishmentCandidates.empty() == false)
      {
         int[] shallowConstraints = new int(0, 0);
         // shallowConstraints.add(vDefaultEmbellishmentAvoidAll);
         shallowConstraints.add(vDefaultAvoidImpassableLand);
         shallowConstraints.add(shallowMinDepthConstraintID);
         shallowConstraints.add(shallowMaxDepthConstraintID);
         // Force this away from land.
         shallowConstraints.add(rmCreateWaterDistanceConstraint(false, 6.0));

         WeightedIntRandomizer shallowRandomizer = copyWeightedIntRandomizer(cBiome.mShallowWaterEmbellishmentCandidates);

         placeWaterEmbellishment("shallow embellishment", shallowRandomizer, shallowConstraints, xsRandFloat(0.025, 0.05));
      }

      // Then, do deep stuff.
      if(cBiome.mDeepWaterEmbellishmentCandidates.empty() == false)
      {
         int[] deepConstraints = new int(0, 0);
         // deepConstraints.add(vDefaultEmbellishmentAvoidAll);
         deepConstraints.add(rmCreateMinWaterDepthConstraint(1.5));
         // deepConstraints.add(rmCreateMaxWaterDepthConstraint(2.5));

         WeightedIntRandomizer deepRandomizer = copyWeightedIntRandomizer(cBiome.mDeepWaterEmbellishmentCandidates);

         placeWaterEmbellishment("deep embellishment", deepRandomizer, deepConstraints, xsRandFloat(0.05, 0.1));
      }
   }

   // Birds.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cBiome.getRandomBird(), 1);
   rmObjectDefPlaceAnywhere(birdID, 0, xsRandInt(2, 3) * cNumberPlayers * getMapAreaSizeFactor());

   rmSetProgress(1.0);
}

void generate()
{
   generateInternal();
}
