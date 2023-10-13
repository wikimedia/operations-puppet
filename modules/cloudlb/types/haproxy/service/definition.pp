# SPDX-License-Identifier: Apache-2.0
type CloudLB::HAProxy::Service::Definition = Struct[{
    'frontends'     => Array[CloudLB::HAProxy::Service::Frontend],
    'backend'       => CloudLB::HAProxy::Service::Backend,
    'healthcheck'   => CloudLB::HAProxy::Service::Healthcheck,
    'firewall'      => CloudLB::HAProxy::Service::Firewall,
    'type'          => Enum['http', 'tcp'],
    'http'          => Optional[CloudLB::HAProxy::Service::HTTPOptions],
}]
