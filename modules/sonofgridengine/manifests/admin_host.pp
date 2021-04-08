# sonofgridengine/admin_host.pp

class sonofgridengine::admin_host(
    $config = undef,
) {
    sonofgridengine::resource { "admin-${facts['hostname']}.${::labsproject}.eqiad1.wikimedia.cloud":
        rname  => "${facts['hostname']}.${::labsproject}.eqiad1.wikimedia.cloud",
        dir    => 'adminhosts',
        config => $config,
    }
}
