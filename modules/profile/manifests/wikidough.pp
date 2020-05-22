class profile::wikidough (
    Hash[String, Dnsdist::Resolver] $recursive_resolvers = lookup(profile::wikidough::recursive_resolvers),
) {

    class { 'dnsdist':
        resolvers => $recursive_resolvers
    }

}
