--- This module contains the CLIENT class.
-- 
-- 1) @{Client#CLIENT} class, extends @{Unit#UNIT}
-- ===============================================
-- Clients are those **Units** defined within the Mission Editor that have the skillset defined as __Client__ or __Player__.
-- Note that clients are NOT the same as Units, they are NOT necessarily alive.
-- The @{Client#CLIENT} class is a wrapper class to handle the DCS Unit objects that have the skillset defined as __Client__ or __Player__:
-- 
--  * Wraps the DCS Unit objects with skill level set to Player or Client.
--  * Support all DCS Unit APIs.
--  * Enhance with Unit specific APIs not in the DCS Group API set.
--  * When player joins Unit, execute alive init logic.
--  * Handles messages to players.
--  * Manage the "state" of the DCS Unit.
-- 
-- Clients are being used by the @{MISSION} class to follow players and register their successes.
--  
-- 1.1) CLIENT reference methods
-- -----------------------------
-- For each DCS Unit having skill level Player or Client, a CLIENT wrapper object (instance) will be created within the _@{DATABASE} object.
-- This is done at the beginning of the mission (when the mission starts).
--  
-- The CLIENT class does not contain a :New() method, rather it provides :Find() methods to retrieve the object reference
-- using the DCS Unit or the DCS UnitName.
-- 
-- Another thing to know is that CLIENT objects do not "contain" the DCS Unit object. 
-- The CLIENT methods will reference the DCS Unit object by name when it is needed during API execution.
-- If the DCS Unit object does not exist or is nil, the CLIENT methods will return nil and log an exception in the DCS.log file.
--  
-- The CLIENT class provides the following functions to retrieve quickly the relevant CLIENT instance:
-- 
--  * @{#CLIENT.Find}(): Find a CLIENT instance from the _DATABASE object using a DCS Unit object.
--  * @{#CLIENT.FindByName}(): Find a CLIENT instance from the _DATABASE object using a DCS Unit name.
--  
-- IMPORTANT: ONE SHOULD NEVER SANATIZE these CLIENT OBJECT REFERENCES! (make the CLIENT object references nil).
-- 
-- @module Client
-- @author FlightControl

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Cargo" )
Include.File( "Message" )


--- The CLIENT class
-- @type CLIENT
-- @extends Unit#UNIT
CLIENT = {
	ONBOARDSIDE = {
		NONE = 0,
		LEFT = 1,
		RIGHT = 2,
		BACK = 3,
		FRONT = 4
	},
	ClassName = "CLIENT",
	ClientName = nil,
	ClientAlive = false,
	ClientTransport = false,
	ClientBriefingShown = false,
	_Menus = {},
	_Tasks = {},
	Messages = { 
	}
}


--- Finds a CLIENT from the _DATABASE using the relevant DCS Unit.
-- @param #CLIENT self
-- @param #string ClientName Name of the DCS **Unit** as defined within the Mission Editor.
-- @param #string ClientBriefing Text that describes the briefing of the mission when a Player logs into the Client.
-- @return #CLIENT
-- @usage
-- -- Create new Clients.
--  local Mission = MISSIONSCHEDULER.AddMission( 'Russia Transport Troops SA-6', 'Operational', 'Transport troops from the control center to one of the SA-6 SAM sites to activate their operation.', 'Russia' )
--  Mission:AddGoal( DeploySA6TroopsGoal )
--
--  Mission:AddClient( CLIENT:FindByName( 'RU MI-8MTV2*HOT-Deploy Troops 1' ):Transport() )
--  Mission:AddClient( CLIENT:FindByName( 'RU MI-8MTV2*RAMP-Deploy Troops 3' ):Transport() )
--  Mission:AddClient( CLIENT:FindByName( 'RU MI-8MTV2*HOT-Deploy Troops 2' ):Transport() )
--  Mission:AddClient( CLIENT:FindByName( 'RU MI-8MTV2*RAMP-Deploy Troops 4' ):Transport() )
function CLIENT:Find( DCSUnit )
  local ClientName = DCSUnit:getName()
  local ClientFound = _DATABASE:FindClient( ClientName )
  
  if ClientFound then
    ClientFound:F( ClientName )
    return ClientFound
  end
  
  error( "CLIENT not found for: " .. ClientName )
end


--- Finds a CLIENT from the _DATABASE using the relevant Client Unit Name.
-- As an optional parameter, a briefing text can be given also.
-- @param #CLIENT self
-- @param #string ClientName Name of the DCS **Unit** as defined within the Mission Editor.
-- @param #string ClientBriefing Text that describes the briefing of the mission when a Player logs into the Client.
-- @return #CLIENT
-- @usage
-- -- Create new Clients.
--	local Mission = MISSIONSCHEDULER.AddMission( 'Russia Transport Troops SA-6', 'Operational', 'Transport troops from the control center to one of the SA-6 SAM sites to activate their operation.', 'Russia' )
--	Mission:AddGoal( DeploySA6TroopsGoal )
--
--	Mission:AddClient( CLIENT:FindByName( 'RU MI-8MTV2*HOT-Deploy Troops 1' ):Transport() )
--	Mission:AddClient( CLIENT:FindByName( 'RU MI-8MTV2*RAMP-Deploy Troops 3' ):Transport() )
--	Mission:AddClient( CLIENT:FindByName( 'RU MI-8MTV2*HOT-Deploy Troops 2' ):Transport() )
--	Mission:AddClient( CLIENT:FindByName( 'RU MI-8MTV2*RAMP-Deploy Troops 4' ):Transport() )
function CLIENT:FindByName( ClientName, ClientBriefing )
  local ClientFound = _DATABASE:FindClient( ClientName )

  if ClientFound then
    ClientFound:F( { ClientName, ClientBriefing } )
    ClientFound:AddBriefing( ClientBriefing )
    ClientFound.MessageSwitch = true

  	return ClientFound
  end
  
  error( "CLIENT not found for: " .. ClientName )
end

function CLIENT:Register( ClientName )
  local self = BASE:Inherit( self, UNIT:Register( ClientName ) )

  self:F( ClientName )
  self.ClientName = ClientName
  self.MessageSwitch = true
  self.ClientAlive2 = false
  
  --self.AliveCheckScheduler = routines.scheduleFunction( self._AliveCheckScheduler, { self }, timer.getTime() + 1, 5 )
  self.AliveCheckScheduler = SCHEDULER:New( self, self._AliveCheckScheduler, {}, 1, 5 )

  return self
end


--- Transport defines that the Client is a Transport. Transports show cargo.
-- @param #CLIENT self
-- @return #CLIENT
function CLIENT:Transport()
  self:F()

  self.ClientTransport = true
  return self
end

--- AddBriefing adds a briefing to a CLIENT when a player joins a mission.
-- @param #CLIENT self
-- @param #string ClientBriefing is the text defining the Mission briefing.
-- @return #CLIENT self
function CLIENT:AddBriefing( ClientBriefing )
  self:F( ClientBriefing )
  self.ClientBriefing = ClientBriefing
  self.ClientBriefingShown = false
  
  return self
end

--- Show the briefing of a CLIENT.
-- @param #CLIENT self
-- @return #CLIENT self
function CLIENT:ShowBriefing()
  self:F( { self.ClientName, self.ClientBriefingShown } )

  if not self.ClientBriefingShown then
    self.ClientBriefingShown = true
    local Briefing = ""
    if self.ClientBriefing then
      Briefing = Briefing .. self.ClientBriefing
    end
    Briefing = Briefing .. " Press [LEFT ALT]+[B] to view the complete mission briefing."
    self:Message( Briefing, 60,  self.ClientName .. '/ClientBriefing', "Briefing" )
  end

  return self
end

--- Show the mission briefing of a MISSION to the CLIENT.
-- @param #CLIENT self
-- @param #string MissionBriefing
-- @return #CLIENT self
function CLIENT:ShowMissionBriefing( MissionBriefing )
  self:F( { self.ClientName } )

  if MissionBriefing then
    self:Message( MissionBriefing, 60,  self.ClientName .. '/MissionBriefing', "Mission Briefing" )
  end

  return self
end



--- Resets a CLIENT.
-- @param #CLIENT self
-- @param #string ClientName Name of the Group as defined within the Mission Editor. The Group must have a Unit with the type Client.
function CLIENT:Reset( ClientName )
	self:F()
	self._Menus = {}
end

-- Is Functions

--- Checks if the CLIENT is a multi-seated UNIT.
-- @param #CLIENT self
-- @return #boolean true if multi-seated.
function CLIENT:IsMultiSeated()
  self:F( self.ClientName )

  local ClientMultiSeatedTypes = { 
    ["Mi-8MT"]  = "Mi-8MT", 
    ["UH-1H"]   = "UH-1H", 
    ["P-51B"]   = "P-51B" 
  }
  
  if self:IsAlive() then
    local ClientTypeName = self:GetClientGroupUnit():GetTypeName()
    if ClientMultiSeatedTypes[ClientTypeName] then
      return true
    end
  end
  
  return false
end

--- Checks for a client alive event and calls a function on a continuous basis.
-- @param #CLIENT self
-- @param #function CallBack Function.
-- @return #CLIENT
function CLIENT:Alive( CallBack, ... )
  self:F()
  
  self.ClientCallBack = CallBack
  self.ClientParameters = arg

  return self
end

--- @param #CLIENT self
function CLIENT:_AliveCheckScheduler()
  self:F( { self.ClientName, self.ClientAlive2, self.ClientBriefingShown } )

  if self:IsAlive() then -- Polymorphic call of UNIT
    if self.ClientAlive2 == false then
      self:ShowBriefing()
      if self.ClientCallBack then
        self:T("Calling Callback function")
        self.ClientCallBack( self, unpack( self.ClientParameters ) )
      end
      self.ClientAlive2 = true
    end
  else
    if self.ClientAlive2 == true then
      self.ClientAlive2 = false
    end
  end
  
  return true
end

--- Return the DCSGroup of a Client.
-- This function is modified to deal with a couple of bugs in DCS 1.5.3
-- @param #CLIENT self
-- @return DCSGroup#Group
function CLIENT:GetDCSGroup()
  self:F3()

--  local ClientData = Group.getByName( self.ClientName )
--	if ClientData and ClientData:isExist() then
--		self:T( self.ClientName .. " : group found!" )
--		return ClientData
--	else
--		return nil
--	end
  
  local ClientUnit = Unit.getByName( self.ClientName )

	local CoalitionsData = { AlivePlayersRed = coalition.getPlayers( coalition.side.RED ), AlivePlayersBlue = coalition.getPlayers( coalition.side.BLUE ) }
	for CoalitionId, CoalitionData in pairs( CoalitionsData ) do
		self:T3( { "CoalitionData:", CoalitionData } )
		for UnitId, UnitData in pairs( CoalitionData ) do
			self:T3( { "UnitData:", UnitData } )
			if UnitData and UnitData:isExist() then

        --self:E(self.ClientName)
        if ClientUnit then
  				local ClientGroup = ClientUnit:getGroup()
  				if ClientGroup then
  					self:T3( "ClientGroup = " .. self.ClientName )
  					if ClientGroup:isExist() and UnitData:getGroup():isExist() then 
  						if ClientGroup:getID() == UnitData:getGroup():getID() then
  							self:T3( "Normal logic" )
  							self:T3( self.ClientName .. " : group found!" )
                self.ClientGroupID = ClientGroup:getID()
  							self.ClientGroupName = ClientGroup:getName()
  							return ClientGroup
  						end
  					else
  						-- Now we need to resolve the bugs in DCS 1.5 ...
  						-- Consult the database for the units of the Client Group. (ClientGroup:getUnits() returns nil)
  						self:T3( "Bug 1.5 logic" )
  						local ClientGroupTemplate = _DATABASE.Templates.Units[self.ClientName].GroupTemplate
  						self.ClientGroupID = ClientGroupTemplate.groupId
  						self.ClientGroupName = _DATABASE.Templates.Units[self.ClientName].GroupName
  						self:T3( self.ClientName .. " : group found in bug 1.5 resolvement logic!" )
  						return ClientGroup
  					end
  --				else
  --					error( "Client " .. self.ClientName .. " not found!" )
  				end
  			else
  			  --self:E( { "Client not found!", self.ClientName } )
  		  end
			end
		end
	end

	-- For non player clients
	if ClientUnit then
  	local ClientGroup = ClientUnit:getGroup()
  	if ClientGroup then
  		self:T3( "ClientGroup = " .. self.ClientName )
  		if ClientGroup:isExist() then 
  			self:T3( "Normal logic" )
  			self:T3( self.ClientName .. " : group found!" )
  			return ClientGroup
  		end
  	end
  end
	
	self.ClientGroupID = nil
	self.ClientGroupUnit = nil
	
	return nil
end 


-- TODO: Check DCSTypes#Group.ID
--- Get the group ID of the client.
-- @param #CLIENT self
-- @return DCSTypes#Group.ID
function CLIENT:GetClientGroupID()

  local ClientGroup = self:GetDCSGroup()

  --self:E( self.ClientGroupID ) -- Determined in GetDCSGroup()
	return self.ClientGroupID
end


--- Get the name of the group of the client.
-- @param #CLIENT self
-- @return #string
function CLIENT:GetClientGroupName()

  local ClientGroup = self:GetDCSGroup()

  self:T( self.ClientGroupName ) -- Determined in GetDCSGroup()
	return self.ClientGroupName
end

--- Returns the UNIT of the CLIENT.
-- @param #CLIENT self
-- @return Unit#UNIT
function CLIENT:GetClientGroupUnit()
	self:F2()

	local ClientDCSUnit = Unit.getByName( self.ClientName )

  self:T( self.ClientDCSUnit )
	if ClientDCSUnit and ClientDCSUnit:isExist() then
		local ClientUnit = _DATABASE:FindUnit( self.ClientName )
		self:T2( ClientUnit )
		return ClientUnit
	end
end

--- Returns the DCSUnit of the CLIENT.
-- @param #CLIENT self
-- @return DCSTypes#Unit
function CLIENT:GetClientGroupDCSUnit()
	self:F2()

  local ClientDCSUnit = Unit.getByName( self.ClientName )
  
  if ClientDCSUnit and ClientDCSUnit:isExist() then
    self:T2( ClientDCSUnit )
    return ClientDCSUnit
  end
end


--- Evaluates if the CLIENT is a transport.
-- @param #CLIENT self
-- @return #boolean true is a transport.
function CLIENT:IsTransport()
	self:F()
	return self.ClientTransport
end

--- Shows the @{Cargo#CARGO} contained within the CLIENT to the player as a message.
-- The @{Cargo#CARGO} is shown using the @{Message#MESSAGE} distribution system.
-- @param #CLIENT self
function CLIENT:ShowCargo()
	self:F()

	local CargoMsg = ""
  
	for CargoName, Cargo in pairs( CARGOS ) do
		if self == Cargo:IsLoadedInClient() then
			CargoMsg = CargoMsg .. Cargo.CargoName .. " Type:" ..  Cargo.CargoType .. " Weight: " .. Cargo.CargoWeight .. "\n"
		end
	end
  
	if CargoMsg == "" then
		CargoMsg = "empty"
	end
  
	self:Message( CargoMsg, 15, self.ClientName .. "/Cargo", "Co-Pilot: Cargo Status", 30 )

end

-- TODO (1) I urgently need to revise this.
--- A local function called by the DCS World Menu system to switch off messages.
function CLIENT.SwitchMessages( PrmTable )
	PrmTable[1].MessageSwitch = PrmTable[2]
end

--- The main message driver for the CLIENT.
-- This function displays various messages to the Player logged into the CLIENT through the DCS World Messaging system.
-- @param #CLIENT self
-- @param #string Message is the text describing the message.
-- @param #number MessageDuration is the duration in seconds that the Message should be displayed.
-- @param #string MessageId is a text identifying the Message in the MessageQueue. The Message system overwrites Messages with the same MessageId
-- @param #string MessageCategory is the category of the message (the title).
-- @param #number MessageInterval is the interval in seconds between the display of the @{Message#MESSAGE} when the CLIENT is in the air.
function CLIENT:Message( Message, MessageDuration, MessageId, MessageCategory, MessageInterval )
	self:F( { Message, MessageDuration, MessageId, MessageCategory, MessageInterval } )

	if not self.MenuMessages then
		if self:GetClientGroupID() then
			self.MenuMessages = MENU_CLIENT:New( self, 'Messages' )
			self.MenuRouteMessageOn = MENU_CLIENT_COMMAND:New( self, 'Messages On', self.MenuMessages, CLIENT.SwitchMessages, { self, true } )
			self.MenuRouteMessageOff = MENU_CLIENT_COMMAND:New( self,'Messages Off', self.MenuMessages, CLIENT.SwitchMessages, { self, false } )
		end
	end

	if self.MessageSwitch == true then
		if MessageCategory == nil then
			MessageCategory = "Messages"
		end
		if self.Messages[MessageId] == nil then
			self.Messages[MessageId] = {}
			self.Messages[MessageId].MessageId = MessageId
			self.Messages[MessageId].MessageTime = timer.getTime()
			self.Messages[MessageId].MessageDuration = MessageDuration
			if MessageInterval == nil then
				self.Messages[MessageId].MessageInterval = 600
			else
				self.Messages[MessageId].MessageInterval = MessageInterval
			end
			MESSAGE:New( Message, MessageCategory, MessageDuration, MessageId ):ToClient( self )
		else
			if self:GetClientGroupDCSUnit() and not self:GetClientGroupDCSUnit():inAir() then
				if timer.getTime() - self.Messages[MessageId].MessageTime >= self.Messages[MessageId].MessageDuration + 10 then
					MESSAGE:New( Message, MessageCategory, MessageDuration, MessageId ):ToClient( self )
					self.Messages[MessageId].MessageTime = timer.getTime()
				end
			else
				if timer.getTime() - self.Messages[MessageId].MessageTime  >= self.Messages[MessageId].MessageDuration + self.Messages[MessageId].MessageInterval then
					MESSAGE:New( Message, MessageCategory, MessageDuration, MessageId ):ToClient( self )
					self.Messages[MessageId].MessageTime = timer.getTime()
				end
			end
		end
	end
end
