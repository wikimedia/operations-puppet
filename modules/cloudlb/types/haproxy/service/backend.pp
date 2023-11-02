# SPDX-License-Identifier: Apache-2.0
type CloudLB::HAProxy::Service::Backend = Struct[{
    'port'         => Stdlib::Port,
    'servers'      => Variant[
        Array[OpenStack::ControlNode],
        # This is used for list of Designate nodes
        Array[Stdlib::Fqdn]
    ],
    'primary_host' => Optional[Stdlib::Fqdn],
}]
