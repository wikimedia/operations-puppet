# sonofgridengine/admin_host.pp

class sonofgridengine::admin_host(
    $config = undef,
) {
    sonofgridengine::resource { "admin-${::fqdn}":
        rname  => $::fqdn,
        dir    => 'adminhosts',
        config => $config,
    }
}
