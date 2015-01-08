class mirrors::serve {
    # HTTP
    include ::nginx

    nginx::site { 'mirrors':
        source => 'puppet:///files/mirrors/nginx.conf',
    }

    file { '/srv/mirrors/index.html':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///files/mirrors/index.html',
    }
}
