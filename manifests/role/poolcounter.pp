class role::poolcounter {
    include ::poolcounter
    system::role { 'role::poolcounter': description => 'PoolCounter server' }
}

