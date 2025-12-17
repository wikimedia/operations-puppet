# SPDX-License-Identifier: Apache-2.0
type Thanos::Store::RelabelRule = Struct[{
  action        => Thanos::Store::RelabelRuleAction,
  regex         => String,
  source_labels => Array[String],
}]
