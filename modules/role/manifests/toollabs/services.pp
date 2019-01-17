# filtertags: labs-project-tools
class role::toollabs::services(
    $active_host = 'tools-services-01.tools.eqiad.wmflabs',
) {
    system::role { 'toollabs::services':
        description => 'Tool Labs manifest based services',
    }

    include ::role::aptly::server

    class { '::toollabs::services': }

    class { '::toollabs::updatetools':
        active => ($::fqdn == $active_host),
    }
}
