# SPDX-License-Identifier: Apache-2.0
# @summary configuration for a single diffscan instance
type Profile::Diffscan::Instance = Struct[{
  email         => Stdlib::Email,
  ranges        => Array[Stdlib::IP::Address],
  range_configs => Optional[Array[Profile::Diffscan::RangeConfig]],
}]
