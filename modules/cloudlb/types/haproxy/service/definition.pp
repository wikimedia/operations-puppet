# SPDX-License-Identifier: Apache-2.0
type CloudLB::HAProxy::Service::Definition = Struct[{
    'frontends'    => Array[CloudLB::HAProxy::Service::Frontend],
    'backend'      => CloudLB::HAProxy::Service::Backend,
    'healthcheck'  => Optional[CloudLB::HAProxy::Service::Healthcheck],
    'firewall'     => CloudLB::HAProxy::Service::Firewall,
    'type'         => Enum['http', 'tcp', 'http-by-host'],
    'http'         => Optional[CloudLB::HAProxy::Service::HTTPOptions],
    'host_mapping' => Optional[Hash[String[1], String[1]]],
}]
