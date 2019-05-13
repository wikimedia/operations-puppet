# === Class nrpe::systemd_scripts
#
# Class that collects all systemd-related monitoring scripts.
#

class nrpe::systemd_scripts {

    # These scripts allows monitoring of systemd services
    file { '/usr/local/bin/nrpe_check_systemd_unit_state':
        ensure => present,
        source => 'puppet:///modules/nrpe/plugins/check_systemd_unit_state.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
}
