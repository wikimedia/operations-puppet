class profile::dumps::web::xmldumps_active {
    class {'::dumps::web::xmldumps_active':
        $do_acme = hiera('do_acme')
    }
}
