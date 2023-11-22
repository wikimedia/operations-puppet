# SPDX-License-Identifier: Apache-2.0
type CloudLB::HAProxy::Service::Frontend = Struct[{
    'port'                 => Stdlib::Port,
    'address'              => Optional[Stdlib::IP::Address::Nosubnet],
    'acme_chief_cert_name' => Optional[String],
}]
