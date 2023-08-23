# SPDX-License-Identifier: Apache-2.0
# The port(s) can be configured as an array of Stdlib::Port or a single Stdlib::Port
type Nftables::Port = Variant[
    Array[Stdlib::Port],
    Stdlib::Port,
]
