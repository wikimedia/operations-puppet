# manage management consoles
# like setting passwords on 'mgmt'
class mgmt {

    # sshpass is needed to login on DRAC consoles
    package { 'sshpass':
        ensure => present,
    }

    # script to change passwords on a list of IPs
    file { '/usr/local/bin/changepw':
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/mgmt/changepw',

    }

    # script to get a list of all the (usable) mgmt IPs
    file { '/usr/local/bin/getmgmtips':
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/mgmt/getmgmtips',

    }
}
