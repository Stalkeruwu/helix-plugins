PLUGIN.name = "Adds shove for OTA"
PLUGIN.author = "Yo Mama"
PLUGIN.description = "OTA /shove command."


ix.config.Add("shoveTime", 30, "How long should a character be unconscious after being knocked out?", nil, {
	data = {min = 5, max = 60},
	category = "Shoving"
})


ix.command.Add("shove", {
    description = "Knock someone out.",
    OnRun = function(self, client)
         if ix.faction.Get(client:Team()).uniqueID != "ota" then
             return "You're not an Overwatch soldier!"
         end

         local tEntity = client:GetEyeTraceNoCursor().Entity
         local target
 
         if tEntity:IsPlayer() then 
             target = tEntity
         else
             return "You must be looking a player!"     
         end

         if target && target:GetPos():Distance(client:GetPos()) >= 50 then
             return "You're not close enough!"
         end 

             client:ForceSequence("melee_gunhit")
         timer.Simple(0.4, function()
             client:EmitSound("physics/body/body_medium_impact_hard6.wav")
             target:SetRagdolled(true, ix.config.Get("shoveTime", 10))
         end)
    end
})