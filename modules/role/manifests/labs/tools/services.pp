class role::labs::tools::services(
    $active_host = 'tools-services-01.eqiad.wmflabs',
) {
    system::role { 'role::labs::tools::services':
        description => 'Tool Labs manifest based services',
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
