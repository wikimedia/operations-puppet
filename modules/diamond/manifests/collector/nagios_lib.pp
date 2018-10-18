# support class, to be include'd multiple times
class diamond::collector::nagios_lib {
    diamond::collector { 'Nagios':
        ensure => 'absent',
        source => 'puppet:///modules/diamond/collector/nagios.py',
    }

    file { '/etc/diamond/nagios.d':
        ensure => 'absent',
        force  => true,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }
}
