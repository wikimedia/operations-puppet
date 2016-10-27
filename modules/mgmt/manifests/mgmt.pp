#sshpass needed to remote to hosts and run 
#racadm commands on Dell servers

class mgmt {

    package { 'sshpass':
        ensure => present,
    }

}
