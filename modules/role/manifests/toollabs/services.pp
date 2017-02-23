# filtertags: labs-project-tools
class role::toollabs::services(
    $active_host = 'tools-services-01.tools.eqiad.wmflabs',
) {
    system::role { 'role::toollabs::services':
        description => 'Tool Labs manifest based services',
    }

    include ::role::aptly::server

    class { '::toollabs::services':
        active => ($::fqdn == $active_host),
    }

    class { '::toollabs::bigbrother':
        active => ($::fqdn == $active_host),
    }

    class { '::toollabs::updatetools':
        active => ($::fqdn == $active_host),
    }

    class { '::toollabs::admin_web_updater':
        active => ($::fqdn == $active_host),
    }
}
