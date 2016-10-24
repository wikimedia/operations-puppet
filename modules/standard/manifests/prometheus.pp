# standard class for prometheus
class standard::prometheus {
    if $::site == 'codfw' or $::site == 'eqiad' {
        include ::role::prometheus::node_exporter
    }
}
