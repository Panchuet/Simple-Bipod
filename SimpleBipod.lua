behaviour("SimpleBipod")

-- Keys:
--   raycastDistance         (float)  : Length from BipodObject to the bottom of the legs
--   detectionDelay          (float)  : Time in seconds the raycast must hit/miss before deploying/undeploying
--   bipodKickbackMultiplier (float)  : Multiplier applied to recoilBaseKickback and recoilRandomKickback when deployed and grounded
--   bipodSnapMultiplier     (float)  : Multiplier applied to recoilSnapMagnitude when deployed and grounded
--   bipodSpreadMultiplier   (float)  : Multiplier applied to followupSpread maxSpreadAim and maxSpreadHip when deployed and grounded
--   deployParameterName     (string) : Name of the animator trigger parameter for the deploy hand animation
--   undeployParameterName   (string) : Name of the animator trigger parameter for the fold hand animation
--   stateValues             (string) : Two space-separated ints e.g. "0 1" (0 = folded, 1 = deployed)
--   stateParameterName      (string) : Name of the animator int parameter (holds the physical bipod position)

function SimpleBipod:Start()
    self.weapon = self.gameObject.GetComponent(Weapon)
    self.animator = self.gameObject.GetComponent(Animator)
    self.dataContainer = self.gameObject.GetComponent(DataContainer)

    self.raycastDistance = self.dataContainer.GetFloat("raycastDistance")
    self.detectionDelay = self.dataContainer.GetFloat("detectionDelay")

    self.bipodKickbackMultiplier = self.dataContainer.GetFloat("bipodKickbackMultiplier")
    self.bipodSnapMultiplier = self.dataContainer.GetFloat("bipodSnapMultiplier")
    self.bipodSpreadMultiplier = self.dataContainer.GetFloat("bipodSpreadMultiplier")

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

    self.origBaseKickback = self.weapon.recoilBaseKickback
    self.origRandomKickback = self.weapon.recoilRandomKickback
    self.origSnapMagnitude = self.weapon.recoilSnapMagnitude

    local spreadData = self.weapon.followupSpread
    self.origMaxSpreadAim = spreadData.maxSpreadAim
    self.origMaxSpreadHip = spreadData.maxSpreadHip
    self.origSpreadGain = spreadData.spreadGain
    self.origSpreadStayTime = spreadData.spreadStayTime
    self.origSpreadDissipateTime = spreadData.spreadDissipateTime
    self.origProneMultiplier = spreadData.proneMultiplier

    self.isDeployed = false
    self.isGrounded = false

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
    if self.weapon.isReloading then return end
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

    self:ApplyState()
end

function SimpleBipod:ApplyAccuracy(grounded)
    if grounded then
        self.weapon.recoilBaseKickback = self.origBaseKickback * self.bipodKickbackMultiplier
        self.weapon.recoilRandomKickback = self.origRandomKickback * self.bipodKickbackMultiplier
        self.weapon.recoilSnapMagnitude = self.origSnapMagnitude * self.bipodSnapMultiplier

        local spreadData = self.weapon.followupSpread
        spreadData.maxSpreadAim = self.origMaxSpreadAim * self.bipodSpreadMultiplier
        spreadData.maxSpreadHip = self.origMaxSpreadHip * self.bipodSpreadMultiplier
        spreadData.spreadGain = self.origSpreadGain
        spreadData.spreadStayTime = self.origSpreadStayTime
        spreadData.spreadDissipateTime = self.origSpreadDissipateTime
        spreadData.proneMultiplier = self.origProneMultiplier
        self.weapon.followupSpread = spreadData
    else
        self.weapon.recoilBaseKickback = self.origBaseKickback
        self.weapon.recoilRandomKickback = self.origRandomKickback
        self.weapon.recoilSnapMagnitude = self.origSnapMagnitude

        local spreadData = self.weapon.followupSpread
        spreadData.maxSpreadAim = self.origMaxSpreadAim
        spreadData.maxSpreadHip = self.origMaxSpreadHip
        spreadData.spreadGain = self.origSpreadGain
        spreadData.spreadStayTime = self.origSpreadStayTime
        spreadData.spreadDissipateTime = self.origSpreadDissipateTime
        spreadData.proneMultiplier = self.origProneMultiplier
        self.weapon.followupSpread = spreadData
    end
end

function SimpleBipod:OnEnable()
    if self.animator == nil then return end
    self.animator.SetInteger(self.stateParameter, self.stateValues[self.isDeployed and 2 or 1])
end

function SimpleBipod:Update()
    if self.weapon == nil or self.anchor == nil then return end

    local ray = Ray(self.anchor.position, Vector3.down)
    local hitInfo = Physics.Raycast(ray, self.raycastDistance, RaycastTarget.ActorWalkable)

    local shouldBeGrounded = hitInfo and self.isDeployed

    if shouldBeGrounded ~= self.isGrounded then
        self.isGrounded = shouldBeGrounded
        self:ApplyAccuracy(self.isGrounded)
    end

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