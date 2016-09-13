# Role class for mobileapps
class role::mobileapps {

    system::role { 'role::mobileapps':
        description => 'A service for use by mobile apps. Provides DOM manipulation, aggregation, JSON flattening'
    }

    include ::lvs::configuration
    conftool::scripts::service { 'mobileapps':
        lvs_services_config => $::lvs::configuration::lvs_services,
        lvs_class_hosts     => $::lvs::configuration::lvs_class_hosts,
    }

    include ::mobileapps
}
