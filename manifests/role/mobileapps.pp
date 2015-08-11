
# Role class for mobileapps
class role::mobileapps {

    system::role { 'role::mobileapps':
        description => 'Yes',
    }

    include ::mobileapps
}

