local PLUGIN = PLUGIN

PLUGIN.name = "Camera"
PLUGIN.description = "Combine Cameras for use."


if CLIENT then
    function PLUGIN:IsViewingCamera()
        return LocalPlayer():GetNetVar("curCamera", false)
    end
end

function PLUGIN:HUDPaint()
    if not LocalPlayer():IsCombine() then return end
    if self:IsViewingCamera() then
        draw.SimpleTextOutlined("Press any key to exit the camera.", "ixMediumFont", ScrW() / 2.5, ScrH() / 4, Color(255, 255, 255, 255), nil, nil, 1, Color(0, 0, 0, 255))
    end

    if #self:GetCameras() > 0 then
        for k, v in pairs(self:GetCameras()) do
            local pos = v:GetPos()
            local toscreen = pos:ToScreen()

            if toscreen.visible then
                if pos:Distance(LocalPlayer():GetPos()) < 512 * 2.5 then
                    draw.SimpleTextOutlined(v:GetNetVar("CameraName", "<:: Camera ::>"), "BudgetLabel", toscreen.x, toscreen.y + 30, Color(255, 255, 255, 255), 0, 0, 0.2, Color(0, 0, 0, 255))
                end
            end
        end
    end
end

function PLUGIN:GetCameras()
    return ents.FindByClass("npc_combine_camera")
end

function PLUGIN:SetCameraName(ent, name)
    ent:SetNetVar("CameraName", name)

end

do
    local COMMAND = {}
    COMMAND.alias = "SCN"
    COMMAND.arguments = ix.type.text

    function COMMAND:OnRun(client, message)
        if (client:IsCombine()) then
                    tr = client:GetEyeTraceNoCursor()
        local camera = tr.Entity
          camera:SetNetVar("CameraName", message)
        else
            return "@notNow"
        end
    end

    ix.command.Add("SetCameraName", COMMAND)
end

function PLUGIN:SaveData()
    local cameras = self:GetCameras()
    local tbl = {}

    for k, v in pairs(cameras) do
        if v:GetNetVar("CameraName", false) then
            tbl[#tbl + 1] = {
                pos = v:GetPos(),
                ang = v:GetAngles(),
                name = v:GetNetVar("CameraName"),
                map_id = v:MapCreationID()
            }
        end
    end

    self:SetData(tbl)
end

function PLUGIN:LoadData()
    local data = self:GetData()

    for k, v in pairs(data) do
        if v.map_id == -1 then
            local ent = ents.Create("npc_combine_camera")
            ent:SetPos(v.pos)
            ent:SetAngles(v.ang)
            ent:Spawn()
            ent:SetNetVar("CameraName", v.name)
        else
            local ent = ents.GetMapCreatedEntity(v.map_id)
            ent:SetNetVar("CameraName", v.name)
        end
    end
end

function PLUGIN:CalcView(ply, pos, angles, fov)
    if self:IsViewingCamera() then
        local camera = self:IsViewingCamera()
        local bonePos, boneAngles = camera:GetBonePosition(camera:LookupBone("Combine_Camera.bone1"))
        local camPos, camAngles = camera:GetBonePosition(camera:LookupBone("Combine_Camera.Lens"))
        local view = {}
        view.origin = camPos + (boneAngles:Forward() * 2.8)
        view.angles = boneAngles + Angle(0, 0, 90)
        view.fov = 90
        view.drawviewer = true

        return view
    end
end

local combineOverlay = ix.util.GetMaterial("effects/combine_binocoverlay")

function PLUGIN:RenderScreenspaceEffects()
    if self:IsViewingCamera() then
        render.UpdateScreenEffectTexture()
        combineOverlay:SetFloat("$alpha", 1)
        combineOverlay:SetInt("$ignorez", 1)
        render.SetMaterial(combineOverlay)
        render.DrawScreenQuad()
    end
end

ix.command.Add("ViewCamera", {
    desc = "ViewCamera",
    OnRun = function(self, client)
        if client:IsCombine() then
            netstream.Start(client, "CameraView", {camera})
        end
    end
})

if CLIENT then
    local PANEL = {}

    function PANEL:Init()
        self:SetSize(ScrW() / 3, ScrH() / 3)
        self:Center()
        self:MakePopup()

        for k, v in pairs(ents.FindByClass("npc_combine_camera")) do
            local button = self:Add("DButton")
            button:Dock(TOP)
            button:SetText(v:GetNetVar("CameraName", "NO NAME PROVIDED"))
            button.camera = v

            function button:DoRightClick()

            self:GetParent():Close()
        end

            function button:DoClick()
                netstream.Start("DoCameraView", {self.camera})
                self:GetParent():Close()
            end
        end
    end

    vgui.Register("CameraMenu", PANEL, "DFrame")

    netstream.Hook("CameraView", function(data)
        if LocalPlayer():IsCombine() then
            vgui.Create("CameraMenu")
        end
    end)

    netstream.Hook("CameraNameXD", function(data)
        Derma_StringRequest("Camera Name", "What are you going to name the Camera?", "CCI-" .. math.random(00000, 99999), function(text)

            netstream.Start("CameraName", {data[1], text})
        end)
    end)

end

if SERVER then
    netstream.Hook("DoCameraView", function(ply, data)
        local camera = data[1]

        if ply:GetNetVar("curCamera", false) then
            ply:SetNetVar("curCamera", false)
            ply:SetViewEntity(ply)
            ply:Freeze(false)

            return
        end

        if camera:GetClass() == "npc_combine_camera" then

            ply:SetNetVar("curCamera", camera)
            ply:SetViewEntity(camera)
            ply:Freeze(true)
            --netstream.Start(ply, "CameraView", {camera})
        end
    end)

    netstream.Hook("CameraName", function(ply, data)
        local camera = data[1]
        local name = data[2]
        PLUGIN:SetCameraName(camera, name)
    end)
end

hook.Add("PlayerButtonDown", "CheckMovementForCamera", function(ply, button)
    if SERVER then
        if ply:GetNetVar("curCamera", false) then
            ply:SetNetVar("curCamera", false)
            ply:SetViewEntity(ply)
            ply:Freeze(false)
            netstream.Start(client, "CameraView", {camera})
        end
    end
end)

hook.Add("PlayerSpawnedNPC", "nameyourfuckingcamera", function(ply, ent)
    if ent:GetClass() == "npc_combine_camera" then

        timer.Simple(0.1, function()
            netstream.Start(ply, "CameraNameXD", {ent})
        end)
    end
end)