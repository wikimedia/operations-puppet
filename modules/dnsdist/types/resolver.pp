# == Type: Dnsdist::Resolver
#
# dnsdist's recursive resolvers and their configuration.

type Dnsdist::Resolver = Struct[{
    host => Stdlib::Host,
    port => Stdlib::Port,
}]
