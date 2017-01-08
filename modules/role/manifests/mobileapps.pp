# Role class for mobileapps
class role::mobileapps {

    system::role { 'role::mobileapps':
        description => 'A service for use by mobile apps. Provides DOM manipulation, aggregation, JSON flattening',
    }

    include ::mobileapps
}
