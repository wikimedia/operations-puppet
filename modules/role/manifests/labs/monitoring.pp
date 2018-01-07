class role::labs::monitoring {
    system::role { 'labs::monitoring': }
    include ::role::labs::graphite
    include ::role::labs::prometheus
    include ::role::grafana::labs
    include standard
    include ::base::firewall
}
