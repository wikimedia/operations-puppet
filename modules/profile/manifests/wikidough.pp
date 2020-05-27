class profile::wikidough (
    Hash[String, Dnsdist::Resolver] $recursive_resolvers = lookup(profile::wikidough::recursive_resolvers),
) {

    include ::network::constants
    ferm::service { 'wikidough-doh':
        proto  => 'tcp',
        port   => 443,
        srange => '$PRODUCTION_NETWORKS',
    }

    acme_chief::cert { 'wikidough':
        puppet_svc => 'dnsdist',
        key_group  => '_dnsdist',
    }

    class { 'dnsdist':
        resolvers    => $recursive_resolvers,
        cert_chain   => '/etc/acmecerts/wikidough/live/ec-prime256v1.chained.crt',
        cert_privkey => '/etc/acmecerts/wikidough/live/ec-prime256v1.key',
    }

}
