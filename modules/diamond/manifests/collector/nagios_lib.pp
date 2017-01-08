# support class, to be include'd multiple times
class diamond::collector::nagios_lib {
    diamond::collector { 'Nagios':
        source   => 'puppet:///modules/diamond/collector/nagios.py',
    }

    file { '/etc/diamond/nagios.d':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }
}
