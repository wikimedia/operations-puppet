# IPMItool mgmt hosts
class role::ipmi::mgmt {

    system::role { 'role::ipmi::mgmt':
        description => 'IPMI Management',
    }

    include ::ipmi::mgmt

}
