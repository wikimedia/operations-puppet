# SPDX-License-Identifier: Apache-2.0
type CloudLB::HAProxy::Service::Definition = Struct[{
    'frontends'     => Array[CloudLB::HAProxy::Service::Frontend],
    'backend'       => CloudLB::HAProxy::Service::Backend,
    'healthcheck'   => CloudLB::HAProxy::Service::Healthcheck,
    'open_firewall' => Boolean,
    'type'          => Enum['http', 'tcp'],
}]
