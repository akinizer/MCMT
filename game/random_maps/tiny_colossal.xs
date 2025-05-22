include "lib2/rm_core.xs";

mutable void applySuddenDeath()
{
   // Sudden Death override.
   // Do nothing here.
}

mutable void placeKotHObjects(int predatorProtoID = cUnitTypeShadePredator, vector areaLoc = cCenterLoc)
{
   // KotH override.
   if(gameIsKotH() == false)
   {
      return;
   }

   // Plenty at the center.
   int plentyID = rmObjectDefCreate(cKotHPlentyName);
   rmObjectDefAddItem(plentyID, cUnitTypePlentyVaultKOTH, 1);
   rmObjectDefPlaceAtLoc(plentyID, 0, areaLoc);
}

void createTriggers()
{
   const int cClassicalAgeDelta = -30;
   const int cHeroicAgeDelta = -30;
   const int cMythicAgeDelta = -30;

   // Generate the trigger code from the script.
   // Note that you could also write an XS script instead and include that instead of dynamically generate code.
   // Create the rule.
   rmTriggerAddScriptLine("rule _init");
   rmTriggerAddScriptLine("highFrequency");
   rmTriggerAddScriptLine("active");
   rmTriggerAddScriptLine("runImmediately");
   rmTriggerAddScriptLine("{");

   // Game setup, generate trigger code based on the player's civ.
   for(int i = 1; i <= cNumberPlayers; i++)
   {
      // Favor trickle.
      rmTriggerAddScriptLine("trPlayerModifyResourceData(" + i + ", cXSPlayerResourceEffectResTrickle, cResourceFavor, 0.75, cXSRelativityAssign);");

      // What we are not allowed to build.
      int cultureID = rmGetPlayerCulture(i);
      if(cultureID == cCultureGreek)
      {
         rmTriggerAddScriptLine("trForbidProtounit(" + i + ", \"Granary\");");
         rmTriggerAddScriptLine("trForbidProtounit(" + i + ", \"Storehouse\");");
      }
      else if(cultureID == cCultureEgyptian)
      {
         rmTriggerAddScriptLine("trForbidProtounit(" + i + ", \"MonumentToVillagers\");");
         rmTriggerAddScriptLine("trForbidProtounit(" + i + ", \"MonumentToSoldiers\");");
         rmTriggerAddScriptLine("trForbidProtounit(" + i + ", \"MonumentToPriests\");");
         rmTriggerAddScriptLine("trForbidProtounit(" + i + ", \"MonumentToPharaohs\");");
         rmTriggerAddScriptLine("trForbidProtounit(" + i + ", \"MonumentToGods\");");
         rmTriggerAddScriptLine("trForbidProtounit(" + i + ", \"Granary\");");
         rmTriggerAddScriptLine("trForbidProtounit(" + i + ", \"LumberCamp\");");
         rmTriggerAddScriptLine("trForbidProtounit(" + i + ", \"MiningCamp\");");
         rmTriggerAddScriptLine("trForbidProtounit(" + i + ", \"Mercenary\");");
         rmTriggerAddScriptLine("trForbidProtounit(" + i + ", \"MercenaryCavalry\");");
      }
      else if(cultureID == cCultureAtlantean)
      {
         rmTriggerAddScriptLine("trForbidProtounit(" + i + ", \"EconomicGuild\");");
      }
      else if(cultureID == cCultureChinese)
      {
         rmTriggerAddScriptLine("trForbidProtounit(" + i + ", \"Silo\");");
      }

      // Generic stuff.
      rmTriggerAddScriptLine("trForbidProtounit(" + i + ", \"Dock\");");
      rmTriggerAddScriptLine("trForbidProtounit(" + i + ", \"Farm\");");
      rmTriggerAddScriptLine("trForbidProtounit(" + i + ", \"WallConnector\");");
      rmTriggerAddScriptLine("trForbidProtounit(" + i + ", \"WallShort\");");
      rmTriggerAddScriptLine("trForbidProtounit(" + i + ", \"WallMedium\");");
      rmTriggerAddScriptLine("trForbidProtounit(" + i + ", \"WallLong\");");

      // Disable Omniscience.
      rmTriggerAddScriptLine("trTechSetStatus(" + i + ", cTechOmniscience, cTechStatusUnobtainable);");

      // Grant Masons, Architects, and Hunting Equipment.
      rmTriggerAddScriptLine("trTechSetStatus(" + i + ", cTechMasons, cTechStatusActive);");
      rmTriggerAddScriptLine("trTechSetStatus(" + i + ", cTechArchitects, cTechStatusActive);");
      rmTriggerAddScriptLine("trTechSetStatus(" + i + ", cTechHuntingEquipment, cTechStatusActive);");

      // Nerf GPs for everyone (in case you obtain them through cheats).
      rmTriggerAddScriptLine("trModifyProtounitAction(\"Earthquake\", \"HandAttack\", " + i + ", 0.25, cXSRelativityBasePercent);");
      rmTriggerAddScriptLine("trModifyProtounitAction(\"Meteor\", \"HandAttack\", " + i + ", 0.5, cXSRelativityBasePercent);");
      rmTriggerAddScriptLine("trModifyProtounitAction(\"Tornado\", \"HandAttack\", " + i + ", 0.75, cXSRelativityBasePercent);");
      rmTriggerAddScriptLine("trModifyProtounitAction(\"ImplodeShockwave\", \"HandAttack\", " + i + ", 0.5, cXSRelativityBasePercent);");
      
      rmTriggerAddScriptLine("trGodPowerSetCooldown(" + i + ", \"Pestilence\", 300);");

      // Culture-based proto/tech/power adjustments.
      if(cultureID == cCultureGreek)
      {
         // Age ups research faster.
         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechClassicalAgeAres, " + i + ", " + cClassicalAgeDelta + ", cXSRelativityAbsolute);");
         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechClassicalAgeAthena, " + i + ", " + cClassicalAgeDelta + ", cXSRelativityAbsolute);");
         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechClassicalAgeHermes, " + i + ", " + cClassicalAgeDelta + ", cXSRelativityAbsolute);");

         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechHeroicAgeAphrodite, " + i + ", " + cHeroicAgeDelta + ", cXSRelativityAbsolute);");
         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechHeroicAgeApollo, " + i + ", " + cHeroicAgeDelta + ", cXSRelativityAbsolute);");
         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechHeroicAgeDionysus, " + i + ", " + cHeroicAgeDelta + ", cXSRelativityAbsolute);");

         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechMythicAgeArtemis, " + i + ", " + cMythicAgeDelta + ", cXSRelativityAbsolute);");
         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechMythicAgeHephaestus, " + i + ", " + cMythicAgeDelta + ", cXSRelativityAbsolute);");
         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechMythicAgeHera, " + i + ", " + cMythicAgeDelta + ", cXSRelativityAbsolute);");
      }
      else if(cultureID == cCultureEgyptian)
      {
         // Priests train slower.
         rmTriggerAddScriptLine("trModifyProtounitData(\"Priest\", " + i + ", cXSProtoEffectTrainPoints, 1.5, cXSRelativityBasePercent);");
      
         // Age ups research faster.
         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechClassicalAgeAnubis, " + i + ", " + cClassicalAgeDelta + ", cXSRelativityAbsolute);");
         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechClassicalAgeBast, " + i + ", " + cClassicalAgeDelta + ", cXSRelativityAbsolute);");
         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechClassicalAgePtah, " + i + ", " + cClassicalAgeDelta + ", cXSRelativityAbsolute);");

         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechHeroicAgeNephthys, " + i + ", " + cHeroicAgeDelta + ", cXSRelativityAbsolute);");
         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechHeroicAgeSekhmet, " + i + ", " + cHeroicAgeDelta + ", cXSRelativityAbsolute);");
         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechHeroicAgeSobek, " + i + ", " + cHeroicAgeDelta + ", cXSRelativityAbsolute);");

         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechMythicAgeHorus, " + i + ", " + cMythicAgeDelta + ", cXSRelativityAbsolute);");
         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechMythicAgeOsiris, " + i + ", " + cMythicAgeDelta + ", cXSRelativityAbsolute);");
         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechMythicAgeThoth, " + i + ", " + cMythicAgeDelta + ", cXSRelativityAbsolute);");
      }
      else if(cultureID == cCultureNorse)
      {
         // Hersirs train slower.
         rmTriggerAddScriptLine("trModifyProtounitData(\"Hersir\", " + i + ", cXSProtoEffectTrainPoints, 1.5, cXSRelativityBasePercent);");
      
         // Age ups research faster.
         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechClassicalAgeForseti, " + i + ", " + cClassicalAgeDelta + ", cXSRelativityAbsolute);");
         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechClassicalAgeFreyja, " + i + ", " + cClassicalAgeDelta + ", cXSRelativityAbsolute);");
         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechClassicalAgeHeimdall, " + i + ", " + cClassicalAgeDelta + ", cXSRelativityAbsolute);");
         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechClassicalAgeUllr, " + i + ", " + cClassicalAgeDelta + ", cXSRelativityAbsolute);");

         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechHeroicAgeBragi, " + i + ", " + cHeroicAgeDelta + ", cXSRelativityAbsolute);");
         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechHeroicAgeNjord, " + i + ", " + cHeroicAgeDelta + ", cXSRelativityAbsolute);");
         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechHeroicAgeSkadi, " + i + ", " + cHeroicAgeDelta + ", cXSRelativityAbsolute);");
         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechHeroicAgeAegir, " + i + ", " + cHeroicAgeDelta + ", cXSRelativityAbsolute);");

         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechMythicAgeBaldr, " + i + ", " + cMythicAgeDelta + ", cXSRelativityAbsolute);");
         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechMythicAgeHel, " + i + ", " + cMythicAgeDelta + ", cXSRelativityAbsolute);");
         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechMythicAgeTyr, " + i + ", " + cMythicAgeDelta + ", cXSRelativityAbsolute);");
         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechMythicAgeVidar, " + i + ", " + cMythicAgeDelta + ", cXSRelativityAbsolute);");
      }
      else if(cultureID == cCultureAtlantean)
      {
         // Age ups research faster.
         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechClassicalAgeLeto, " + i + ", " + cClassicalAgeDelta + ", cXSRelativityAbsolute);");
         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechClassicalAgeOceanus, " + i + ", " + cClassicalAgeDelta + ", cXSRelativityAbsolute);");
         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechClassicalAgePrometheus, " + i + ", " + cClassicalAgeDelta + ", cXSRelativityAbsolute);");

         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechHeroicAgeHyperion, " + i + ", " + cHeroicAgeDelta + ", cXSRelativityAbsolute);");
         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechHeroicAgeRheia, " + i + ", " + cHeroicAgeDelta + ", cXSRelativityAbsolute);");
         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechHeroicAgeTheia, " + i + ", " + cHeroicAgeDelta + ", cXSRelativityAbsolute);");

         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechMythicAgeAtlas, " + i + ", " + cMythicAgeDelta + ", cXSRelativityAbsolute);");
         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechMythicAgeHelios, " + i + ", " + cMythicAgeDelta + ", cXSRelativityAbsolute);");
         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechMythicAgeHekate, " + i + ", " + cMythicAgeDelta + ", cXSRelativityAbsolute);");
      }
      else if(cultureID == cCultureChinese)
      {
         // Age ups research faster.
         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechClassicalAgeXuannu, " + i + ", " + cClassicalAgeDelta + ", cXSRelativityAbsolute);");
         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechClassicalAgeChiyou, " + i + ", " + cClassicalAgeDelta + ", cXSRelativityAbsolute);");
         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechClassicalAgeHoutu, " + i + ", " + cClassicalAgeDelta + ", cXSRelativityAbsolute);");

         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechHeroicAgeGoumang, " + i + ", " + cHeroicAgeDelta + ", cXSRelativityAbsolute);");
         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechHeroicAgeRushou, " + i + ", " + cHeroicAgeDelta + ", cXSRelativityAbsolute);");
         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechHeroicAgeNuba, " + i + ", " + cHeroicAgeDelta + ", cXSRelativityAbsolute);");

         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechMythicAgeZhurong, " + i + ", " + cMythicAgeDelta + ", cXSRelativityAbsolute);");
         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechMythicAgeGonggong, " + i + ", " + cMythicAgeDelta + ", cXSRelativityAbsolute);");
         rmTriggerAddScriptLine("trTechModifyResearchPoints(cTechMythicAgeHuangdi, " + i + ", " + cMythicAgeDelta + ", cXSRelativityAbsolute);");
      }
   }

   // We're done.
   rmTriggerAddScriptLine("xsDisableSelf();");

   // Close the rule.
   rmTriggerAddScriptLine("}");
}

