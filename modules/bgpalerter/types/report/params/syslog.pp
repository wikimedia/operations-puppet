# SPDX-License-Identifier: Apache-2.0
type Bgpalerter::Report::Params::Syslog = Struct[{
    showPaths => Integer[0],
    host      => Stdlib::Host,
    port      => Stdlib::Port,
    transport => Enum['udp', 'tcp'],
    templates => Hash[Variant[Bgpalerter::Report::Channel, Enum['default']], String[1]],
}]
