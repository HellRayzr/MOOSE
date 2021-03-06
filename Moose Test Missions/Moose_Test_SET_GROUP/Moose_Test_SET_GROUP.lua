
Include.File( 'Set' )
Include.File( 'Spawn' )

SetBluePlanesGroup = SET_GROUP:New()
  :FilterCoalitions( "blue" )
  :FilterCategories( "plane" )
  :FilterStart()
  
SetNorthKoreaGroup = SET_GROUP:New()
  :FilterCountries( "RUSSIA" )
  :FilterStart()

SetSAMGroup = SET_GROUP:New()
  :FilterPrefixes( "SAM" )
  :FilterStart()

SpawnUS_Plane = SPAWN:New( 'Spawn Test USA Plane')
GroupUS_Plane = SpawnUS_Plane:Spawn()

SpawnUS_Vehicle = SPAWN:New( 'Spawn Test USA Vehicle')
GroupUS_Vehicle = SpawnUS_Vehicle:Spawn()

SpawnUS_Ship = SPAWN:New( 'Spawn Test USA Ship')
GroupUS_Ship = SpawnUS_Ship:Spawn()

SpawnRU_Vehicle = SPAWN:New( 'Spawn Test RUSSIA Vehicle')
GroupRU_Vehicle = SpawnRU_Vehicle:Spawn()

SpawnRU_Ship = SPAWN:New( 'Spawn Test RUSSIA Ship')
GroupRU_Ship = SpawnRU_Ship:Spawn()

SpawnM2A2_AttackVehicle = SPAWN:New( 'Spawn Test M2A2 Attack Vehicle' )
SpawnSAM_AttackVehicle = SPAWN:New( 'Spawn Test SAM Attack Vehicle' )

for i = 1, 30 do
  GroupM2A2_AttackVehicle = SpawnM2A2_AttackVehicle:SpawnInZone( ZONE:New("Spawn Zone"), true)
  GroupSAM_AttackVehicle = SpawnSAM_AttackVehicle:SpawnInZone( ZONE:New("Spawn Zone"), true)
end

SetVehicleCompletely = SET_GROUP:New()
  :FilterPrefixes( "Spawn Vehicle Zone Completely" )
  :FilterStart() 

SetVehiclePartly = SET_GROUP:New()
  :FilterPrefixes( "Spawn Vehicle Zone Partly" )
  :FilterStart() 

SetVehicleNot = SET_GROUP:New()
  :FilterPrefixes( "Spawn Vehicle Zone Not" )
  :FilterStart() 

Spawn_Vehicle_Zone_Completely = SPAWN:New( 'Spawn Vehicle Zone Completely' )
Spawn_Vehicle_Zone_Partly     = SPAWN:New( 'Spawn Vehicle Zone Partly' )
Spawn_Vehicle_Zone_Not        = SPAWN:New( 'Spawn Vehicle Zone Not' )
for i = 1, 30 do
  Spawn_Vehicle_Zone_Completely:SpawnInZone( ZONE:New("Spawn Zone Completely"), true)
  Spawn_Vehicle_Zone_Partly:SpawnInZone( ZONE:New("Spawn Zone Partly"), true)
  Spawn_Vehicle_Zone_Not:SpawnInZone( ZONE:New("Spawn Zone Not"), true)
end

--DBBlue:TraceDatabase()
--SCHEDULER:New( DBBluePlanes, DBBluePlanes.Flush, {  }, 1 )
--SCHEDULER:New( DBRedVehicles, DBRedVehicles.Flush, {  }, 1 )
--SCHEDULER:New( DBShips, DBShips.Flush, {  }, 1 )
--SCHEDULER:New( DBBelgium, DBBelgium.Flush, {  }, 1 )
--SCHEDULER:New( DBNorthKorea, DBNorthKorea.Flush, {  }, 1 )
--SCHEDULER:New( DBKA50Vinson, DBKA50Vinson.Flush, {  }, 1 )
--
--SCHEDULER:New( DBBluePlanesGroup, DBBluePlanesGroup.Flush, { }, 1 )
--SCHEDULER:New( DBNorthKoreaGroup, DBNorthKoreaGroup.Flush, { }, 1 )

SetBluePlanesGroup:ForEachGroup( 
  --- @param Group#GROUP MooseGroup
  function( MooseGroup ) 
    for UnitId, UnitData in pairs( MooseGroup:GetUnits() ) do
      local UnitAction = UnitData -- Unit#UNIT
      UnitAction:SmokeBlue()
    end
  end 
)

SetNorthKoreaGroup:ForEachGroup( 
  --- @param Group#GROUP MooseGroup
  function( MooseGroup ) 
    for UnitId, UnitData in pairs( MooseGroup:GetUnits() ) do
      local UnitAction = UnitData -- Unit#UNIT
      UnitAction:SmokeRed()
    end
  end 
)

SetSAMGroup:ForEachGroup( 
  --- @param Group#GROUP MooseGroup
  function( MooseGroup ) 
    for UnitId, UnitData in pairs( MooseGroup:GetUnits() ) do
      local UnitAction = UnitData -- Unit#UNIT
      UnitAction:SmokeOrange()
    end
  end 
)

GroupZoneCompletely = GROUP:FindByName( "Zone Completely" )
GroupZonePartly = GROUP:FindByName( "Zone Partly" )
GroupZoneNot = GROUP:FindByName( "Zone Not" )

ZoneCompletely = ZONE_POLYGON:New( "Zone Completely", GroupZoneCompletely ):SmokeZone( POINT_VEC3.SmokeColor.White )
ZonePartly = ZONE_POLYGON:New( "Zone Partly", GroupZonePartly ):SmokeZone( POINT_VEC3.SmokeColor.White )
ZoneNot = ZONE_POLYGON:New( "Zone Not", GroupZoneNot ):SmokeZone( POINT_VEC3.SmokeColor.White )

SetVehicleCompletely:ForEachGroupCompletelyInZone( ZoneCompletely,
  --- @param Group#GROUP MooseGroup
  function( MooseGroup ) 
    for UnitId, UnitData in pairs( MooseGroup:GetUnits() ) do
      local UnitAction = UnitData -- Unit#UNIT
      UnitAction:SmokeBlue()
    end
  end 
)
  
SetVehiclePartly:ForEachGroupPartlyInZone( ZonePartly,
  --- @param Group#GROUP MooseGroup
  function( MooseGroup ) 
    for UnitId, UnitData in pairs( MooseGroup:GetUnits() ) do
      local UnitAction = UnitData -- Unit#UNIT
      UnitAction:SmokeBlue()
    end
  end 
)
    
SetVehicleNot:ForEachGroupNotInZone( ZoneNot,
  --- @param Group#GROUP MooseGroup
  function( MooseGroup ) 
    for UnitId, UnitData in pairs( MooseGroup:GetUnits() ) do
      local UnitAction = UnitData -- Unit#UNIT
      UnitAction:SmokeBlue()
    end
  end 
)
  