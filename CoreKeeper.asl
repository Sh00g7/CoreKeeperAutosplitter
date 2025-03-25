state("CoreKeeper") {}

startup
{
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
	vars.Helper.Settings.CreateFromXml("Components/CoreKeeper.Settings.xml");
	
	vars.obtainedItems = new HashSet<int>();
	vars.biomesExplored = new HashSet<int>();
	vars.bossesDefeated = new HashSet<string>();
	vars.bosses = new List<string> {
		"Glurch",
		"Ghorm",
		"Malugaz",
		"Hivemother",
		"Azeos",
		"Omoroth",
		"RaAkar",
		"KingSlime",
		"Ivy",
		"Morpha",
		"Igneous",
		"AtlanteanWorm",
		"Nimruza",
		"Urschleim",
		"Druidra",
		"Pyrdra",
		"Crydra",
		"CoreCommander"
	};
}

init
{
	vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
	{
		var mgr = mono["Pug.Other", "Manager"];
		vars.Helper["CutsceneComplete"] = mono.Make<bool>(mgr, "_instance", "currentSceneHandler", "optionalCutsceneHandler", "cutsceneComplete");
		
		// 0: In game		1: Title		2: Intro		3: Dev		4: Loading		5: Outro		6: Benchmark
		vars.Helper["Scene"] = mono.Make<int>(mgr, "_instance", "currentSceneHandler", "sceneHandlerType");

		vars.Helper["worldId"] = mono.Make<int>(mgr, "_instance", "_saveManager", "_worldId");
		vars.Helper["worldInfo"] = mono.MakeArray<IntPtr>(mgr, "_instance", "_saveManager", "worldInfo");

		vars.Helper["version"] = mono.MakeString(mgr, "version");

		vars.activatedCrystalsOffset = mono["Pug.Other", "WorldInfo"]["activatedCrystals"];
		
		vars.Helper["charId"] = mono.Make<int>(mgr, "_instance", "_saveManager", "_characterId");
		vars.Helper["charData"] = mono.MakeArray<IntPtr>(mgr, "_instance", "_saveManager", "characterData");
		vars.Helper["wallLowered"] = mono.Make<bool>(mgr, "_instance", "player", "greatWallHasBeenLowered");

		// 0: None, 1: Slime, 2: Larva, 3: Stone, 4: Obsidian, 5: Nature, 6: GreatWall, 7: Sea, 8: Desert, 9: Crystal, 10: Passage
		vars.Helper["Biome"] = mono.Make<int>(mgr, "_instance", "player", "currentBiome");
				
		var inv = mono.Make<IntPtr>(mgr, "_instance", "player", "inventoryCache");
		var cob = mono["Pug.ECS.Components", "ContainedObjectsBuffer"];
		var od = mono["Pug.ECS.Components", "ObjectDataCD"];
		
		
		vars.GetInventoryItems = (Func<List<int>>)(() => {
			var items = new List<int>();

			inv.Update(game);
			var count = vars.Helper.Read<int>(inv.Current + 0x18);
			for (int i = 0; i < count; i++) {
				var id = vars.Helper.Read<int>(inv.Current + 0x10, 0x20 + (i * 0x14) + cob["objectData"] + od["objectID"]);
				
				// Only adds new items
				if(id > 0 && vars.obtainedItems.Add(id))
					items.Add(id);
			}
			
			return items;
		});
		
		
		string logPath = Environment.GetEnvironmentVariable("appdata") + "\\..\\LocalLow\\Pugstorm\\Core Keeper\\Player.log";
		vars.line = "";
		vars.reader = new StreamReader(new FileStream(logPath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite));

		return true;
	});
}

exit {
	vars.reader = null;
}

update
{
	if (current.worldId != -1) {
		current.activatedCrystals = vars.Helper.ReadList<int>(current.worldInfo[current.worldId] + vars.activatedCrystalsOffset);
	}
	if (current.charId != -1 && settings["items"])
		current.Items = vars.GetInventoryItems();
	
	if (vars.reader == null) 
		return false;
	
	vars.line = vars.reader.ReadLine();
}

start
{
	return current.CutsceneComplete != old.CutsceneComplete && current.CutsceneComplete;
}

split
{
	if (old.activatedCrystals.Count < current.activatedCrystals.Count) {
		return settings["obj" + current.activatedCrystals[current.activatedCrystals.Count - 1]] || 
				(settings["coreActivated"] && current.activatedCrystals.Count == 3);
	}
	if (settings["greatWallLowered"] && current.wallLowered != old.wallLowered && current.wallLowered)
		return true;
	
	if (settings["items"]) {
		for (int i = 0; i < current.Items.Count; i++) {
			return settings["i" + current.Items[i]];
		}
	}

	if (settings["biomes"]) {
		return settings["b" + current.Biome] && vars.biomesExplored.Add(current.Biome);
	}
	
	if (vars.line != null) {
		foreach (var boss in vars.bosses) {
			if (vars.line.StartsWith("Try trigger achievement Defeat" + boss))
				return settings[boss] && vars.bossesDefeated.Add(boss);
		}
	}
	
	if (settings["AllBosses"]) {
		// Pre 1.0
		if (current.version[0] == "0") {
			return vars.bossesDefeated.Count == 12;
		}
		else {
			// 1.0
			if (current.version[2] == "0") {
				return vars.bossesDefeated.Count == 17;
			}

			// 1.1
			return vars.bossesDefeated.Count == 18;
		}
	}
}

reset
{
	return current.Scene == 1;
}

onReset
{
	vars.obtainedItems.Clear();
	vars.bossesDefeated.Clear();
}