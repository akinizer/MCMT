include "lib2/rm_core.xs";

mutable void applySuddenDeath()
{
   // Override and do nothing here for Sudden Death.
}

// TODO Have this as a library function that we can override so we don't have to call it.
void generateTriggers()
{
   rmTriggerAddScriptLine("const string cGPCeaseFire = \"CeaseFire3Minutes\";");
   rmTriggerAddScriptLine("const string cSettlement = \"Settlement\";");
   rmTriggerAddScriptLine("const string cTownCenter = \"TownCenter\";");

   rmTriggerAddScriptLine("");

   rmTriggerAddScriptLine("rule _ceasefire");
   rmTriggerAddScriptLine("highFrequency");
   rmTriggerAddScriptLine("active");
   rmTriggerAddScriptLine("{");
   rmTriggerAddScriptLine("   trGodPowerInvoke(0, cGPCeaseFire, vector(" + rmXFractionToMeters(0.5) + ", 0.0, " + rmZFractionToMeters(0.5) + "), vector(0.0, 0.0, 0.0));");
   rmTriggerAddScriptLine("   xsDisableSelf();");
   rmTriggerAddScriptLine("}");
   
   rmTriggerAddScriptLine("rule _town_center_build_rate");
   rmTriggerAddScriptLine("highFrequency");
   rmTriggerAddScriptLine("active");
   rmTriggerAddScriptLine("{");
   rmTriggerAddScriptLine("   for(int i = 1; i <= cNumberPlayers; i++)");
   rmTriggerAddScriptLine("   {");
   rmTriggerAddScriptLine("      trModifyProtounitData(cSettlement, i, 4, 0.25, 3);");
   rmTriggerAddScriptLine("      trModifyProtounitData(cTownCenter, i, 4, 0.25, 3);");
   rmTriggerAddScriptLine("   }");
   rmTriggerAddScriptLine("   xsDisableSelf();");
   rmTriggerAddScriptLine("}");

   rmTriggerAddScriptLine("rule _town_center_restore_rate");
   rmTriggerAddScriptLine("highFrequency");
   rmTriggerAddScriptLine("active");
   rmTriggerAddScriptLine("{");
   rmTriggerAddScriptLine("   if (((xsGetTime() - (cActivationTime / 1000)) >= 180))");
   rmTriggerAddScriptLine("   {");
   rmTriggerAddScriptLine("      for(int i = 1; i <= cNumberPlayers; i++)");
   rmTriggerAddScriptLine("      {");
   rmTriggerAddScriptLine("         trModifyProtounitData(cSettlement, i, 4, 1.75, 3);");
   rmTriggerAddScriptLine("         trModifyProtounitData(cTownCenter, i, 4, 1.75, 3);");
   rmTriggerAddScriptLine("      }");
   rmTriggerAddScriptLine("      xsDisableSelf();");
   rmTriggerAddScriptLine("   }");
   rmTriggerAddScriptLine("}");

   rmTriggerAddScriptLine("rule _lightset");
   rmTriggerAddScriptLine("highFrequency");
   rmTriggerAddScriptLine("active");
   rmTriggerAddScriptLine("{");
   rmTriggerAddScriptLine("   trSetLighting(\"" + cLightingSetRmNomad02 + "\", 180.0);");
   rmTriggerAddScriptLine("   xsDisableSelf();");
   rmTriggerAddScriptLine("}");
}

