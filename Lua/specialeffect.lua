--[[ SpecialEffect.lua

]]--

SpecialEffect = setmetatable({}, {})
do
    local effect = getmetatable(SpecialEffect)
    effect.__index = effect

    function effect.__call(x, y, z)
        return setmetatable({x = x, y = y, z = z or 0, handle = {}}, effect)
    end

    function effect:addModel(model)
        local e = AddSpecialEffect(model, self.x, self.y)
        self.handle[model] = e
        return e
    end
    function effect:removeModel(model)
        DestroyEffect(self.handle[model])
    end
    function effect:clearModels()
        
    end
  
    function effect:killModel(model, deathDuration)
        BlzPlaySpecialEffect(self.handle[model], ANIM_TYPE_DEATH)
        TimerStart(CreateTimer(), deathDuration or 2, false, function()
            self:removeModel(model)
            DestroyTimer(GetExpiredTimer())
        end)
    end
    function effect:killAllModels(deathDuration)
        TimerStart(CreateTimer(), deathDuration or 2, false, function()
            self:removeModel(self.handle)
            DestroyTimer(GetExpiredTimer())
        end
    end
    
end