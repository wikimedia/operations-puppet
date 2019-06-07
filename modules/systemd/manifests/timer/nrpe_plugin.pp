# == Class systemd::timer::nrpe_plugin
#
# Nagios NRPE pluing script to check the status of systemd unit.
class systemd::timer::nrpe_plugin {
    file { '/usr/local/lib/nagios/plugins/check_systemd_unit_status':
        ensure => present,
        source => 'puppet:///modules/systemd/check_systemd_unit_status',
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }
}
