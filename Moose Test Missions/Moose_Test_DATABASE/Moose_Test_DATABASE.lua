Include.File( 'Database' )
Include.File( 'Spawn' )

DBBluePlanes = DATABASE:New()
  :FilterCoalitions( "blue" )
  :FilterCategories( "plane" )
  :FilterStart()

DBRedVehicles = DATABASE:New()
  :FilterCoalitions( "red" )
  :FilterCategories( "ground" )
  :FilterStart()

DBShips = DATABASE:New()
  :FilterCategories( "ship" )
  :FilterStart()
  
DBBelgium = DATABASE:New()
  :FilterCategories( "helicopter" )
  :FilterCountries( "BELGIUM" )
  :FilterStart()
  
DBNorthKorea = DATABASE:New()
  :FilterCountries( "NORTH_KOREA" )
  :FilterStart()
  
DBKA50Vinson = DATABASE:New()
  :FilterTypes( { "Ka-50", "VINSON" } )
  :FilterStart()

DBBluePlanes:TraceDatabase()
DBRedVehicles:TraceDatabase()
DBShips:TraceDatabase()
DBBelgium:TraceDatabase()
DBNorthKorea:TraceDatabase()
DBKA50Vinson:TraceDatabase()


SpawnUS_Plane = SPAWN:New( 'Database Spawn Test USA Plane')
GroupUS_Plane = SpawnUS_Plane:Spawn()

SpawnUS_Vehicle = SPAWN:New( 'Database Spawn Test USA Vehicle')
GroupUS_Vehicle = SpawnUS_Vehicle:Spawn()

SpawnUS_Ship = SPAWN:New( 'Database Spawn Test USA Ship')
GroupUS_Ship = SpawnUS_Ship:Spawn()

SpawnRU_Vehicle = SPAWN:New( 'Database Spawn Test RUSSIA Vehicle')
GroupRU_Vehicle = SpawnRU_Vehicle:Spawn()

SpawnRU_Ship = SPAWN:New( 'Database Spawn Test RUSSIA Ship')
GroupRU_Ship = SpawnRU_Ship:Spawn()

SpawnUS_AttackVehicle = SPAWN:New( 'Database Spawn Test USA Attack Vehicle' )
SpawnRU_AttackVehicle = SPAWN:New( 'Database Spawn Test RUSSIA Attack Vehicle' )

for i = 1, 10 do
  GroupRU_AttackVehicle = SpawnRU_AttackVehicle:SpawnInZone( ZONE:New("Spawn Zone RU"), true)
  GroupUS_AttackVehicle = SpawnUS_AttackVehicle:SpawnInZone( ZONE:New("Spawn Zone US"), true)
end


--DBBlue:TraceDatabase()
routines.scheduleFunction( DBBluePlanes.TraceDatabase, { DBBluePlanes }, 1 )
routines.scheduleFunction( DBRedVehicles.TraceDatabase, { DBRedVehicles }, 1 )
routines.scheduleFunction( DBShips.TraceDatabase, { DBShips }, 1 )
routines.scheduleFunction( DBBelgium.TraceDatabase, { DBBelgium }, 1 )
routines.scheduleFunction( DBNorthKorea.TraceDatabase, { DBNorthKorea }, 1 )
routines.scheduleFunction( DBKA50Vinson.TraceDatabase, { DBKA50Vinson }, 1 )

DBRedVehicles
  :ForEachAliveUnit( function( DCSUnit ) 
    DBRedVehicles:T( DCSUnit:getName() )
  end )
