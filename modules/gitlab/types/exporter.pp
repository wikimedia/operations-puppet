# SPDX-License-Identifier: Apache-2.0
  type Gitlab::Exporter = Struct[{
    port    => Stdlib::Port,
    listen_address => Optional[Stdlib::IP::Address], # if not present default to localhost
  }]
