# SPDX-License-Identifier: Apache-2.0

# @type Wmflib::Infra::Devices

# Represents the infrastructure devices, can be either a device running the
# network (e.g. router, switch) or a generic infrastructure device (RIPE Atlas,
# console server, etc)

type Wmflib::Infra::Devices = Hash[
  Stdlib::Host,
  Variant[Wmflib::Network::Device, Wmflib::Infra::Device],
]
