# = Class: prometheus::wmcs_scripts
#
# This class includes Prometheus scripts to be used in WMCS, usually to generate targets
# for Prometheus to pick up.

class prometheus::wmcs_scripts {
    require_package('python3-yaml')
    require_package('python3-keystoneclient')
    require_package('python3-novaclient')

    # output all nova instances for the current labs project as prometheus
    # 'targets'
    file { '/usr/local/bin/prometheus-labs-targets':
        ensure => file,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-labs-targets.py',
    }
}
