class osm::users {
    group { 'osm':
        ensure => present,
    }

    user { 'osmupdater':
        ensure => present,
        group => 'osm',
        home => '/home/osmupdater',
        managehome => true,
        require => Group['osm'],
    }

    file { '/home/osmupdater/.pgpass':
        ensure => present,
        owner => 'osmupdater',
        group => 'osm',
        content => inline_template('localhost:*:osmupdater:<%=  %>'),
    }
}
