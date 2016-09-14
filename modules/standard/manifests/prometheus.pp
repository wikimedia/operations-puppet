# standard class for prometheus
class standard::prometheus {
    if $::site == 'codfw' {
        include ::role::prometheus::node_exporter
    }
}
