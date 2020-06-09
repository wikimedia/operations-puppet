# == Type: Dnsdist::Resolver
#
# dnsdist's recursive resolvers and their configuration.

type Dnsdist::Resolver = Struct[{
    name => String,
    host => Stdlib::Host,
    port => Stdlib::Port,
}]
