# = Class: prometheus::wmcs_scripts
#
# This class includes Prometheus scripts to be used in WMCS, usually to generate targets
# for Prometheus to pick up.

class prometheus::wmcs_scripts (
    Wmflib::Ensure $ensure = present,
) {
    # output all nova instances for the current labs project as prometheus
    # 'targets'
    file { '/usr/local/bin/prometheus-labs-targets':
        ensure => stdlib::ensure($ensure, 'file'),
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-labs-targets.py',
    }

    file { '/usr/local/bin/prometheus-labs-targets.sh':
        ensure => stdlib::ensure($ensure, 'file'),
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-labs-targets-timer',
    }
}
