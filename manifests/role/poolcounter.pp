class role::poolcounter {
	include ::poolcounter
	system_role { 'role::poolcounter': description => 'PoolCounter server' }
}

