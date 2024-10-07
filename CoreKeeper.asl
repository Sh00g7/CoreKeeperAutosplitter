state("CoreKeeper") {}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
  
    settings.Add("obj2500",true,"Ghorm Statue Activated");
	settings.Add("obj2501",true,"Glurch Statue Activated");
	settings.Add("obj2502",true,"Malugaz Statue Activated");
	settings.Add("coreActivated",false,"Core Activated");
	settings.SetToolTip("coreActivated", "Alternative if you do not want to split for each statue. The Core is activated when all 3 Boss Statues are activated.");
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
        
        vars.activatedCrystalsOffset = mono["Pug.Other", "WorldInfo"]["activatedCrystals"];
        
        return true;
    });
}

update
{
    if (current.worldId != -1)
    {
        current.activatedCrystals = vars.Helper.ReadList<int>(current.worldInfo[current.worldId] + vars.activatedCrystalsOffset);
    }
}

start
{
	return current.CutsceneComplete != old.CutsceneComplete && current.CutsceneComplete;
}

split
{
    if (old.activatedCrystals.Count < current.activatedCrystals.Count)
    {
        return settings["obj" + current.activatedCrystals[current.activatedCrystals.Count - 1]] || 
				(settings["coreActivated"] && current.activatedCrystals.Count == 3);
    }
}

reset
{
	return current.Scene == 1;
}