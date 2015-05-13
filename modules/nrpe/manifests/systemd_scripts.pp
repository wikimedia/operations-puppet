# === Class nrpe::systemd_scripts
#
# Class that collects all systemd-related monitoring scripts.
#

class nrpe::systemd_scripts {
    require_package 'libnagios-plugin-perl'

    # This script allows monitoring of systemd services
    file { '/usr/local/bin/nrpe_check_systemd_state':
        ensure => present,
        source => 'puppet:///modules/nrpe/check_systemd_state',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
}
