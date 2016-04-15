class mirrors::serve {
    # HTTP
    include ::nginx

    nginx::site { 'mirrors':
        source => 'puppet:///modules/mirrors/mirrors.wikimedia.org.conf',
    }

    nginx::site { 'ubuntu':
        source => 'puppet:///modules/mirrors/ubuntu.wikimedia.org.conf',
    }

    file { '/srv/mirrors/index.html':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/mirrors/index.html',
    }
}
