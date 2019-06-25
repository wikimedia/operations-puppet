function profile::lvs_pool_nodes(Array[String ]$pools, Hash $lvs_services) >> Array[String] {
    $module_path = get_module_path('profile')
    $site_nodes = loadyaml("${module_path}/../../conftool-data/node/${::site}.yaml")[$::site]

    # Now build a non-flattened list of all servers in the site from all pools
    # configured here.
    $all_nodes = $pools.map |$pool| {
        if $pool in $lvs_services {
            keys($site_nodes[$lvs_services[$pool]['conftool']['cluster']])
        }
        else {
            []
        }
    }
    # Flatten the list, remove duplicates, return it.
    unique(flatten($all_nodes))
}
