# SPDX-License-Identifier: Apache-2.0
type Bgpalerter::Report::Params::Kafka = Struct[{
    host   => Stdlib::Host,
    port   => Stdlib::Port,
    topics => Hash[Variant[Bgpalerter::Report::Channel, Enum['default']], String[1]],
}]
