local TheNet = GLOBAL.TheNet
local tonumber = GLOBAL.tonumber

if not TheNet:GetIsServer() then
    return
end

--把 "1", "#1", "2", "#2", "3", "4", "#4", "5", "#5", "6", "#6", "7" 变成1-12
local function Trans(text)
    local list_num = {"1", "#1", "2", "#2", "3", "4", "#4", "5", "#5", "6", "#6", "7"}
    for k,v in ipairs(list_num) do
        if text == v then
            return k
        end
    end
end

--曲谱转化
local function TextToMusic(text)
    local list_temp = {}
    local list_result = {}
    local list_needed = {"0"}
    --将字符串转化为列表
    if text then
        string.gsub(text, "[^ ]+", function(w)
            table.insert(list_temp, w)
        end)
    end
    --构造合规的字符列表
    local list_plus = {"-", "", "+"}
    local list_num = {"1", "#1", "2", "#2", "3", "4", "#4", "5", "#5", "6", "#6", "7"}
    for _,i in pairs(list_plus) do
        for _,j in pairs(list_num) do
            table.insert(list_needed, j..i)
        end
    end
    --检查每个项目是否合规
    for k,v in pairs(list_temp) do
        if table.contains(list_needed, v) then
            table.insert(list_result, v)
        end
    end
    --替换
    for k,v in pairs(list_result) do
        if string.find(v, "-") then
            v = string.gsub(v, "-", "")
            v = Trans(v)
            v = tonumber(v)
            list_result[k] = {v, 3}
        elseif string.find(v, "+") then
            v = string.gsub(v, "+", "")
            v = Trans(v)
            v = tonumber(v)
            list_result[k] = {v, 5}
        elseif v == "0" then
            list_result[k] = {0, 0}
        else
            v = Trans(v)
            v = tonumber(v)
            list_result[k] = {v, 4}
        end
    end
    return list_result
end

--执行播放
local function JustPlay(inst, musicsheet)
    local music = TextToMusic(musicsheet)
    local index = 1
    if inst.musictask ~= nil then
        inst.musictask:Cancel()
        inst.musictask = nil
    end
    inst.musictask = inst:DoPeriodicTask(0.25, function()
        inst.AnimState:PlayAnimation("hit")
        local character = music[index]
        if character == nil or character[1] == nil or character[2] == nil then
            inst.components.machine:TurnOff()
            return
        end
        local octave = character[2]
        if character[1] ~= 0 then
            local _sound = "hookline_2/common/shells/sea_sound_"..(octave == 3 and 1 or octave == 4 and 2 or 3).."_LP"
            inst.SoundEmitter:PlaySoundWithParams(_sound, {note = character[1] - 1 + 0.1})
        end
        index = index + 1
        if index > #music then
            inst.components.machine:TurnOff()
        end
    end)
end

local function TurnOn(inst)
    --如果木牌是空的就结束
    if not inst.components.writeable or not inst.components.writeable.text or inst.components.writeable.text == "" then
        inst:DoTaskInTime(0.1, function()
            inst.components.machine:TurnOff()
        end)
        return
    end
    --获取木牌文字
    local text_homesign = inst.components.writeable.text
    JustPlay(inst, text_homesign)
end

local function TurnOff(inst)
    if inst.musictask ~= nil then
        inst.musictask:Cancel()
        inst.musictask = nil
    end
end

local function PlauMusic(inst)
    if not inst.components.machine then
        inst:AddComponent("machine")
    end
    inst.components.machine.turnonfn = TurnOn
    inst.components.machine.turnofffn = TurnOff
    inst.components.machine.cooldowntime = 0.5
end

AddPrefabPostInit("homesign", PlauMusic)