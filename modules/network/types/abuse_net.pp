# SPDX-License-Identifier: Apache-2.0
type Network::Abuse_net = Struct[{
    context  => Array[Network::Context],
    networks => Array[Stdlib::IP::Address],
    comment  => Optional[String[1]],
}]
