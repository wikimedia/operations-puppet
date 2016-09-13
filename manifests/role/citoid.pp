# vim: set ts=4 et sw=4:
class role::citoid {

    system::role { 'role::citoid': }

    # LVS pooling/depoling scripts
    include ::lvs::configuration
    conftool::scripts::service { 'citoid':
        lvs_services_config => $::lvs::configuration::lvs_services,
        lvs_class_hosts     => $::lvs::configuration::lvs_class_hosts,
    }

    include ::citoid
}
