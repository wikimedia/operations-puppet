
# Role class for mobileapps
class role::mobileapps {

    system::role { 'role::mobileapps':
        description => 'Mashup service used by the mobile apps',
    }

    include ::mobileapps
}

