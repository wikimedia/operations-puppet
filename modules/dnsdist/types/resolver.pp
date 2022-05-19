# SPDX-License-Identifier: Apache-2.0
# @summary dnsdist's recursive resolver and its configuration
#
# @param name
#   name of the backend recursor. required.
#
# @param ip
#   IP address the recursor listens on. required.
#
# @param port
#   port the recursor listens on. required.

type Dnsdist::Resolver = Struct[{
    name => String,
    ip   => Stdlib::IP::Address::Nosubnet,
    port => Stdlib::Port,
}]
