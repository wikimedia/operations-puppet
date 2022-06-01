# Setup monitoring for anycast-healthchecker
# Original file from https://github.com/unixsurfer/anycast_healthchecker/blob/master/contrib/nagios/check_anycast_healthchecker.py
class profile::bird::anycast_healthchecker_monitoring{

    ensure_packages('python3-docopt')

    file { '/usr/lib/nagios/plugins/check_anycast_healthchecker.py':
        ensure => absent,
    }

    nrpe::plugin { 'check_anycast_healthchecker':
        source  => 'puppet:///modules/profile/bird/check_anycast_healthchecker.py',
        require => Package['python3-docopt'],
    }

    sudo::user { 'nagios_check_anycast_healthchecker':
        ensure => absent,
    }

    nrpe::monitor_service { 'anycast_healthchecker':
        description  => 'Check if anycast-healthchecker and all configured threads are running',
        nrpe_command => '/usr/local/lib/nagios/plugins/check_anycast_healthchecker',
        sudo_user    => 'bird',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Anycast#Anycast_healthchecker_not_running',
    }
}
