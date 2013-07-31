# Class: nrpe::service
#
# Ensures service is running
# 
# Parameters:
#
# Actions:
#   Ensure service is running
#
# Requires:
#   Class[nrpe::packages]
#
# Sample Usage:
#   include nrpe::service

class nrpe::service {
    Class[nrpe::packages] -> Class[nrpe::service]

    # TODO: Clear the pattern, hasrestart, restart parameters because they are
    # ugly
    service { 'nagios-nrpe-server':
        ensure => running,
        pattern => '/usr/sbin/nrpe',
        hasrestart => true,
        restart => 'killall nrpe; sleep 2; /etc/init.d/nagios-nrpe-server start',
        require => Package['nagios-nrpe-server'],
        subscribe => File['/etc/nagios/nrpe_local.cfg'],
    }
}
