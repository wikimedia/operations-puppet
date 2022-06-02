# SPDX-License-Identifier: Apache-2.0
type Poolcounter::Backends = Array[
    Struct[{
        'label' => String,
        'fqdn'  => Stdlib::Fqdn,
    }]
]
