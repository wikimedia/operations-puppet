# == Type: Dnsdist::Resolver
#
# dnsdist's recursive resolver and its configuration. In the current setup,
# there is only a single backend recursor.

type Dnsdist::Resolver = Struct[{
    name => String,
    host => Stdlib::Host,
    port => Stdlib::Port,
}]
