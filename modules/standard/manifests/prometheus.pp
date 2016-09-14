# standard class for prometheus
class standard::prometheus {
    if $::site == 'codfw' {
        role(prometheus::node_exporter)
    }
}
