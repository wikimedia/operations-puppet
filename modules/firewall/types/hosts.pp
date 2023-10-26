# SPDX-License-Identifier: Apache-2.0
# @summary ferm host filter
type Firewall::Hosts = Variant[
  String,
  Array[
    Variant[
      Stdlib::Fqdn,
      Stdlib::IP::Address,
      Ferm::Variable
    ],
  ]
]
