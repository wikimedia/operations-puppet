# == Define: diamond::collector::nginx
#
# Configures a minimal puppet agent collector
# that collects just time since last puppet run
# and total time it took for puppet to run
#
define diamond::collector::minimalpuppetagent {
    package { 'python-yaml':
        ensure => present,
    }

    diamond::collector { 'MinimalPuppetAgent':
        source  => 'puppet:///modules/diamond/collector/minimalpuppetagent.py',
        require => Package['python-yaml'],
    }
}
