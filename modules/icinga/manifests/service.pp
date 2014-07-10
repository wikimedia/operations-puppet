
class icinga::service {

    require icinga::apache

    service { 'icinga':
        ensure    => running,
        hasstatus => false,
        restart   => '/etc/init.d/icinga reload',
        subscribe => [
            File[$icinga::monitor::configuration::variables::puppet_files],
            File[$icinga::monitor::configuration::variables::static_files],
            File['/etc/icinga/puppet_services.cfg'],
            File['/etc/icinga/puppet_hostextinfo.cfg'],
            File['/etc/icinga/puppet_hosts.cfg'],
        ],
    }
}

