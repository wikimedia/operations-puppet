# SPDX-License-Identifier: Apache-2.0
type CloudLB::HAProxy::Service::Frontend = Struct[{
    'port'                 => Stdlib::Port,
    'address'              => Optional[Variant[Stdlib::IP::Address::Nosubnet, Array[Stdlib::IP::Address::Nosubnet, 1]]],
    'acme_chief_cert_name' => Optional[String],
}]
