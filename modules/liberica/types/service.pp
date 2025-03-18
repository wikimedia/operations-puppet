# SPDX-License-Identifier: Apache-2.0
type Liberica::Service = Struct[{
        'forward_type'     => Enum['tunnel', 'direct_route'],
        'depool_threshold' => Float[0.0, 1.0],
        'cluster'          => String,
        'service'          => String,
        'ip'               => Stdlib::IP::Address::Nosubnet,
        'port'             => Stdlib::Port,
        'protocol'         => Liberica::Protocol,
        'healthchecks'     => Hash[String, Liberica::Healthcheck],
}]
