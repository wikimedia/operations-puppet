class osm::users {
    group { 'osm':
        ensure => present,
        system => true,
    }

    user { 'osmupdater':
        ensure  => present,
        system  => true,
        groups  => 'osm',
        home    => '/nonexistent',
        require => Group['osm'],
    }
}
