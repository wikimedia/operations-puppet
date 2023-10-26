# SPDX-License-Identifier: Apache-2.0
# @summary type to pass an srange in nft variant
type Firewall::Range = Variant[
  Array[
    Variant[
      Stdlib::Fqdn,
      Stdlib::IP::Address,
    ],
  ]
]
