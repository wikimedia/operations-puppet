# Type for dnsdist's recursive resolver.
type Dnsdist::Resolver = Struct[{
    host => Stdlib::Host,
    port => Stdlib::Port,
}]
