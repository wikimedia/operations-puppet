
class icinga::service {

    require icinga::apache

    service { 'icinga':
        ensure    => running,
        hasstatus => false,
        restart   => '/etc/init.d/icinga reload',
        subscribe => [
            File[$icinga::config_vars::puppet_files],
            File[$icinga::config_vars::static_files],
            File['/etc/icinga/puppet_services.cfg'],
            File['/etc/icinga/puppet_hostextinfo.cfg'],
            File['/etc/icinga/puppet_hosts.cfg'],
        ],
    }
}

