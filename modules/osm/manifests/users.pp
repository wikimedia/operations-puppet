class osm::users {
    group { 'osm':
        ensure => present,
    }

    user { 'osmupdater':
        ensure     => present,
        group      => 'osm',
        home       => '/nonexistent',
        managehome => false,
        require    => Group['osm'],
    }
}
