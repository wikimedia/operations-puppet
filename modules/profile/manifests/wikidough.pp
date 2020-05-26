class profile::wikidough (
    Hash[String, Dnsdist::Resolver] $recursive_resolvers = lookup(profile::wikidough::recursive_resolvers),
) {

    class { 'dnsdist':
        resolvers => $recursive_resolvers
    }

    acme_chief::cert { 'wikidough':
        puppet_svc => 'dnsdist',
        key_group  => '_dnsdist',
    }

}
