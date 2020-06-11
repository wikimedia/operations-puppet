class profile::toolforge::k8s::haproxy (
    Array[Stdlib::Fqdn] $ingress_nodes = lookup('profile::toolforge::k8s::ingress_nodes',  {default_value => ['localhost']}),
    Stdlib::Port        $ingress_port  = lookup('profile::toolforge::k8s::ingress_port',   {default_value => 30000}),
    Array[Stdlib::Fqdn] $control_nodes = lookup('profile::toolforge::k8s::control_nodes',  {default_value => ['localhost']}),
    Stdlib::Port        $api_port      = lookup('profile::toolforge::k8s::apiserver_port', {default_value => 6443}),
) {
    class { '::profile::wmcs::kubeadm::haproxy':
        ingress_nodes        => $ingress_nodes,
        ingress_backend_port => $ingress_port,
        ingress_bind_port    => $ingress_port,
        control_nodes        => $control_nodes,
        api_port             => $api_port,
    }
    contain '::profile::wmcs::kubeadm::haproxy'
}
