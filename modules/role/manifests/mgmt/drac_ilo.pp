# manage management interfaces
# like setting passwords on DRACs/iLOs
class role::mgmt::drac_ilo {

    system::role { 'role::mgmt::drac_ilo':
        description => 'Manage management interfaces',
    }

    include ::mgmt
}

