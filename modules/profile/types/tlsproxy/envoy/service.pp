# SPDX-License-Identifier: Apache-2.0
type Profile::Tlsproxy::Envoy::Service = Struct[{
    'server_names' => Array[Variant[Stdlib::Fqdn, Enum['*']]],
    'port' => Stdlib::Port,
    'cert_name' => Optional[String],
}]
