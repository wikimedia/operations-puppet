class osm::users {
    group { 'osm':
        ensure => present,
    }

    user { 'osmupdater':
        ensure  => present,
        groups  => 'osm',
        home    => '/nonexistent',
        require => Group['osm'],
    }
}
