# standard class for prometheus
class standard::prometheus {
    include ::role::prometheus::node_exporter
}
