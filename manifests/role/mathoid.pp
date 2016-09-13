# vim: set ts=4 et sw=4:

class role::mathoid{
    system::role { 'role::mathoid':
        description => 'mathoid server'
    }

    # LVS pooling/depoling scripts
    include ::lvs::configuration
    conftool::scripts::service { 'mathoid':
        lvs_services_config => $::lvs::configuration::lvs_services,
        lvs_class_hosts     => $::lvs::configuration::lvs_class_hosts,
    }

    include ::mathoid
}
