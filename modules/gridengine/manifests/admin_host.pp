# gridengine/admin_host.pp

class gridengine::admin_host(
    $config = undef,
)
{
    gridengine::resource { "admin-${::fqdn}":
        rname  => $::fqdn,
        dir    => 'adminhosts',
        config => $config,
    }

}

