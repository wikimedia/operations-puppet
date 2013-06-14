define varnish::setup_filesystem() {
    file { "/srv/${title}":
        owner => root,
        group => root,
        ensure => directory
    }

    mount { "/srv/${title}":
        require => File["/srv/${title}"],
        device => "/dev/${title}",
        fstype => "auto",
        options => $::realm ? {
            'production' => "noatime,nodiratime,nobarrier,logbufs=8",
            'labs' => "noatime,nodiratime,nobarrier,comment=cloudconfig"
        },
        ensure => mounted
    }
}
