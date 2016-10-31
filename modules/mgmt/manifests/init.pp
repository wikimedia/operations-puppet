# manage management consoles
# like setting passwords on 'mgmt'
class mgmt {

    # sshpass is needed to login on DRAC consoles
    package { 'sshpass':
        ensure => present,
    }
    file { '/usr/local/bin/changepw':
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/mgmt/changepw',

    }
}
