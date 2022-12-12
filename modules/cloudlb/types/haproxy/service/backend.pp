# SPDX-License-Identifier: Apache-2.0
type CloudLB::HAProxy::Service::Backend = Struct[{
    'port'         => Stdlib::Port,
    'servers'      => Array[Stdlib::Fqdn],
    'primary_host' => Optional[Stdlib::Fqdn],
}]
