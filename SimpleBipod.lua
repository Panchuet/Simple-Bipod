behaviour("SimpleBipod")

-- Keys:
--   raycastDistance              (float)  : Length from BipodObject to the bottom of the legs
--   detectionDelay               (float)  : Time in seconds the raycast must hit/miss before deploying/undeploying
--   bipodKickbackProneMultiplier (float)  : Multiplier applied to recoilKickbackProneMultiplier when deployed
--   bipodSnapProneMultiplier     (float)  : Multiplier applied to recoilSnapProneMultiplier when deployed
--   bipodSpreadProneMultiplier   (float)  : Multiplier applied to followupSpread.proneMultiplier when deployed
--   deployParameterName          (string) : Name of the animator trigger parameter for the deploy hand animation
--   undeployParameterName        (string) : Name of the animator trigger parameter for the fold hand animation
--   stateValues                  (string) : Two space-separated ints e.g. "0 1" (0 = folded, 1 = deployed)
--   stateParameterName           (string) : Name of the animator int parameter (holds the physical bipod position)

function SimpleBipod:Start()
    self.weapon = self.gameObject.GetComponent(Weapon)
    self.animator = self.gameObject.GetComponent(Animator)
    self.dataContainer = self.gameObject.GetComponent(DataContainer)

    self.raycastDistance = self.dataContainer.GetFloat("raycastDistance")
    self.detectionDelay = self.dataContainer.GetFloat("detectionDelay")
    
    self.bipodKickbackProneMultiplier = self.dataContainer.GetFloat("bipodKickbackProneMultiplier")
    self.bipodSnapProneMultiplier = self.dataContainer.GetFloat("bipodSnapProneMultiplier")
    self.bipodSpreadProneMultiplier = self.dataContainer.GetFloat("bipodSpreadProneMultiplier")

    self.stateValues = {}
    for match in (self.dataContainer.GetString("stateValues") .. " "):gmatch("(.-) ") do
        table.insert(self.stateValues, tonumber(match))
    end

    if self.animator ~= nil then
        self.deployTrigger = self.animator.StringToHash(self.dataContainer.GetString("deployParameterName"))
        self.undeployTrigger = self.animator.StringToHash(self.dataContainer.GetString("undeployParameterName"))
        self.stateParameter = self.animator.StringToHash(self.dataContainer.GetString("stateParameterName"))
    end

    self.anchor = self.gameObject.transform.Find("BipodObject")

    self.origKickbackProne = self.weapon.recoilKickbackProneMultiplier
    self.origSnapProne = self.weapon.recoilSnapProneMultiplier
    
    if self.weapon.followupSpread ~= nil then
        self.origMaxSpreadAim = self.weapon.followupSpread.maxSpreadAim
        self.origMaxSpreadHip = self.weapon.followupSpread.maxSpreadHip
        self.origSpreadGain = self.weapon.followupSpread.spreadGain
        self.origSpreadStayTime = self.weapon.followupSpread.spreadStayTime
        self.origSpreadDissipateTime = self.weapon.followupSpread.spreadDissipateTime
        self.origSpreadProne = self.weapon.followupSpread.proneMultiplier
    end

    self.isDeployed = false
    
    self.hitTimer = 0
    self.missTimer = 0

    self:ApplyState()
end

function SimpleBipod:ApplyState()
    if self.animator ~= nil then
        self.animator.SetInteger(self.stateParameter, self.stateValues[self.isDeployed and 2 or 1])
    end
end

function SimpleBipod:ChangeState(deploy)
    if self.isDeployed == deploy then return end

    self.isDeployed = deploy
    
    self.hitTimer = 0
    self.missTimer = 0
    
    if self.animator ~= nil then
        if deploy then
            self.animator.SetTrigger(self.deployTrigger)
        else
            self.animator.SetTrigger(self.undeployTrigger)
        end
    end

    if deploy then
        self.weapon.recoilKickbackProneMultiplier = self.bipodKickbackProneMultiplier
        self.weapon.recoilSnapProneMultiplier = self.bipodSnapProneMultiplier
        
        if self.weapon.followupSpread ~= nil then
            local spreadData = self.weapon.followupSpread
            spreadData.maxSpreadAim = self.origMaxSpreadAim
            spreadData.maxSpreadHip = self.origMaxSpreadHip
            spreadData.spreadGain = self.origSpreadGain
            spreadData.spreadStayTime = self.origSpreadStayTime
            spreadData.spreadDissipateTime = self.origSpreadDissipateTime
            spreadData.proneMultiplier = self.bipodSpreadProneMultiplier
            self.weapon.followupSpread = spreadData
        end
    else
        self.weapon.recoilKickbackProneMultiplier = self.origKickbackProne
        self.weapon.recoilSnapProneMultiplier = self.origSnapProne
        
        if self.weapon.followupSpread ~= nil then
            local spreadData = self.weapon.followupSpread
            spreadData.maxSpreadAim = self.origMaxSpreadAim
            spreadData.maxSpreadHip = self.origMaxSpreadHip
            spreadData.spreadGain = self.origSpreadGain
            spreadData.spreadStayTime = self.origSpreadStayTime
            spreadData.spreadDissipateTime = self.origSpreadDissipateTime
            spreadData.proneMultiplier = self.origSpreadProne
            self.weapon.followupSpread = spreadData
        end
    end

    self:ApplyState()
end

function SimpleBipod:OnEnable()
    if self.animator == nil then return end
    self.animator.SetInteger(self.stateParameter, self.stateValues[self.isDeployed and 2 or 1])
end

function SimpleBipod:Update()
    if self.weapon == nil or self.anchor == nil then return end

    local ray = Ray(self.anchor.position, Vector3.down)
    local hitInfo = Physics.Raycast(ray, self.raycastDistance, RaycastTarget.ActorWalkable)

    if hitInfo then
        self.missTimer = 0
        
        if not self.isDeployed then
            self.hitTimer = self.hitTimer + Time.deltaTime
            if self.hitTimer >= self.detectionDelay then
                self:ChangeState(true)
            end
        else
            self.hitTimer = 0
        end
    else
        self.hitTimer = 0
        
        if self.isDeployed then
            self.missTimer = self.missTimer + Time.deltaTime
            if self.missTimer >= self.detectionDelay then
                self:ChangeState(false)
            end
        else
            self.missTimer = 0
        end
    end
end