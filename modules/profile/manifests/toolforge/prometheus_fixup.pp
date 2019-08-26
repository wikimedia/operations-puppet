# To be used on deprecated roles that are in the process of being refactored.
class profile::toolforge::prometheus_fixup (
    Array[Stdlib::Fqdn] $prometheus_nodes = lookup('prometheus_nodes')
) {
    $prometheus_hosts = join($prometheus_nodes, ' ')
    # So prometheus blackbox exporter can monitor ssh
    ferm::service { 'ssh-prometheus':
        proto  => 'tcp',
        port   => '22',
        srange => "@resolve((${prometheus_hosts}))",
    }
}
