class role::labs::tools::services(
    $active_host = 'tools-services-01.eqiad.wmflabs',
) {
    system::role { 'role::labs::tools::services':
        description => 'Tool Labs manifest based services',
    }

    include role::aptly
    # Backup packages!
    # FIXME: Find out if we deserve better than this
    file { '/data/project/.system/aptly':
        ensure => directory,
        owner  => 'root',
        group  => "${::labsproject}.admin",
        mode   => '0770',
    }

    file { "/data/project/.system/aptly/${::fqdn}":
        ensure    => directory,
        source    => '/srv/packages',
        owner     => 'root',
        group     => "${::labsproject}.admin",
        mode      => '0440',
        recurse   => true,
        show_diff => false,
    }

    class { 'toollabs::services':
        active => ($::fqdn == $active_host),
    }

    class { 'toollabs::bigbrother':
        active => ($::fqdn == $active_host),
    }

    class { 'toollabs::updatetools':
        active => ($::fqdn == $active_host),
    }

    class { 'toollabs::toolwatcher':
        active => ($::fqdn == $active_host)
    }

    class { 'toollabs::admin_web_updater':
        active => ($::fqdn == $active_host)
    }
}
