# sonofgridengine/admin_host.pp

class sonofgridengine::admin_host(
    $config = undef,
) {
    gridengine::resource { "admin-${::fqdn}":
        rname  => $::fqdn,
        dir    => 'adminhosts',
        config => $config,
    }
}
