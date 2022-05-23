# === Class nrpe::systemd_scripts
#
# Class that collects all systemd-related monitoring scripts.
#

class nrpe::systemd_scripts {
    file { '/usr/local/bin/nrpe_check_systemd_unit_state':
        ensure => absent,
    }

    nrpe::plugin { 'check_systemd_unit_state':
        source => 'puppet:///modules/nrpe/plugins/check_systemd_unit_state.py',
    }
}
