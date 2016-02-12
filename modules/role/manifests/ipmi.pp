# IPMItool mgmt hosts
class role::ipmi {

    system::role { 'role::ipmi':
        description => 'IPMI Management'
    }

    include ::ipmi

}