void generate()
{
   rmSetProgress(0.0);

   // Set up random biome "library".
   int forestType = 0;
   int treeType = 0;
   int seaType = 0;
   int natureCiv = 0;
   int cliffType = 0;
   int berryTerrain1 = 0;
   int berryTerrain2 = 0;
   
   // Animals.
   int smallHuntType1 = 0;
   int smallHuntType2 = 0;
   int bigHuntType1 = 0;
   int bigHuntType2 = 0;
   int herdType = 0;

   // Mixes are customized differently per biome.
   int baseMixID = rmCustomMixCreate();

   int biome = xsRandInt(0, 1);

   // 0 is Greek, 1 is Egyptian. Can expand this way if desired.
   if (biome == 0)
   {
      seaType = cWaterGreekSeaAegean;
      forestType = cForestGreekMediterraneanDirt;
      treeType = cUnitTypeTreeOak;
      natureCiv = cCultureGreek;
      cliffType = cCliffGreekGrass;
      berryTerrain1 = cTerrainGreekGrass2;
      berryTerrain2 = cTerrainGreekGrassDirt1;

      smallHuntType1 = cUnitTypeDeer;
      smallHuntType2 = cUnitTypeGazelle;
      bigHuntType1 = cUnitTypeAurochs;
      bigHuntType2 = cUnitTypeBoar;

      if (xsRandBool(0.5) == true)
      {
         herdType = cUnitTypeCow;
      }
      else
      {
         herdType = cUnitTypePig;
      }
   
      // Define mixes.
      rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.3, 2);
      rmCustomMixAddPaintEntry(baseMixID, cTerrainGreekGrass2, 3.0);
      rmCustomMixAddPaintEntry(baseMixID, cTerrainGreekGrass1, 4.0);
      rmCustomMixAddPaintEntry(baseMixID, cTerrainGreekGrassDirt1, 4.0);
      rmCustomMixAddPaintEntry(baseMixID, cTerrainGreekGrassDirt2, 3.0);
   }
   else if (biome == 1)
   {
      seaType = cWaterEgyptSea;
      forestType = cForestEgyptPalm;
      treeType = cUnitTypeTreePalm;
      natureCiv = cCultureEgyptian;
      cliffType = cCliffEgyptSand;
      berryTerrain1 = cTerrainEgyptGrassDirt1;
      berryTerrain2 = cTerrainEgyptGrassDirt2;

      smallHuntType1 = cUnitTypeZebra;
      smallHuntType2 = cUnitTypeGiraffe;
      bigHuntType1 = cUnitTypeWaterBuffalo;
      bigHuntType2 = cUnitTypeHippopotamus;

      if (xsRandBool(0.75) == true)
      {
         herdType = cUnitTypeGoat;
      }
      else
      {
         herdType = cUnitTypePig;
      }

      // Define mixes.
      rmCustomMixSetPaintParams(baseMixID, cNoiseRandom);
      rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptDirtRocks1, 1.0);
      rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptSand1, 3.0);
      rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptSand2, 3.0);
      rmCustomMixAddPaintEntry(baseMixID, cTerrainEgyptSand3, 3.0);
   }

 // Set size.
   int playerTiles=20000;
   int cNumberNonGaiaPlayers = 10;
   if(cMapSizeCurrent == 1)
   {
      playerTiles = 30000;
   }
   int size=2.0*sqrt(cNumberNonGaiaPlayers*playerTiles/0.9);
   rmSetMapSize(size, size);
   rmInitializeWater(seaType);

   // Player placement (doesn't matter here).
   rmPlacePlayersOnCircle(0.25);

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCivFromCulture(cCultureEgyptian);

   // Lighting.
   rmSetLighting(cLightingSetRmNomad01);

   rmSetProgress(0.1);

   // Random Spots to create a more varied looking nomad.
   int randomSpotsClassID = rmClassCreate();

   int avoidRandomSpots = rmCreateClassDistanceConstraint(randomSpotsClassID, 20.0);
   int numRandomSpots = cNumberPlayers * getMapAreaSizeFactor();
   
   for(int i = 0; i < cNumberPlayers; i++)
   {
      int randomSpotsID = rmAreaCreate("random spots " + i);

      rmAreaSetSize(randomSpotsID, xsRandFloat(0.01, 0.015));
      rmAreaSetCoherence(randomSpotsID, 0.25);
      rmAreaAddToClass(randomSpotsID, randomSpotsClassID);

      rmAreaAddConstraint(randomSpotsID, vDefaultAvoidEdge);
      rmAreaAddConstraint(randomSpotsID, avoidRandomSpots);
      rmAreaAddConstraint(randomSpotsID, rmCreateLocDistanceConstraint(cCenterLoc, rmXFractionToMeters(0.3)));

      rmAreaBuild(randomSpotsID);
   }

   // Continent.
   // This is a bit of an upper limit, but we're using this for placement only.
   float continentRadiusMeters = cSqrtTwo * rmXFractionToMeters(0.5);

   int continentID = rmAreaCreate("continent");
   rmAreaSetSize(continentID, 0.5);
   rmAreaSetLoc(continentID, cCenterLoc);
   rmAreaSetMix(continentID, baseMixID);

   rmAreaSetCoherence(continentID, 0.0);
   rmAreaSetHeight(continentID, 0.25);
   rmAreaSetHeightNoise(continentID, cNoiseFractalSum, 5.0, 0.1, 2, 0.5);
   rmAreaSetHeightNoiseBias(continentID, 1.0); // Grow upwards only.
   rmAreaSetHeightNoiseEdgeFalloffDist(continentID, 10.0); // Avoid shore.
   rmAreaAddHeightBlend(continentID, cBlendEdge, cFilter5x5Box, 5, 5);
   rmAreaSetEdgeSmoothDistance(continentID, 3);

   rmAreaSetBlobs(continentID, 2, 5);
   rmAreaSetBlobDistance(continentID, 15, 40);

   rmAreaAddConstraint(continentID, createSymmetricBoxConstraint(rmXMetersToFraction(15.0)), 0.0, 15.0);
   rmAreaAddConstraint(continentID, avoidRandomSpots, 0.0, 10.0);

   rmAreaBuild(continentID);

   rmSetProgress(0.2);

   // KotH.
   placeKotHObjects();

   // Unlike most other maps, this one places stuff randomly on the continent.
   // Settlements.

   int numSettlementsPerPlayer = 2 + (1 * getMapSizeBonusFactor());

   int settlementID = rmObjectDefCreate("settlement");
   rmObjectDefAddItem(settlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(settlementID, vDefaultSettlementAvoidImpassableLand);
   rmObjectDefAddConstraint(settlementID, vDefaultSettlementAvoidSiegeShipRange);
   rmObjectDefAddConstraint(settlementID, vDefaultAvoidKotH);
   addObjectLocsAtOrigin(settlementID, numSettlementsPerPlayer * cNumberPlayers, cCenterLoc,
                         0.0, continentRadiusMeters, 60.0);

   generateLocs("settlement locs");

   rmSetProgress(0.3);

   // Continent cliffs.
   int cliffClassID = rmClassCreate();
   int numCliffs = cNumberPlayers * getMapAreaSizeFactor();

   if(gameIs1v1() == true)
   {
      numCliffs *= xsRandInt(1, 3);
   }
   else
   {
      numCliffs *= xsRandInt(1, 2);
   }

   float cliffMinSize = rmTilesToAreaFraction(200);
   float cliffMaxSize = rmTilesToAreaFraction(300);

   int cliffAvoidCliff = rmCreateClassDistanceConstraint(cliffClassID, 25.0);

   for(int i = 0; i < numCliffs; i++)
   {
      int cliffID = rmAreaCreate("cliff " + i);
      rmAreaSetParent(cliffID, continentID);

      rmAreaSetSize(cliffID, xsRandFloat(cliffMinSize, cliffMaxSize));
      rmAreaSetMix(cliffID, baseMixID);
      rmAreaSetCliffType(cliffID, cliffType);
      if (xsRandBool(0.5) == true)
      {
         rmAreaSetCliffRamps(cliffID, 2, 0.3, 0.1, 1.0);
      }
      else
      {
         rmAreaSetCliffRamps(cliffID, 1, 0.5, 0.1, 1.0);
      }
      rmAreaSetCliffRampSteepness(cliffID, 2.0);
      rmAreaSetCliffEmbellishmentDensity(cliffID, 0.25);
      
      rmAreaSetHeightRelative(cliffID, 6.0);
      rmAreaAddHeightBlend(cliffID, cBlendAll, cFilter5x5Gaussian, 2);
      rmAreaSetEdgeSmoothDistance(cliffID, 10);
      rmAreaSetCoherence(cliffID, 0.25);

      rmAreaSetBlobs(cliffID, 3, 5);
      rmAreaSetBlobDistance(cliffID, 20.0, 40.0);

      rmAreaAddConstraint(cliffID, cliffAvoidCliff);
      rmAreaAddConstraint(cliffID, vDefaultAvoidWater16);
      rmAreaAddConstraint(cliffID, vDefaultAvoidSettlementWithFarm);
      rmAreaAddConstraint(cliffID, vDefaultAvoidKotH);
      rmAreaSetOriginConstraintBuffer(cliffID, 10.0);
      rmAreaAddToClass(cliffID, cliffClassID);

      rmAreaBuild(cliffID);
   }

   rmSetProgress(0.4);

   // Other stuff.
   // Gold.
   float avoidGoldMeters = 50.0;

   int goldID = rmObjectDefCreate("gold");
   rmObjectDefAddItem(goldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(goldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(goldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(goldID, vDefaultGoldAvoidWater);
   rmObjectDefAddConstraint(goldID, vDefaultAvoidSettlementRange);
   addObjectLocsAtOrigin(goldID, xsRandInt(4, 5) * getMapAreaSizeFactor() * cNumberPlayers , cCenterLoc,
                         0.0, continentRadiusMeters, avoidGoldMeters);

   generateLocs("gold locs");

   rmSetProgress(0.5);

   // Hunt.
   float avoidHuntMeters = 30.0;
   int numPreyHunt = xsRandInt(1, 2);

   for(int i = 0; i < numPreyHunt; i++)
   {
      float huntFloat = xsRandFloat(0.0, 1.0);
      int huntID = rmObjectDefCreate("prey hunt " + i);
      if(huntFloat < 1.0 / 5.0)
      {
         rmObjectDefAddItem(huntID, smallHuntType1, xsRandInt(3, 6));
         rmObjectDefAddItem(huntID, smallHuntType2, xsRandInt(3, 6));
      }
      else if(huntFloat < 2.0 / 5.0)
      {
         rmObjectDefAddItem(huntID, smallHuntType1, xsRandInt(1, 4));
         rmObjectDefAddItem(huntID, smallHuntType2, xsRandInt(2, 4));
      }
      else if(huntFloat < 3.0 / 5.0)
      {
         rmObjectDefAddItem(huntID, smallHuntType1, xsRandInt(1, 4));
         rmObjectDefAddItem(huntID, smallHuntType2, xsRandInt(2, 4));
      }
      else if(huntFloat < 4.0 / 5.0)
      {
         rmObjectDefAddItem(huntID, smallHuntType1, xsRandInt(3, 9));
      }
      else
      {
         rmObjectDefAddItem(huntID, smallHuntType2, xsRandInt(3, 9));
      }
      rmObjectDefAddConstraint(huntID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(huntID, vDefaultFoodAvoidImpassableLand);
      rmObjectDefAddConstraint(huntID, vDefaultFoodAvoidWater);
      rmObjectDefAddConstraint(huntID, vDefaultAvoidSettlementRange);
      addObjectLocsAtOrigin(huntID, getMapAreaSizeFactor() * cNumberPlayers, cCenterLoc,
                            0.0, continentRadiusMeters, avoidHuntMeters);
   }

   int numAggressiveHunt = xsRandInt(1, 2);

   for(int i = 0; i < numAggressiveHunt; i++)
   {
      float huntFloat = xsRandFloat(0.0, 1.0);
      int huntID = rmObjectDefCreate("aggro hunt " + i);
      if(huntFloat < 0.25)
      {
         rmObjectDefAddItem(huntID, bigHuntType1, xsRandInt(1, 2));
      }
      else if(huntFloat < 0.5)
      {
         rmObjectDefAddItem(huntID, bigHuntType2, xsRandInt(1, 2));
      }
      else if(huntFloat < 0.75)
      {
         rmObjectDefAddItem(huntID, bigHuntType1, xsRandInt(3, 5));
      }
      else
      {
         rmObjectDefAddItem(huntID, bigHuntType2, xsRandInt(2, 6));
      }
      rmObjectDefAddConstraint(huntID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(huntID, vDefaultFoodAvoidImpassableLand);
      rmObjectDefAddConstraint(huntID, vDefaultFoodAvoidWater);
      rmObjectDefAddConstraint(huntID, vDefaultAvoidSettlementRange);
      addObjectLocsAtOrigin(huntID, getMapAreaSizeFactor() * cNumberPlayers, cCenterLoc,
                            0.0, continentRadiusMeters, avoidHuntMeters);
   }

   generateLocs("hunt locs");

   rmSetProgress(0.6);

   // Berries.
   float avoidBerriesMeters = 50.0;

   int berriesID = rmObjectDefCreate("berries");
   rmObjectDefAddItem(berriesID, cUnitTypeBerryBush, xsRandInt(6, 11), cBerryClusterRadius);
   rmObjectDefAddConstraint(berriesID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(berriesID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(berriesID, vDefaultFoodAvoidWater);
   rmObjectDefAddConstraint(berriesID, vDefaultAvoidSettlementRange);
   addObjectLocsAtOrigin(berriesID, xsRandInt(1, 2) * getMapAreaSizeFactor() * cNumberPlayers, cCenterLoc,
                         0.0, continentRadiusMeters, avoidBerriesMeters);

   generateLocs("berry locs");

   // Herdables.
   float avoidHerdMeters = 20.0;
   int numHerd = xsRandInt(1, 3);

   for(int i = 0; i < numHerd; i++)
   {
      int herdID = rmObjectDefCreate("herd " + i);
      rmObjectDefAddItem(herdID, herdType, xsRandInt(1, 3));
      rmObjectDefAddConstraint(herdID, vDefaultFoodAvoidAll);
      rmObjectDefAddConstraint(herdID, vDefaultFoodAvoidImpassableLand);
      rmObjectDefAddConstraint(herdID, vDefaultFoodAvoidWater);
      addObjectLocsAtOrigin(herdID, getMapAreaSizeFactor() * cNumberPlayers, cCenterLoc,
                            0.0, continentRadiusMeters, avoidHerdMeters);
   }

   generateLocs("herd locs");

   // Relics.
   float avoidRelicMeters = 80.0;

   int relicID = rmObjectDefCreate("relic");
   rmObjectDefAddItem(relicID, cUnitTypeRelic, 1);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidAll);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidImpassableLand);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidWater);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidSettlementRange);
   addObjectLocsAtOrigin(relicID, 2 * getMapAreaSizeFactor() * cNumberPlayers, cCenterLoc,
                         0.0, continentRadiusMeters, avoidRelicMeters);

   generateLocs("relic locs");

   rmSetProgress(0.7);

   // Forests.
   float avoidForestMeters = 35.0;

   int forestDefID = rmAreaDefCreate("forest");
   rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(50), rmTilesToAreaFraction(80));
   rmAreaDefSetForestType(forestDefID, forestType);
   rmAreaDefSetAvoidSelfDistance(forestDefID, avoidForestMeters);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidWater4);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidImpassableLand8);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidSettlementWithFarm);

   rmAreaDefCreateAndBuildAreas(forestDefID, 8 * cNumberPlayers * getMapAreaSizeFactor());

   rmSetProgress(0.8);

   // Starting units.
   // Greek.
   int greekVillagerID = rmObjectDefCreate("greek villager");
   rmObjectDefAddItem(greekVillagerID, cUnitTypeVillagerGreek, 1);
   rmObjectDefAddConstraint(greekVillagerID, vDefaultAvoidAll8);
   rmObjectDefAddConstraint(greekVillagerID, vDefaultAvoidImpassableLand4);
   rmObjectDefAddConstraint(greekVillagerID, vDefaultAvoidWater8);

   // Egyptian.
   int eggyVillagerID = rmObjectDefCreate("egyptian villager");
   rmObjectDefAddItem(eggyVillagerID, cUnitTypeVillagerEgyptian, 1);
   rmObjectDefAddConstraint(eggyVillagerID, vDefaultAvoidAll8);
   rmObjectDefAddConstraint(eggyVillagerID, vDefaultAvoidImpassableLand4);
   rmObjectDefAddConstraint(eggyVillagerID, vDefaultAvoidWater8);

   // Norse.
   int norseBerserkID = rmObjectDefCreate("norse berserk");
   rmObjectDefAddItem(norseBerserkID, cUnitTypeBerserk, 1);
   rmObjectDefAddConstraint(norseBerserkID, vDefaultAvoidAll8);
   rmObjectDefAddConstraint(norseBerserkID, vDefaultAvoidImpassableLand4);
   rmObjectDefAddConstraint(norseBerserkID, vDefaultAvoidWater8);

   int norseVillagerID = rmObjectDefCreate("norse gatherer");
   rmObjectDefAddItem(norseVillagerID, cUnitTypeVillagerNorse, 1);
   rmObjectDefAddConstraint(norseVillagerID, vDefaultAvoidAll8);
   rmObjectDefAddConstraint(norseVillagerID, vDefaultAvoidImpassableLand4);
   rmObjectDefAddConstraint(norseVillagerID, vDefaultAvoidWater8);

   int norseDwarfID = rmObjectDefCreate("norse dwarf");
   rmObjectDefAddItem(norseDwarfID, cUnitTypeVillagerDwarf, 1);
   rmObjectDefAddConstraint(norseDwarfID, vDefaultAvoidAll8);
   rmObjectDefAddConstraint(norseDwarfID, vDefaultAvoidImpassableLand4);
   rmObjectDefAddConstraint(norseDwarfID, vDefaultAvoidWater8);

   int norseOxCartID = rmObjectDefCreate("norse oxcart");
   rmObjectDefAddItem(norseOxCartID, cUnitTypeOxCart, 1);
   rmObjectDefAddConstraint(norseOxCartID, vDefaultAvoidAll8);
   rmObjectDefAddConstraint(norseOxCartID, vDefaultAvoidImpassableLand4);
   rmObjectDefAddConstraint(norseOxCartID, vDefaultAvoidWater8);

   // Atty.
   int attyVillagerID = rmObjectDefCreate("atlantean villager");
   rmObjectDefAddItem(attyVillagerID, cUnitTypeVillagerAtlantean, 1);
   rmObjectDefAddConstraint(attyVillagerID, vDefaultAvoidAll8);
   rmObjectDefAddConstraint(attyVillagerID, vDefaultAvoidImpassableLand4);
   rmObjectDefAddConstraint(attyVillagerID, vDefaultAvoidWater8);

   // Gaia.
   int attyVillagerHeroID = rmObjectDefCreate("atlantean villager hero");
   rmObjectDefAddItem(attyVillagerHeroID, cUnitTypeVillagerAtlanteanHero, 1);
   rmObjectDefAddConstraint(attyVillagerHeroID, vDefaultAvoidAll8);
   rmObjectDefAddConstraint(attyVillagerHeroID, vDefaultAvoidImpassableLand4);
   rmObjectDefAddConstraint(attyVillagerHeroID, vDefaultAvoidWater8);

   // Chinese.
   int chineseVillagerID = rmObjectDefCreate("chinese villager");
   rmObjectDefAddItem(chineseVillagerID, cUnitTypeVillagerChinese, 1);
   rmObjectDefAddConstraint(chineseVillagerID, vDefaultAvoidAll8);
   rmObjectDefAddConstraint(chineseVillagerID, vDefaultAvoidImpassableLand4);
   rmObjectDefAddConstraint(chineseVillagerID, vDefaultAvoidWater8);

   int chineseKuafuID = rmObjectDefCreate("chinese kuafu");
   rmObjectDefAddItem(chineseKuafuID, cUnitTypeKuafu, 1);
   rmObjectDefAddConstraint(chineseKuafuID, vDefaultAvoidAll8);
   rmObjectDefAddConstraint(chineseKuafuID, vDefaultAvoidImpassableLand4);
   rmObjectDefAddConstraint(chineseKuafuID, vDefaultAvoidWater8);

   // Placement radius.
   float startingUnitPlacementRadiusMeters = 65.0;
   float startingUnitDist = 40.0;

   // Place and adjust starting res.
   for(int i = 1; i <= cNumberPlayers; i++)
   {
      int p = vDefaultTeamPlayerOrder[i];
      int culture = rmGetPlayerCulture(p);

      if(culture == cCultureGreek)
      {
         addObjectLocsForPlayer(greekVillagerID, true, p, 4, 0.0, startingUnitPlacementRadiusMeters,
                                startingUnitDist, cBiasNone, cInAreaNone);
         rmAddPlayerResource(p, cResourceWood, 350);
         rmAddPlayerResource(p, cResourceGold, 350);
      }
      else if(culture == cCultureEgyptian)
      {
         addObjectLocsForPlayer(eggyVillagerID, true, p, 3, 0.0, startingUnitPlacementRadiusMeters,
                                startingUnitDist, cBiasNone, cInAreaNone);
         rmAddPlayerResource(p, cResourceGold, 550);
      }
      else if(culture == cCultureNorse)
      {
         addObjectLocsForPlayer(norseBerserkID, true, p, 1, 0.0, startingUnitPlacementRadiusMeters,
                                startingUnitDist, cBiasNone, cInAreaNone);
         addObjectLocsForPlayer(norseOxCartID, true, p, 1, 0.0, startingUnitPlacementRadiusMeters,
                                startingUnitDist, cBiasNone, cInAreaNone);
         if(rmGetPlayerCiv(p) == cCivThor)
         {
            addObjectLocsForPlayer(norseDwarfID, true, p, 1, 0.0, startingUnitPlacementRadiusMeters,
                                   startingUnitDist, cBiasNone, cInAreaNone);
         }
         else
         {
            addObjectLocsForPlayer(norseVillagerID, true, p, 1, 0.0, startingUnitPlacementRadiusMeters,
                                   startingUnitDist, cBiasNone, cInAreaNone);
         }
         rmAddPlayerResource(p, cResourceWood, 350);
         rmAddPlayerResource(p, cResourceGold, 350);
      }
      else if(culture == cCultureAtlantean)
      {
         if(rmGetPlayerCiv(p) == cCivGaia)
         {
            addObjectLocsForPlayer(attyVillagerHeroID, true, p, 2, 0.0, startingUnitPlacementRadiusMeters,
                                   startingUnitDist, cBiasNone, cInAreaNone);
            rmAddPlayerResource(p, cResourceWood, 350);
            rmAddPlayerResource(p, cResourceGold, 350);
         }
         else
         {
            addObjectLocsForPlayer(attyVillagerID, true, p, 2, 0.0, startingUnitPlacementRadiusMeters,
                                   startingUnitDist, cBiasNone, cInAreaNone);
            rmAddPlayerResource(p, cResourceWood, 350);
            rmAddPlayerResource(p, cResourceGold, 350);
         }
      }
      else if(culture == cCultureChinese)
      {
         addObjectLocsForPlayer(chineseVillagerID, true, p, 2, 0.0, startingUnitPlacementRadiusMeters,
                                startingUnitDist, cBiasNone, cInAreaNone);
         addObjectLocsForPlayer(chineseKuafuID, true, p, 1, 0.0, startingUnitPlacementRadiusMeters,
                                startingUnitDist, cBiasNone, cInAreaNone);
         rmAddPlayerResource(p, cResourceWood, 350);
         rmAddPlayerResource(p, cResourceGold, 350);
      }
      else
      {
         rmEchoError("Invalid culture!");
      }
   }

   generateLocs("starting units");

   // Global fish.
   float avoidFishMeters = 20.0;

   int globalFishID = rmObjectDefCreate("global fish");
   rmObjectDefAddItem(globalFishID, cUnitTypeMahi, 3, 5.0);
   rmObjectDefAddConstraint(globalFishID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(globalFishID, rmCreatePassabilityDistanceConstraint(cPassabilityLand, true, 6.0), cObjectConstraintBufferNone);
   rmObjectDefAddConstraint(globalFishID, rmCreatePassabilityMaxDistanceConstraint(cPassabilityLand, true, 18.0), cObjectConstraintBufferNone);
   rmObjectDefAddConstraint(globalFishID, rmCreateTypeDistanceConstraint(cUnitTypeFishResource, avoidFishMeters));
   addObjectLocsAtOrigin(globalFishID, xsRandInt(10, 15) * sqrt(cNumberPlayers) * getMapAreaSizeFactor(), cCenterLoc,
                         0.0, continentRadiusMeters, avoidFishMeters);

   int outerGlobalFishID = rmObjectDefCreate("outer global fish");
   rmObjectDefAddItem(outerGlobalFishID, cUnitTypeMahi, 3, 5.0);
   rmObjectDefAddConstraint(outerGlobalFishID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(outerGlobalFishID, rmCreatePassabilityDistanceConstraint(cPassabilityLand, true, 17.5), cObjectConstraintBufferNone);
   rmObjectDefAddConstraint(outerGlobalFishID, rmCreateTypeDistanceConstraint(cUnitTypeFishResource, avoidFishMeters));
   addObjectLocsAtOrigin(outerGlobalFishID, xsRandInt(6, 12) * sqrt(cNumberPlayers) * getMapAreaSizeFactor(), cCenterLoc,
                         0.0, -1.0, avoidFishMeters);

   generateLocs("global fish locs");

   rmSetProgress(0.9);

   // Embellishment.
   // Seaweed.
   int seaweedID = rmObjectDefCreate("seaweed");
   rmObjectDefAddItem(seaweedID, cUnitTypeSeaweed, xsRandInt(3, 5), 2.0);
   rmObjectDefAddConstraint(seaweedID, rmCreatePassabilityDistanceConstraint(cPassabilityLand, true, 6.0), cObjectConstraintBufferNone);
   rmObjectDefAddConstraint(seaweedID, rmCreatePassabilityMaxDistanceConstraint(cPassabilityLand, true, 10.0), cObjectConstraintBufferNone);
   rmObjectDefPlaceAnywhere(seaweedID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());

   // Berries.
   buildAreaUnderObjectDef(berriesID, berryTerrain1, berryTerrain2, 10.0);

   // Embellishment lib
   int rockTiny = 0;
   int rockSmall = 0;
   int plantGrass = 0;
   int plantBush = 0;
   int plantWeeds = 0;
   int plantShrub = 0;

   if (biome == 0)
   {
      // Greek.
      rockTiny = cUnitTypeRockGreekTiny;
      rockSmall = cUnitTypeRockGreekSmall;
      plantGrass = cUnitTypePlantGreekGrass;
      plantBush = cUnitTypePlantGreekBush;
      plantWeeds = cUnitTypePlantGreekWeeds;
      plantShrub = cUnitTypePlantGreekShrub;
   }
   else
   {
      // Egypt.
      rockTiny = cUnitTypeRockEgyptTiny;
      rockSmall = cUnitTypeRockEgyptSmall;
      plantGrass = cUnitTypePlantDeadGrass;
      plantBush = cUnitTypePlantDeadBush;
      plantWeeds = cUnitTypePlantDeadWeeds;
      plantShrub = cUnitTypePlantDeadShrub;
   }
   // Random trees.
   int randomTreeID = rmObjectDefCreate("random tree");
   rmObjectDefAddItem(randomTreeID, treeType, 1);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidImpassableLand);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidTree);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefPlaceAnywhere(randomTreeID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   // Rocks.
   int rockTinyID = rmObjectDefCreate("rock tiny");
   rmObjectDefAddItem(rockTinyID, rockTiny, 1);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockTinyID, vDefaultAvoidImpassableLand8);
   rmObjectDefPlaceAnywhere(rockTinyID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());

   int rockSmallID = rmObjectDefCreate("rock small");
   rmObjectDefAddItem(rockSmallID, rockSmall, 1);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockSmallID, vDefaultAvoidImpassableLand8);
   rmObjectDefPlaceAnywhere(rockSmallID, 0, 25 * cNumberPlayers * getMapAreaSizeFactor());

   // Grass.
   int grassID = rmObjectDefCreate("grass");
   rmObjectDefAddItem(grassID, plantGrass, 1);
   rmObjectDefAddConstraint(grassID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(grassID, vDefaultAvoidImpassableLand8);
   rmObjectDefPlaceAnywhere(grassID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   // Bush.
   int bushID = rmObjectDefCreate("bush");
   rmObjectDefAddItem(bushID, plantBush, 1);
   rmObjectDefAddConstraint(bushID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(bushID, vDefaultAvoidImpassableLand8);
   rmObjectDefPlaceAnywhere(bushID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   // Weeds.
   int weedsID = rmObjectDefCreate("weeds");
   rmObjectDefAddItem(weedsID, plantWeeds, 1);
   rmObjectDefAddConstraint(weedsID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(weedsID, vDefaultAvoidImpassableLand8);
   rmObjectDefPlaceAnywhere(weedsID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   // Shrub.
   int shrubID = rmObjectDefCreate("shrub");
   rmObjectDefAddItem(shrubID, plantShrub, 1);
   rmObjectDefAddConstraint(shrubID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(shrubID, vDefaultAvoidImpassableLand8);
   rmObjectDefPlaceAnywhere(shrubID, 0, 10 * cNumberPlayers * getMapAreaSizeFactor());

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeHawk, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   rmSetProgress(1.0);

   generateTriggers();
}
