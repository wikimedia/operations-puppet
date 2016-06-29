# = Class: prometheus::scripts
#
# This class includes accessory prometheus scripts, usually to generate targets
# for prometheus to pick up.

class prometheus::scripts {
    require_package('python3-yaml')

    # output all nova instances for the current labs project as prometheus
    # 'targets' for 'file service discovery' to pick up
    file { '/usr/local/bin/prometheus-labs-targets':
        ensure => file,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-labs-targets',
    }

    require_package('php5-cli')
    # output prometheus 'file service discovery' configuration based on
    # mediawiki MySQL configuration
    file { '/usr/local/bin/prometheus-mysql-mw-targets':
        ensure => file,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-mysql-mw-targets',
    }
}
