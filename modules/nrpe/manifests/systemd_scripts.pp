# === Class nrpe::systemd_scripts
#
# Class that collects all systemd-related monitoring scripts.
#

class nrpe::systemd_scripts {

    require_package('python3')

    # These scripts allows monitoring of systemd services
    file { '/usr/local/bin/nrpe_check_systemd_unit_state':
        ensure => present,
        source => 'puppet:///modules/nrpe/plugins/check_systemd_unit_state',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
    file { '/usr/local/lib/nagios/plugins/check_systemd_state':
        ensure => present,
        source => 'puppet:///modules/nrpe/plugins/check_systemd_state.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
}
