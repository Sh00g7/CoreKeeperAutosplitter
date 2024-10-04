state("CoreKeeper") {}

startup
{
  Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");
  
  settings.Add("1Statue",true,"Split when 1 boss statue is activated");
  settings.Add("2Statues",true,"Split when 2 boss statues are activated");
  settings.Add("3Statues",true,"Split when all 3 boss statues are activated (Core is activated)");
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
	if(settings["1Statue"] && current.activatedCrystals.Count == 1 && current.activatedCrystals.Count != old.activatedCrystals.Count) {
		return true;
	}
	if(settings["2Statues"] && current.activatedCrystals.Count == 2 && current.activatedCrystals.Count != old.activatedCrystals.Count) {
		return true;
	}
	if(settings["3Statues"] && current.activatedCrystals.Count == 3 && current.activatedCrystals.Count != old.activatedCrystals.Count) {
		return true;
	}
}