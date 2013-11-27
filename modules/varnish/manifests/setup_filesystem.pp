define varnish::setup_filesystem() {
    file { "/srv/${title}":
        ensure => directory,
        owner  => root,
        group  => root,
    }

    $mount_options = $::realm ? {
        'production' => 'noatime,nodiratime,nobarrier,logbufs=8',
        'labs'       => 'noatime,nodiratime,nobarrier,comment=cloudconfig',
    }

    mount { "/srv/${title}":
        ensure  => mounted,
        require => File["/srv/${title}"],
        device  => "/dev/${title}",
        fstype  => 'auto',
        options => $mount_options,
    }
}
