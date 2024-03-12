# SPDX-License-Identifier: Apache-2.0
# @summary configuration for an individual striker instance
type Profile::Wmcs::Striker::Instance = Struct[{
  port    => Stdlib::Port::User,
  version => String[1],
  env     => Hash[String[1], Any],
}]
