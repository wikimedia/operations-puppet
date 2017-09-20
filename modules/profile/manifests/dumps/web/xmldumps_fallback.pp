class profile::dumps::web::xmldumps_fallback {
    class {'::dumps::web::xmldumps':
        do_acme => hiera('do_acme'),
    }
}
