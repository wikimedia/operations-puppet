# == Class: ocg_collection::service
#
# Upstart service definition for a OCG Collection render node.
#

class ocg_collection::service {
    require ocg_collection

    service { 'ocg-collection':
        provider   => upstart,
        ensure     => running,
        hasstatus  => false,
        hasrestart => false,
        enable     => true,
        require    => File['/etc/init/ocg-collection.conf'],
    }

    monitor_service { 'ocg-collection':
        description   => 'Offline Content Generation - Collection',
        check_command => 'check_http_on_port!17080',
    }
}
