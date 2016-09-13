# vim: set ts=4 et sw=4:
class role::graphoid {

    system::role { 'role::graphoid':
        description => 'node.js service converting graph definitions into PNG'
    }

    # LVS pooling/depoling scripts
    include ::lvs::configuration
    conftool::scripts::service { 'graphoid':
        lvs_services_config => $::lvs::configuration::lvs_services,
        lvs_class_hosts     => $::lvs::configuration::lvs_class_hosts,
    }

    include ::graphoid
}
