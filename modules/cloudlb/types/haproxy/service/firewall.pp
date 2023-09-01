# SPDX-License-Identifier: Apache-2.0
type CloudLB::HAProxy::Service::Firewall = Variant[
    Struct[{
        'open_to_internet' => Boolean,
    }],
    Struct[{
        'open_to_cloud_private' => Boolean,
    }],
    Struct[{
        'restricted_to_fqdns' => Array[Stdlib::Fqdn],
    }],
]
