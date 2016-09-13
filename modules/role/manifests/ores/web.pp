class role::ores::web {
    # LVS pooling/depoling scripts
    include ::lvs::configuration
    conftool::scripts::service { 'ores':
        lvs_services_config => $::lvs::configuration::lvs_services,
        lvs_class_hosts     => $::lvs::configuration::lvs_class_hosts,
    }

    include ::ores::web
}
