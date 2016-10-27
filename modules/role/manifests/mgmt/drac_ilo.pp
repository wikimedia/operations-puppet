#sshpass needed to remote to hosts and run 
#racadm and ILO commands on nodes

class role::mgmt::drac_ilo {

    system::role { 'role::mgmt::drac_ilo':
        description => 'SSHPASS'
    }

    include ::mgmt
}

