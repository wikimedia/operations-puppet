class role::ganglia::config {
    # TODO: hiera this
    $rra_sizes = '"RRA:AVERAGE:0.5:1:360" "RRA:AVERAGE:0.5:24:245" "RRA:AVERAGE:0.5:168:241" "RRA:AVERAGE:0.5:672:241" "RRA:AVERAGE:0.5:5760:371"'
    $data_sources = ganglia_aggregator_config()
}

