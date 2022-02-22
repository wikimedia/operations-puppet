# == Type: Dnsdist::Resolver
#
# dnsdist's recursive resolver and its configuration. In the current setup,
# there is only a single backend recursor.
#
#  [*name*]
#    [string] name of the backend recursor. required.
#
#  [*ip*]
#    [IP adddress] IP address the recursor listens on. required.
#
#  [*port*]
#    [port] port the recursor listens on. required.

type Dnsdist::Resolver = Struct[{
    name => String,
    ip   => Stdlib::IP::Address::Nosubnet,
    port => Stdlib::Port,
}]
