class profile::toolforge::k8s::apilb (
        $servers = hiera('profile::toolforge::k8s::api_servers'),
    ) {
    class { 'haproxy':
        template => 'profile/toolforge/k8s/apilb/haproxy.cfg.erb',
    }
}