void generate()
{
   rmSetProgress(0.0);

   // Place settlements on the third tile from the map edges so they touch the edges.
   int settlementTileIdx = 2;
   int edgeTexture = cTerrainCityTile1;

   // Set size.
   float sclr=6.9;
   if(cMapSizeCurrent == 1)
   {
      sclr=8.4;
   }

   if(gameIs1v1() == true)
   {
      int xTiles = 33;
      int zTiles = 17;
      rmSetMapSize(xTiles * sclr, zTiles * sclr);

      rmInitializeLand(edgeTexture);

      float xFrac = rmXTileIndexToFraction(settlementTileIdx);
      float zFrac = rmZTileIndexToFraction(0.5 * zTiles);
      placePlayersOnLine(vectorXZ(xFrac, zFrac), vectorXZ(1.0 - xFrac, 1.0 - zFrac));
   }
   else if(cNumberTeams == 2)
   {
      int xTiles = 33;
      int zTiles = 16 * getMaxTeamPlayers() + 1;
      rmSetMapSize(xTiles * sclr, zTiles * sclr);

      rmInitializeLand(edgeTexture);

      float xFrac = rmXTileIndexToFraction(settlementTileIdx);
      float zFrac = rmZTileIndexToFraction(settlementTileIdx);
      rmSetPlacementTeam(1);
      placePlayersOnLine(vectorXZ(xFrac, 1.0 - zFrac), vectorXZ(xFrac, zFrac));
      rmSetPlacementTeam(2);
      placePlayersOnLine(vectorXZ(1.0 - xFrac, zFrac), vectorXZ(1.0 - xFrac, 1.0 - zFrac));
   }
   else
   {
      int axisTiles = 8 * cNumberPlayers + 1;
      rmSetMapSize(axisTiles * sclr);

      rmInitializeLand(edgeTexture);

      rmPlacePlayersOnSquare(0.5 - rmXTileIndexToFraction(settlementTileIdx));
   }

   // Only do the most basic stuf on this map.
   finalizePlayerPlacement();

   // Lighting.
   rmSetLighting(cLightingSetRmTiny01);

   rmSetProgress(0.25);

   // Playable area, going up to 1 tile towards the edge.
   int mapAreaID = rmAreaCreate("map area");
   rmAreaSetTerrainType(mapAreaID, cTerrainEgyptSand1);
   rmAreaSetSize(mapAreaID, 1.0);
   rmAreaSetCoherence(mapAreaID, 1.0);
   rmAreaAddConstraint(mapAreaID, createSymmetricBoxConstraint(rmXTileIndexToFraction(1), rmZTileIndexToFraction(1)));
   rmAreaBuild(mapAreaID);

   rmSetProgress(0.5);

   if(gameIsKotH() == true)
   {
      placeKotHObjects();
   }

   // Objects (not so much to place here).
   int startingCitadelCenterID = rmObjectDefCreate("starting citadel center");
   rmObjectDefAddItem(startingCitadelCenterID, cUnitTypeCitadelCenter, 1);
   placeObjectDefAtPlayerLocs(startingCitadelCenterID, true);

   rmSetProgress(0.75);

   // Set resources.
   for(int i = 1; i <= cNumberPlayers; i++)
   {
      // Player resources.
      rmSetPlayerResource(i, cResourceFood, 100000.0);
      rmSetPlayerResource(i, cResourceWood, 100000.0);
      rmSetPlayerResource(i, cResourceGold, 100000.0);

      // Favor trickle set via trigger.
   }

   // Create the triggers (to forbid units etc.).
   createTriggers();

   rmSetProgress(1.0);
}
