# manage management consoles
# like setting passwords on 'mgmt'
class mgmt {

    # sshpass is needed to login on DRAC consoles
    package { 'sshpass':
        ensure => present,
    }

}
