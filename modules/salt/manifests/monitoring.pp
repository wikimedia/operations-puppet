# Let Icinga check for unaccepted salt keys (T144801)
class salt::monitoring() {

    $check_unaccepted_keys = '/usr/local/lib/nagios/plugins/check_unaccepted_keys'

    file { $check_unaccepted_keys:
        ensure => present,
        mode   => '0550',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/salt/check_unaccepted_keys',
    }

    sudo::user { 'nagios_unaccepted_keys':
        user       => 'nagios',
        privileges => ["ALL = NOPASSWD: ${check_unaccepted_keys}"],
    }

    nrpe::monitor_service { 'salt_unaccepted_keys':
        description  => 'unaccepted salt keys',
        nrpe_command => $check_unaccepted_keys,
    }

}
