# SPDX-License-Identifier: Apache-2.0

# K8s::Core::V1Taint represents a taint to be used in KubeletConfiguration YAML
type K8s::Core::V1Taint = Struct[{
  key             => String[1],
  effect          => Enum['NoSchedule', 'PreferNoSchedule', 'NoExecute'],
  Optional[value] => String[1],
}]
