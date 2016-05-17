--- Manage sets of units and groups. 
-- 
-- @{#Database} class
-- ==================
-- Mission designers can use the DATABASE class to build sets of units belonging to certain:
-- 
--  * Coalitions
--  * Categories
--  * Countries
--  * Unit types
--  * Starting with certain prefix strings.
--  
-- This list will grow over time. Planned developments are to include filters and iterators.
-- Additional filters will be added around @{Zone#ZONEs}, Radiuses, Active players, ...
-- More iterators will be implemented in the near future ...
--
-- Administers the Initial Sets of the Mission Templates as defined within the Mission Editor.
-- 
-- DATABASE construction methods:
-- =================================
-- Create a new DATABASE object with the @{#DATABASE.New} method:
-- 
--    * @{#DATABASE.New}: Creates a new DATABASE object.
--   
-- 
-- DATABASE filter criteria: 
-- =========================
-- You can set filter criteria to define the set of units within the database.
-- Filter criteria are defined by:
-- 
--    * @{#DATABASE.FilterCoalitions}: Builds the DATABASE with the units belonging to the coalition(s).
--    * @{#DATABASE.FilterCategories}: Builds the DATABASE with the units belonging to the category(ies).
--    * @{#DATABASE.FilterTypes}: Builds the DATABASE with the units belonging to the unit type(s).
--    * @{#DATABASE.FilterCountries}: Builds the DATABASE with the units belonging to the country(ies).
--    * @{#DATABASE.FilterUnitPrefixes}: Builds the DATABASE with the units starting with the same prefix string(s).
--   
-- Once the filter criteria have been set for the DATABASE, you can start filtering using:
-- 
--   * @{#DATABASE.FilterStart}: Starts the filtering of the units within the database.
-- 
-- Planned filter criteria within development are (so these are not yet available):
-- 
--    * @{#DATABASE.FilterGroupPrefixes}: Builds the DATABASE with the groups of the units starting with the same prefix string(s).
--    * @{#DATABASE.FilterZones}: Builds the DATABASE with the units within a @{Zone#ZONE}.
-- 
-- 
-- DATABASE iterators:
-- ===================
-- Once the filters have been defined and the DATABASE has been built, you can iterate the database with the available iterator methods.
-- The iterator methods will walk the DATABASE set, and call for each element within the set a function that you provide.
-- The following iterator methods are currently available within the DATABASE:
-- 
--   * @{#DATABASE.ForEachAliveUnit}: Calls a function for each alive unit it finds within the DATABASE.
--   
-- Planned iterators methods in development are (so these are not yet available):
-- 
--   * @{#DATABASE.ForEachUnit}: Calls a function for each unit contained within the DATABASE.
--   * @{#DATABASE.ForEachGroup}: Calls a function for each group contained within the DATABASE.
--   * @{#DATABASE.ForEachUnitInZone}: Calls a function for each unit within a certain zone contained within the DATABASE.
-- 
-- ====
-- @module Database
-- @author FlightControl

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Menu" )
Include.File( "Group" )
Include.File( "Unit" )
Include.File( "Event" )
Include.File( "Client" )

--- DATABASE class
-- @type DATABASE
-- @extends Base#BASE
DATABASE = {
  ClassName = "DATABASE",
  Templates = {
    Units = {},
    Groups = {},
    ClientsByName = {},
    ClientsByID = {},
  },
  DCSUnits = {},
  DCSUnitsAlive = {},
  DCSGroups = {},
  DCSGroupsAlive = {},
  Units = {},
  UnitsAlive = {},
  Groups = {},
  GroupsAlive = {},
  NavPoints = {},
  Statics = {},
  Players = {},
  PlayersAlive = {},
  Clients = {},
  ClientsAlive = {},
  Filter = {
    Coalitions = nil,
    Categories = nil,
    Types = nil,
    Countries = nil,
    UnitPrefixes = nil,
    GroupPrefixes = nil,
  },
  FilterMeta = {
    Coalitions = {
      red = coalition.side.RED,
      blue = coalition.side.BLUE,
      neutral = coalition.side.NEUTRAL,
    },
    Categories = {
      plane = Unit.Category.AIRPLANE,
      helicopter = Unit.Category.HELICOPTER,
      ground = Unit.Category.GROUND_UNIT,
      ship = Unit.Category.SHIP,
      structure = Unit.Category.STRUCTURE,
    },
  },
}

local _DATABASECoalition =
  {
    [1] = "Red",
    [2] = "Blue",
  }

local _DATABASECategory =
  {
    [Unit.Category.AIRPLANE] = "Plane",
    [Unit.Category.HELICOPTER] = "Helicopter",
    [Unit.Category.GROUND_UNIT] = "Vehicle",
    [Unit.Category.SHIP] = "Ship",
    [Unit.Category.STRUCTURE] = "Structure",
  }


--- Creates a new DATABASE object, building a set of units belonging to a coalitions, categories, countries, types or with defined prefix names.
-- @param #DATABASE self
-- @return #DATABASE
-- @usage
-- -- Define a new DATABASE Object. This DBObject will contain a reference to all Group and Unit Templates defined within the ME and the DCSRTE.
-- DBObject = DATABASE:New()
function DATABASE:New()

  -- Inherits from BASE
  local self = BASE:Inherit( self, BASE:New() )
  
  _EVENTDISPATCHER:OnBirth( self._EventOnBirth, self )
  _EVENTDISPATCHER:OnDead( self._EventOnDeadOrCrash, self )
  _EVENTDISPATCHER:OnCrash( self._EventOnDeadOrCrash, self )
  
  
  -- Add database with registered clients and already alive players
  
  -- Follow alive players and clients
  _EVENTDISPATCHER:OnPlayerEnterUnit( self._EventOnPlayerEnterUnit, self )
  _EVENTDISPATCHER:OnPlayerLeaveUnit( self._EventOnPlayerLeaveUnit, self )
  
  
  return self
end

--- Builds a set of units of coalitons.
-- Possible current coalitions are red, blue and neutral.
-- @param #DATABASE self
-- @param #string Coalitions Can take the following values: "red", "blue", "neutral".
-- @return #DATABASE self
function DATABASE:FilterCoalitions( Coalitions )
  if not self.Filter.Coalitions then
    self.Filter.Coalitions = {}
  end
  if type( Coalitions ) ~= "table" then
    Coalitions = { Coalitions }
  end
  for CoalitionID, Coalition in pairs( Coalitions ) do
    self.Filter.Coalitions[Coalition] = Coalition
  end
  return self
end

--- Builds a set of units out of categories.
-- Possible current categories are plane, helicopter, ground, ship.
-- @param #DATABASE self
-- @param #string Categories Can take the following values: "plane", "helicopter", "ground", "ship".
-- @return #DATABASE self
function DATABASE:FilterCategories( Categories )
  if not self.Filter.Categories then
    self.Filter.Categories = {}
  end
  if type( Categories ) ~= "table" then
    Categories = { Categories }
  end
  for CategoryID, Category in pairs( Categories ) do
    self.Filter.Categories[Category] = Category
  end
  return self
end

--- Builds a set of units of defined unit types.
-- Possible current types are those types known within DCS world.
-- @param #DATABASE self
-- @param #string Types Can take those type strings known within DCS world.
-- @return #DATABASE self
function DATABASE:FilterTypes( Types )
  if not self.Filter.Types then
    self.Filter.Types = {}
  end
  if type( Types ) ~= "table" then
    Types = { Types }
  end
  for TypeID, Type in pairs( Types ) do
    self.Filter.Types[Type] = Type
  end
  return self
end

--- Builds a set of units of defined countries.
-- Possible current countries are those known within DCS world.
-- @param #DATABASE self
-- @param #string Countries Can take those country strings known within DCS world.
-- @return #DATABASE self
function DATABASE:FilterCountries( Countries )
  if not self.Filter.Countries then
    self.Filter.Countries = {}
  end
  if type( Countries ) ~= "table" then
    Countries = { Countries }
  end
  for CountryID, Country in pairs( Countries ) do
    self.Filter.Countries[Country] = Country
  end
  return self
end

--- Builds a set of units of defined unit prefixes.
-- All the units starting with the given prefixes will be included within the set.
-- @param #DATABASE self
-- @param #string Prefixes The prefix of which the unit name starts with.
-- @return #DATABASE self
function DATABASE:FilterUnitPrefixes( Prefixes )
  if not self.Filter.UnitPrefixes then
    self.Filter.UnitPrefixes = {}
  end
  if type( Prefixes ) ~= "table" then
    Prefixes = { Prefixes }
  end
  for PrefixID, Prefix in pairs( Prefixes ) do
    self.Filter.UnitPrefixes[Prefix] = Prefix
  end
  return self
end

--- Builds a set of units of defined group prefixes.
-- All the units starting with the given group prefixes will be included within the set.
-- @param #DATABASE self
-- @param #string Prefixes The prefix of which the group name where the unit belongs to starts with.
-- @return #DATABASE self
function DATABASE:FilterGroupPrefixes( Prefixes )
  if not self.Filter.GroupPrefixes then
    self.Filter.GroupPrefixes = {}
  end
  if type( Prefixes ) ~= "table" then
    Prefixes = { Prefixes }
  end
  for PrefixID, Prefix in pairs( Prefixes ) do
    self.Filter.GroupPrefixes[Prefix] = Prefix
  end
  return self
end

--- Starts the filtering.
-- @param #DATABASE self
-- @return #DATABASE self
function DATABASE:FilterStart()

  if _DATABASE then
    -- OK, we have a _DATABASE
    -- Now use the different filters to build the set.
    -- We first take ALL of the Units of the _DATABASE.
    
    self:E( { "Adding Database Datapoints with filters" } )
    for DCSUnitName, DCSUnit in pairs( _DATABASE.DCSUnits ) do

      if self:_IsIncludeDCSUnit( DCSUnit ) then

        self:E( { "Adding Unit:", DCSUnitName } )
        self.DCSUnits[DCSUnitName] = _DATABASE.DCSUnits[DCSUnitName]
        self.Units[DCSUnitName] = _DATABASE.Units[DCSUnitName]
        
        if _DATABASE.DCSUnitsAlive[DCSUnitName] then
          self.DCSUnitsAlive[DCSUnitName] = _DATABASE.DCSUnitsAlive[DCSUnitName]
          self.UnitsAlive[DCSUnitName] = _DATABASE.UnitsAlive[DCSUnitName]
        end
        
      end
    end
    
    for DCSGroupName, DCSGroup in pairs( _DATABASE.DCSGroups ) do
      
      --if self:_IsIncludeDCSGroup( DCSGroup ) then
      self:E( { "Adding Group:", DCSGroupName } )
      self.DCSGroups[DCSGroupName] = _DATABASE.DCSGroups[DCSGroupName]
      self.Groups[DCSGroupName] = _DATABASE.Groups[DCSGroupName]
      --end
      
      if _DATABASE.DCSGroupsAlive[DCSGroupName] then
        self.DCSGroupsAlive[DCSGroupName] = _DATABASE.DCSGroupsAlive[DCSGroupName]
        self.GroupsAlive[DCSGroupName] = _DATABASE.GroupsAlive[DCSGroupName]
      end
    end

    for DCSUnitName, Client in pairs( _DATABASE.Clients ) do
      self:E( { "Adding Client for Unit:", DCSUnitName } )
      self.Clients[DCSUnitName] = _DATABASE.Clients[DCSUnitName]
    end
    
  else
    self:E( "There is a structural error in MOOSE. No _DATABASE has been defined! Cannot build this custom DATABASE." )
  end
  
  return self
end


--- Instantiate new Groups within the DCSRTE.
-- This method expects EXACTLY the same structure as a structure within the ME, and needs 2 additional fields defined:
-- SpawnCountryID, SpawnCategoryID
-- This method is used by the SPAWN class.
-- @param #DATABASE self
-- @param #table SpawnTemplate
-- @return #DATABASE self
function DATABASE:Spawn( SpawnTemplate )
  self:F( SpawnTemplate.name )

  self:T( { SpawnTemplate.SpawnCountryID, SpawnTemplate.SpawnCategoryID } )

  -- Copy the spawn variables of the template in temporary storage, nullify, and restore the spawn variables.
  local SpawnCoalitionID = SpawnTemplate.SpawnCoalitionID
  local SpawnCountryID = SpawnTemplate.SpawnCountryID
  local SpawnCategoryID = SpawnTemplate.SpawnCategoryID

  -- Nullify
  SpawnTemplate.SpawnCoalitionID = nil
  SpawnTemplate.SpawnCountryID = nil
  SpawnTemplate.SpawnCategoryID = nil

  self:_RegisterGroup( SpawnTemplate )
  coalition.addGroup( SpawnCountryID, SpawnCategoryID, SpawnTemplate )

  -- Restore
  SpawnTemplate.SpawnCoalitionID = SpawnCoalitionID
  SpawnTemplate.SpawnCountryID = SpawnCountryID
  SpawnTemplate.SpawnCategoryID = SpawnCategoryID


  local SpawnGroup = GROUP:New( Group.getByName( SpawnTemplate.name ) )
  return SpawnGroup
end


--- Set a status to a Group within the Database, this to check crossing events for example.
function DATABASE:SetStatusGroup( GroupName, Status )
  self:F( Status )

  self.Templates.Groups[GroupName].Status = Status
end


--- Get a status to a Group within the Database, this to check crossing events for example.
function DATABASE:GetStatusGroup( GroupName )
  self:F( Status )

  if self.Templates.Groups[GroupName] then
    return self.Templates.Groups[GroupName].Status
  else
    return ""
  end
end

--- Private method that registers new Group Templates within the DATABASE Object.
-- @param #DATABASE self
-- @param #table GroupTemplate
-- @return #DATABASE self
function DATABASE:_RegisterGroup( GroupTemplate )

  local GroupTemplateName = env.getValueDictByKey(GroupTemplate.name)

  if not self.Templates.Groups[GroupTemplateName] then
    self.Templates.Groups[GroupTemplateName] = {}
    self.Templates.Groups[GroupTemplateName].Status = nil
  end
  
  -- Delete the spans from the route, it is not needed and takes memory.
  if GroupTemplate.route and GroupTemplate.route.spans then 
    GroupTemplate.route.spans = nil
  end
  
  self.Templates.Groups[GroupTemplateName].GroupName = GroupTemplateName
  self.Templates.Groups[GroupTemplateName].Template = GroupTemplate
  self.Templates.Groups[GroupTemplateName].groupId = GroupTemplate.groupId
  self.Templates.Groups[GroupTemplateName].UnitCount = #GroupTemplate.units
  self.Templates.Groups[GroupTemplateName].Units = GroupTemplate.units

  self:T( { "Group", self.Templates.Groups[GroupTemplateName].GroupName, self.Templates.Groups[GroupTemplateName].UnitCount } )

  for unit_num, UnitTemplate in pairs( GroupTemplate.units ) do

    local UnitTemplateName = env.getValueDictByKey(UnitTemplate.name)
    self.Templates.Units[UnitTemplateName] = {}
    self.Templates.Units[UnitTemplateName].UnitName = UnitTemplateName
    self.Templates.Units[UnitTemplateName].Template = UnitTemplate
    self.Templates.Units[UnitTemplateName].GroupName = GroupTemplateName
    self.Templates.Units[UnitTemplateName].GroupTemplate = GroupTemplate
    self.Templates.Units[UnitTemplateName].GroupId = GroupTemplate.groupId
    self:E( {"skill",UnitTemplate.skill})
    if UnitTemplate.skill and (UnitTemplate.skill == "Client" or UnitTemplate.skill == "Player") then
      self.Templates.ClientsByName[UnitTemplateName] = UnitTemplate
      self.Templates.ClientsByID[UnitTemplate.unitId] = UnitTemplate
    end
    self:E( { "Unit", self.Templates.Units[UnitTemplateName].UnitName } )
  end
end

--- Private method that registers all alive players in the mission.
-- @param #DATABASE self
-- @return #DATABASE self
function DATABASE:_RegisterPlayers()

  local CoalitionsData = { AlivePlayersRed = coalition.getPlayers( coalition.side.RED ), AlivePlayersBlue = coalition.getPlayers( coalition.side.BLUE ) }
  for CoalitionId, CoalitionData in pairs( CoalitionsData ) do
    for UnitId, UnitData in pairs( CoalitionData ) do
      self:T3( { "UnitData:", UnitData } )
      if UnitData and UnitData:isExist() then
        local UnitName = UnitData:getName()
        if not self.PlayersAlive[UnitName] then
          self:E( { "Add player for unit:", UnitName, UnitData:getPlayerName() } )
          self.PlayersAlive[UnitName] = UnitData:getPlayerName()
        end
      end
    end
  end
  
  return self
end

--- Private method that registers all datapoints within in the mission.
-- @param #DATABASE self
-- @return #DATABASE self
function DATABASE:_RegisterDatabase()

  local CoalitionsData = { AlivePlayersRed = coalition.getGroups( coalition.side.RED ), AlivePlayersBlue = coalition.getGroups( coalition.side.BLUE ) }
  for CoalitionId, CoalitionData in pairs( CoalitionsData ) do
    for DCSGroupId, DCSGroup in pairs( CoalitionData ) do

      local DCSGroupName = DCSGroup:getName()

      self:E( { "Register Group:", DCSGroup, DCSGroupName } )
      self.DCSGroups[DCSGroupName] = DCSGroup
      self.Groups[DCSGroupName] = GROUP:New( DCSGroup )

      if self:_IsAliveDCSGroup(DCSGroup) then
        self:E( { "Register Alive Group:", DCSGroup, DCSGroupName } )
        self.DCSGroupsAlive[DCSGroupName] = DCSGroup
        self.GroupsAlive[DCSGroupName] = self.Groups[DCSGroupName]  
      end

      for DCSUnitId, DCSUnit in pairs( DCSGroup:getUnits() ) do

        local DCSUnitName = DCSUnit:getName()
        self:E( { "Register Unit:", DCSUnit, DCSUnitName } )

        self.DCSUnits[DCSUnitName] = DCSUnit
        self.Units[DCSUnitName] = UNIT:New( DCSUnit )

        if self:_IsAliveDCSUnit(DCSUnit) then
          self:E( { "Register Alive Unit:", DCSUnit, DCSUnitName } )
          self.DCSUnitsAlive[DCSUnitName] = DCSUnit
          self.UnitsAlive[DCSUnitName] = self.Units[DCSUnitName]  
        end
      end
      
      for ClientName, ClientTemplate in pairs( self.Templates.ClientsByName ) do
        self.Clients[ClientName] = CLIENT:New( ClientName )
      end
    end
  end
  
  return self
end


--- Events

--- Handles the OnBirth event for the alive units set.
-- @param #DATABASE self
-- @param Event#EVENTDATA Event
function DATABASE:_EventOnBirth( Event )
  self:F( { Event } )

  if Event.IniDCSUnit then
    if self:_IsIncludeDCSUnit( Event.IniDCSUnit ) then
      self.DCSUnits[Event.IniDCSUnitName] = Event.IniDCSUnit 
      self.DCSUnitsAlive[Event.IniDCSUnitName] = Event.IniDCSUnit
      self.Units[Event.IniDCSUnitName] = UNIT:New( Event.IniDCSUnit )
      
      --if not self.DCSGroups[Event.IniDCSGroupName] then
      --  self.DCSGroups[Event.IniDCSGroupName] = Event.IniDCSGroupName
      --  self.DCSGroupsAlive[Event.IniDCSGroupName] = Event.IniDCSGroupName
      --  self.Groups[Event.IniDCSGroupName] = GROUP:New( Event.IniDCSGroup )
      --end
      self:_EventOnPlayerEnterUnit( Event )
    end
  end
end

--- Handles the OnDead or OnCrash event for alive units set.
-- @param #DATABASE self
-- @param Event#EVENTDATA Event
function DATABASE:_EventOnDeadOrCrash( Event )
  self:F( { Event } )

  if Event.IniDCSUnit then
    if self.DCSUnitsAlive[Event.IniDCSUnitName] then
      self.DCSUnits[Event.IniDCSUnitName] = nil 
      self.DCSUnitsAlive[Event.IniDCSUnitName] = nil
    end
  end
end

--- Handles the OnPlayerEnterUnit event to fill the active players table (with the unit filter applied).
-- @param #DATABASE self
-- @param Event#EVENTDATA Event
function DATABASE:_EventOnPlayerEnterUnit( Event )
  self:F( { Event } )

  if Event.IniDCSUnit then
    if self:_IsIncludeDCSUnit( Event.IniDCSUnit ) then
      if not self.PlayersAlive[Event.IniDCSUnitName] then
        self:E( { "Add player for unit:", Event.IniDCSUnitName, Event.IniDCSUnit:getPlayerName() } )
        self.PlayersAlive[Event.IniDCSUnitName] = Event.IniDCSUnit:getPlayerName()
        self.ClientsAlive[Event.IniDCSUnitName] = _DATABASE.Clients[ Event.IniDCSUnitName ]
      end
    end
  end
end

--- Handles the OnPlayerLeaveUnit event to clean the active players table.
-- @param #DATABASE self
-- @param Event#EVENTDATA Event
function DATABASE:_EventOnPlayerLeaveUnit( Event )
  self:F( { Event } )

  if Event.IniDCSUnit then
    if self:_IsIncludeDCSUnit( Event.IniDCSUnit ) then
      if self.PlayersAlive[Event.IniDCSUnitName] then
        self:E( { "Cleaning player for unit:", Event.IniDCSUnitName, Event.IniDCSUnit:getPlayerName() } )
        self.PlayersAlive[Event.IniDCSUnitName] = nil
        self.ClientsAlive[Event.IniDCSUnitName] = nil
      end
    end
  end
end

--- Iterators

--- Interate the DATABASE and call an interator function for the given set, providing the Object for each element within the set and optional parameters.
-- @param #DATABASE self
-- @param #function IteratorFunction The function that will be called when there is an alive player in the database.
-- @return #DATABASE self
function DATABASE:ForEach( IteratorFunction, arg, Set )
  self:F( arg )
  
  local function CoRoutine()
    local Count = 0
    for ObjectID, Object in pairs( Set ) do
        self:T2( Object )
        IteratorFunction( Object, unpack( arg ) )
        Count = Count + 1
        if Count % 10 == 0 then
          coroutine.yield( false )
        end    
    end
    return true
  end
  
  local co = coroutine.create( CoRoutine )
  
  local function Schedule()
  
    local status, res = coroutine.resume( co )
    self:T( { status, res } )
    
    if status == false then
      error( res )
    end
    if res == false then
      return true -- resume next time the loop
    end
    
    return false
  end

  local Scheduler = SCHEDULER:New( self, Schedule, {}, 0.001, 0.001, 0 )
  
  return self
end


--- Interate the DATABASE and call an interator function for each **alive** unit, providing the Unit and optional parameters.
-- @param #DATABASE self
-- @param #function IteratorFunction The function that will be called when there is an alive unit in the database. The function needs to accept a UNIT parameter.
-- @return #DATABASE self
function DATABASE:ForEachDCSUnitAlive( IteratorFunction, ... )
  self:F( arg )
  
  self:ForEach( IteratorFunction, arg, self.DCSUnitsAlive )

  return self
end

--- Interate the DATABASE and call an interator function for each **alive** player, providing the Unit of the player and optional parameters.
-- @param #DATABASE self
-- @param #function IteratorFunction The function that will be called when there is an alive player in the database. The function needs to accept a UNIT parameter.
-- @return #DATABASE self
function DATABASE:ForEachPlayer( IteratorFunction, ... )
  self:F( arg )
  
  self:ForEach( IteratorFunction, arg, self.PlayersAlive )
  
  return self
end


--- Interate the DATABASE and call an interator function for each client, providing the Client to the function and optional parameters.
-- @param #DATABASE self
-- @param #function IteratorFunction The function that will be called when there is an alive player in the database. The function needs to accept a CLIENT parameter.
-- @return #DATABASE self
function DATABASE:ForEachClient( IteratorFunction, ... )
  self:F( arg )
  
  self:ForEach( IteratorFunction, arg, self.Clients )

  return self
end


function DATABASE:ScanEnvironment()
  self:F()

  self.Navpoints = {}
  self.Units = {}
  --Build routines.db.units and self.Navpoints
  for coa_name, coa_data in pairs(env.mission.coalition) do

    if (coa_name == 'red' or coa_name == 'blue') and type(coa_data) == 'table' then
      --self.Units[coa_name] = {}

      ----------------------------------------------
      -- build nav points DB
      self.Navpoints[coa_name] = {}
      if coa_data.nav_points then --navpoints
        for nav_ind, nav_data in pairs(coa_data.nav_points) do

          if type(nav_data) == 'table' then
            self.Navpoints[coa_name][nav_ind] = routines.utils.deepCopy(nav_data)

            self.Navpoints[coa_name][nav_ind]['name'] = nav_data.callsignStr  -- name is a little bit more self-explanatory.
            self.Navpoints[coa_name][nav_ind]['point'] = {}  -- point is used by SSE, support it.
            self.Navpoints[coa_name][nav_ind]['point']['x'] = nav_data.x
            self.Navpoints[coa_name][nav_ind]['point']['y'] = 0
            self.Navpoints[coa_name][nav_ind]['point']['z'] = nav_data.y
          end
      end
      end
      -------------------------------------------------
      if coa_data.country then --there is a country table
        for cntry_id, cntry_data in pairs(coa_data.country) do

          local countryName = string.lower(cntry_data.name)
          --self.Units[coa_name][countryName] = {}
          --self.Units[coa_name][countryName]["countryId"] = cntry_data.id

          if type(cntry_data) == 'table' then  --just making sure

            for obj_type_name, obj_type_data in pairs(cntry_data) do

              if obj_type_name == "helicopter" or obj_type_name == "ship" or obj_type_name == "plane" or obj_type_name == "vehicle" or obj_type_name == "static" then --should be an unncessary check

                local category = obj_type_name

                if ((type(obj_type_data) == 'table') and obj_type_data.group and (type(obj_type_data.group) == 'table') and (#obj_type_data.group > 0)) then  --there's a group!

                  --self.Units[coa_name][countryName][category] = {}

                  for group_num, GroupTemplate in pairs(obj_type_data.group) do

                    if GroupTemplate and GroupTemplate.units and type(GroupTemplate.units) == 'table' then  --making sure again- this is a valid group
                      self:_RegisterGroup( GroupTemplate )
                    end --if GroupTemplate and GroupTemplate.units then
                  end --for group_num, GroupTemplate in pairs(obj_type_data.group) do
                end --if ((type(obj_type_data) == 'table') and obj_type_data.group and (type(obj_type_data.group) == 'table') and (#obj_type_data.group > 0)) then
              end --if obj_type_name == "helicopter" or obj_type_name == "ship" or obj_type_name == "plane" or obj_type_name == "vehicle" or obj_type_name == "static" then
          end --for obj_type_name, obj_type_data in pairs(cntry_data) do
          end --if type(cntry_data) == 'table' then
      end --for cntry_id, cntry_data in pairs(coa_data.country) do
      end --if coa_data.country then --there is a country table
    end --if coa_name == 'red' or coa_name == 'blue' and type(coa_data) == 'table' then
  end --for coa_name, coa_data in pairs(mission.coalition) do

  self:_RegisterDatabase()
  self:_RegisterPlayers()

  return self
end


---
-- @param #DATABASE self
-- @param DCSUnit#Unit DCSUnit
-- @return #DATABASE self
function DATABASE:_IsIncludeDCSUnit( DCSUnit )
  self:F( DCSUnit )
  local DCSUnitInclude = true

  if self.Filter.Coalitions then
    local DCSUnitCoalition = false
    for CoalitionID, CoalitionName in pairs( self.Filter.Coalitions ) do
      self:T( { "Coalition:", DCSUnit:getCoalition(), self.FilterMeta.Coalitions[CoalitionName], CoalitionName } )
      if self.FilterMeta.Coalitions[CoalitionName] and self.FilterMeta.Coalitions[CoalitionName] == DCSUnit:getCoalition() then
        DCSUnitCoalition = true
      end
    end
    DCSUnitInclude = DCSUnitInclude and DCSUnitCoalition
  end
  
  if self.Filter.Categories then
    local DCSUnitCategory = false
    for CategoryID, CategoryName in pairs( self.Filter.Categories ) do
      self:T( { "Category:", DCSUnit:getDesc().category, self.FilterMeta.Categories[CategoryName], CategoryName } )
      if self.FilterMeta.Categories[CategoryName] and self.FilterMeta.Categories[CategoryName] == DCSUnit:getDesc().category then
        DCSUnitCategory = true
      end
    end
    DCSUnitInclude = DCSUnitInclude and DCSUnitCategory
  end
  
  if self.Filter.Types then
    local DCSUnitType = false
    for TypeID, TypeName in pairs( self.Filter.Types ) do
      self:T( { "Type:", DCSUnit:getTypeName(), TypeName } )
      if TypeName == DCSUnit:getTypeName() then
        DCSUnitType = true
      end
    end
    DCSUnitInclude = DCSUnitInclude and DCSUnitType
  end
  
  if self.Filter.Countries then
    local DCSUnitCountry = false
    for CountryID, CountryName in pairs( self.Filter.Countries ) do
      self:T( { "Country:", DCSUnit:getCountry(), CountryName } )
      if country.id[CountryName] == DCSUnit:getCountry() then
        DCSUnitCountry = true
      end
    end
    DCSUnitInclude = DCSUnitInclude and DCSUnitCountry
  end

  if self.Filter.UnitPrefixes then
    local DCSUnitPrefix = false
    for UnitPrefixId, UnitPrefix in pairs( self.Filter.UnitPrefixes ) do
      self:T( { "Unit Prefix:", string.find( DCSUnit:getName(), UnitPrefix, 1 ), UnitPrefix } )
      if string.find( DCSUnit:getName(), UnitPrefix, 1 ) then
        DCSUnitPrefix = true
      end
    end
    DCSUnitInclude = DCSUnitInclude and DCSUnitPrefix
  end

  self:T( DCSUnitInclude )
  return DCSUnitInclude
end

---
-- @param #DATABASE self
-- @param DCSUnit#Unit DCSUnit
-- @return #DATABASE self
function DATABASE:_IsAliveDCSUnit( DCSUnit )
  self:F( DCSUnit )
  local DCSUnitAlive = false
  if DCSUnit and DCSUnit:isExist() and DCSUnit:isActive() then
    if self.DCSUnits[DCSUnit:getName()] then
      DCSUnitAlive = true
    end
  end
  self:T( DCSUnitAlive )
  return DCSUnitAlive
end

---
-- @param #DATABASE self
-- @param DCSGroup#Group DCSGroup
-- @return #DATABASE self
function DATABASE:_IsAliveDCSGroup( DCSGroup )
  self:F( DCSGroup )
  local DCSGroupAlive = false
  if DCSGroup and DCSGroup:isExist() then
    if self.DCSGroups[DCSGroup:getName()] then
      DCSGroupAlive = true
    end
  end
  self:T( DCSGroupAlive )
  return DCSGroupAlive
end


--- Traces the current database contents in the log ... (for debug reasons).
-- @param #DATABASE self
-- @return #DATABASE self
function DATABASE:TraceDatabase()
  self:F()
  
  self:T( { "DCSUnits:", self.DCSUnits } )
  self:T( { "DCSUnitsAlive:", self.DCSUnitsAlive } )
end


