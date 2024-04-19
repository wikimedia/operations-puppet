# SPDX-License-Identifier: Apache-2.0
type OpenStack::Neutron::ProviderNetwork = Struct[{
  bridge    => String[1],
  interface => String[1],
}]
