# SPDX-License-Identifier: Apache-2.0
type Envoyproxy::Ratelimitconfig = Struct[{
    'address'           => Stdlib::Host,
    'port'              => Stdlib::Port,
    'domain'            => Optional[String],
    'connect_timeout'   => Optional[Float],
}]
