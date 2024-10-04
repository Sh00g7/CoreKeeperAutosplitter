state("CoreKeeper") {}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
  
    settings.Add("statue1", true, "Split when 1 boss statue is activated");
    settings.Add("statue2", true, "Split when 2 boss statues are activated");
    settings.Add("statue3", true, "Split when all 3 boss statues are activated (Core is activated)");
}

init
{
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono =>
    {
        var mgr = mono["Pug.Other", "Manager"];
        vars.Helper["CutsceneComplete"] = mono.Make<bool>(mgr, "_instance", "currentSceneHandler", "optionalCutsceneHandler", "cutsceneComplete");
        
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
    return old.activatedCrystals.Count != current.activatedCrystals.Count
        && settings["statue" + current.activatedCrystals.Count];
}
