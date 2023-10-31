# SPDX-License-Identifier: Apache-2.0
# @summary config for diffscan to load ip ranges from network::constants
type Profile::Diffscan::RangeConfig = Struct[{
  realm   => String[1],
  options => Hash,
}]
