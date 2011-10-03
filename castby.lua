
local CUSTOM_CLASS_COLORS = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
local C = {}
for class, color in next, CUSTOM_CLASS_COLORS do
    C[class] = ('%02x%02x%02x'):format(color.r*255, color.g*255, color.b*255)
end

local function SetUnitAura(self, unit, index, filter)
    local name, rank, icon, count, debuffType, duration, expires, caster = UnitAura(unit, index, filter)
    if(caster) then
        local _, class = UnitClass(caster)
        local name, realm = UnitName(caster)
        if(realm) then
            name = ('%s-%s'):format(name, realm)
        end
        self:AddLine(('\nCast by |cff%s%s|r (%s)'):format(C[class], name, caster))
    end
end

hooksecurefunc(GameTooltip, 'SetUnitAura', SetUnitAura)

