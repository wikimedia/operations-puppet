# Establishes the Confd setup for relevant lvs services
#
# === Parameters
#
# [*lvs_services*]
#   lvs_services hash from lvs/configuration.pp
#
# [*lvs_class_hosts*]
#   lvs_class_hosts hash from lvs/configuration.pp
#
define pybal::pool(
    $lvs_services={},
    $lvs_class_hosts={},
) {

    $service_config = $lvs_services[$name]

    # This shadows pybal template for selection
    if member($service_config['sites'], $::site) {
        if member($lvs_class_hosts[$service_config['class']], $::hostname) {

            $cluster = $service_config['conftool']['cluster']
            $service = $service_config['conftool']['service']

            pybal::conf_file { $::site:
                pool_name => $name,
                cluster   => $cluster,
                service   => $service,
            }
        }
    }
}
