# SPDX-License-Identifier: Apache-2.0
type CloudLB::HAProxy::Service::Frontend = Struct[{
    'port'                 => Stdlib::Port,
    'acme_chief_cert_name' => Optional[String],
}]
