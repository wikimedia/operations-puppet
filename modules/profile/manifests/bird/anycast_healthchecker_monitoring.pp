# Setup monitoring for anycast-healthchecker
# Original file from https://github.com/unixsurfer/anycast_healthchecker/blob/master/contrib/nagios/check_anycast_healthchecker.py
class profile::bird::anycast_healthchecker_monitoring{

  file { 'check_anycast_healthchecker':
      path   => '/usr/lib/nagios/plugins/check_anycast_healthchecker.py',
      mode   => '0555',
      owner  => 'bird',
      group  => 'bird',
      source => 'puppet:///modules/profile/bird/check_anycast_healthchecker.py',
  }
    nrpe::monitor_service { 'anycast_healthchecker':
        description  => 'Check if anycast-healthchecker and all configured threads are running',
        nrpe_command => 'sudo -u bird /usr/bin/python3 /usr/lib/nagios/plugins/check_anycast_healthchecker.py',
        require      => File['check_anycast_healthchecker'],
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Anycast_recursive_DNS#Anycast_healthchecker_not_running',
    }
}
