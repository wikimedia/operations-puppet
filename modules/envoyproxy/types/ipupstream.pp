# SPDX-License-Identifier: Apache-2.0
type Envoyproxy::Ipupstream = Struct[{
    'port' => Stdlib::Port,
    'addr' => Optional[Stdlib::Host],
}]
