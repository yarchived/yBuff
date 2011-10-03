
local BACKDROP = {
    bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=],
    insets = {top = -1, bottom = -1, left = -1, right = -1}
}

local HOUR = 3600
local TEN = 60*10
local MIN = 60

local SetTimeLeftOnButton = function(self, sec)
    if(sec>=HOUR) then
        local h = floor(sec / HOUR)
        local m = floor(sec % HOUR)
        self.duration:SetText(("%dh:%dm"):format(h, m))
        return (sec % HOUR)
    elseif(sec > TEN) then
        local m = floor(sec / MIN)
        self.duration:SetText(('%dm'):format(m))
        return (sec % MIN)
    elseif(sec > MIN) then
        local m = floor(sec / MIN)
        local s = floor(sec % MIN)
        self.duration:SetText(('%d:%02d'):format(m ,s))
        return (sec - floor(sec))
    elseif(sec > 0) then
        self.duration:SetText(('|cffff0000%ds|r'):format(floor(sec)))
        return (sec - floor(sec))
    end
end

local UpdateTimer = function(self)
    if(self.aniGroup:IsPlaying()) then
        self.aniGroup:Stop()
    end
    if(self.expiration and self.expiration > GetTime()) then
        local timeLeft = self.expiration - GetTime()
        if(timeLeft>0) then
            local nextUpdate = SetTimeLeftOnButton(self, timeLeft)
            if(nextUpdate) then
                self.ani:SetDuration(nextUpdate)
                self.aniGroup:Play()
                self.duration:Show()
            else
                self.duration:Hide()
            end
        end
    else
        self.duration:Hide()
    end
end

local OnFinished = function(self)
    return UpdateTimer(self.__parent)
end

local function UpdateAura(self, index)
    local unit = self.__parent:GetAttribute'unit'
    local filter = self.__parent:GetAttribute'filter'

    local name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff, value1, value2, value3 = UnitAura(unit, index, filter)

    if(name) then
        self.icon:SetTexture(icon)
        self.count:SetText(count > 0 and count)
        self.expiration = expires

        UpdateTimer(self)
    end
end

local function OnAttributeChanged(self, attribute, value)
    if(attribute == 'index') then
        UpdateAura(self, value)
    end
end

local function OnHide(self)
    if(self.aniGroup:IsPlaying()) then
        self.aniGroup:Stop()
    end
end

local PostCreate = function(self)
    local icon = self:CreateTexture(nil, 'BORDER')
    icon:SetAllPoints()
    icon:SetTexCoord(4/64, 60/64, 4/64, 60/64)
    self.icon = icon

    local count = self:CreateFontString(nil, 'ARTWORK')
    count:SetPoint('BOTTOMRIGHT', -2, 1)
    count:SetFont(STANDARD_TEXT_FONT, 12, 'OUTLINE')
    self.count = count

    local duration = self:CreateFontString(nil, 'ARTWORK')
    duration:SetPoint('TOP', self, 'BOTTOM', 0, -1)
    duration:SetFont(STANDARD_TEXT_FONT, 12)
    duration:SetShadowColor(0, 0, 0)
    duration:SetShadowOffset(1, -1)
    self.duration = duration

    local overlay = self:CreateTexture(nil, 'ARTWORK')
    overlay:SetAllPoints()
    overlay:SetTexture[[Interface\AddOns\yBuff\SmartName]]
    self.overlay = overlay

    local aniGroup = self:CreateAnimationGroup()
    aniGroup:SetLooping'NONE'
    aniGroup:SetScript('OnFinished', OnFinished)
    self.aniGroup = aniGroup
    aniGroup.__parent = self

    local ani = aniGroup:CreateAnimation()
    ani:SetOrder(1)
    self.ani = ani
    ani.__parent = self

    --self:SetScript('OnUpdate', OnUpdate)
    self:SetScript('OnAttributeChanged', OnAttributeChanged)
    self:SetScript('OnHide', OnHide)

    self.__parent = self:GetParent()

    self:SetBackdrop(BACKDROP)
    self:SetBackdropColor(0,0,0, .5)

    UpdateAura(self, self:GetID())
end

local function OnAttributeChanged(self, attribute, value)
    if(attribute:match'^child(%d+)') then
        PostCreate(value)
    end
end

local function SetManyAttribute(self, ...)
    for i = 1, select('#', ...), 2 do
        local att, val = select(i, ...)
        if(not att) then break end
        self:SetAttribute(att, val)
    end
end

local function CreateBuffFrame(name, ...)
    local f = CreateFrame('Frame', name, UIParent, 'SecureAuraHeaderTemplate')
    local _SIZE = 28

    SetManyAttribute(f,
        'minWidth', '200',
        'minHeight', '80',
        'wrapAfter', '12',
        'maxWraps', '4',
        'point', 'TOPRIGHT',
        'xOffset', tostring(-3 - _SIZE),
        'yOffset', '0',
        'wrapYOffset', tostring(-10 - _SIZE),
        ...)
    RegisterAttributeDriver(f, 'unit', '[vehicleui]vehicle;player')
    f:SetScript('OnAttributeChanged', OnAttributeChanged)

    f:SetBackdrop(BACKDROP)
    f:SetBackdropColor(0, 0, 0, .5)

    return f
end

local buff = CreateBuffFrame('yBuffFrame',
    'unit', 'player',
    'filter', 'HELPFUL',
    'includeWeapons', '1',
    'weaponTemplate', 'yBuffCancelableAuraTemplate',
    'template', 'yBuffCancelableAuraTemplate')
buff:SetPoint('TOPRIGHT', Minimap, 'TOPLEFT', -20, 0)
buff:Show()

local debuff = CreateBuffFrame('yDebuffFrame',
    'unit', 'player',
    'filter', 'HARMFUL',
    'template', 'yBuffAuraTemplate')
debuff:SetPoint('TOPRIGHT', buff, 'BOTTOMRIGHT', 0, -20)
debuff:Show()

BuffFrame:UnregisterAllEvents()
BuffFrame:Hide()

