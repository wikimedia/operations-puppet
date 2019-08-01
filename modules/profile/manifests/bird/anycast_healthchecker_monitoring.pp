# Setup monitoring for anycast-healthchecker
# Original file from https://github.com/unixsurfer/anycast_healthchecker/blob/master/contrib/nagios/check_anycast_healthchecker.py
class profile::bird::anycast_healthchecker_monitoring{

    require_package('python3-docopt')

    file { 'check_anycast_healthchecker':
        path    => '/usr/lib/nagios/plugins/check_anycast_healthchecker.py',
        mode    => '0555',
        owner   => 'bird',
        group   => 'bird',
        source  => 'puppet:///modules/profile/bird/check_anycast_healthchecker.py',
        require => Package['python3-docopt'],
    }

    sudo::user { 'nagios_check_anycast_healthchecker':
        user       => 'nagios',
        privileges => [ 'ALL = (bird) NOPASSWD: /usr/lib/nagios/plugins/check_anycast_healthchecker.py' ],
        require    => File['check_anycast_healthchecker'],
    }

    nrpe::monitor_service { 'anycast_healthchecker':
        description  => 'Check if anycast-healthchecker and all configured threads are running',
        nrpe_command => '/usr/bin/sudo -u bird /usr/lib/nagios/plugins/check_anycast_healthchecker.py',
        require      => Sudo::User['nagios_check_anycast_healthchecker'],
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Anycast#Anycast_healthchecker_not_running',
    }
}
