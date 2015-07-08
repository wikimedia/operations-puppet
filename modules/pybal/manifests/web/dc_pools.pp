define pybal::web::dc_pools() {
    $services = hiera('lvs::configuration::lvs_services')
    $resource_names = prefix(keys($services), "${name}/")

    pybal::web::service{ $resource_names:
        config => $services,
    }
}
