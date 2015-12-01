# = Class: role::wdqs
#
# This class sets up Wikidata Query Service
#
class role::wdqs  {
    include standard
    include base::firewall

    $nagios_contact_group = 'admins,wdqs-admins'

    if $::realm == 'labs' {
        include role::labs::lvm::srv
    }

    system::role { 'role::wdqs':
        ensure      => 'present',
        description => 'Wikidata Query Service',
    }


    Class['::wdqs'] -> Class['::wdqs::gui']

    # Install services - both blazegraph and the updater
    include ::wdqs

    # Service Web proxy
    include ::wdqs::gui

    ferm::service { 'wdqs_http':
        proto => 'tcp',
        port  => '80',
    }

    ferm::service { 'wdqs_https':
        proto => 'tcp',
        port  => '443',
    }

    # Monitor Blazegraph
    include ::wdqs::monitor::blazegraph

    # Monitor Updater
    include ::wdqs::monitor::updater

    # Service monitoring
    include ::wdqs::monitor::services
}
