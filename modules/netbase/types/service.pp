# SPDX-License-Identifier: Apache-2.0
# @summary This structure is used to represent service definitions across our infrastructre
#   it has been designed to be mostly compatible with the values data present in /etc/services
#   however also addes some additional flexibility namely a portend parameter so we can represent
#   port ranges
#
# Im not sure if puppet-strings pares params fore types but still useful
# to stick to the convention
# @param protocols An array of supported protocols
# @param port the port number for the specific service
# @param portend An optional parameter used to specify the port end.  if specified this service
#   description represents a port range and not an individual port.  This parameter should only
#   be used for services which operate on multiple ports e.g. traceroute.  It should not be used to
#   group services which happen to listen of an contiguous set of ports
# @param description a free text description of the service
# @param aliases An array of aliases the service is also known by
type Netbase::Service = Struct[{
    protocols   => Array[Enum['udp', 'tcp']],
    port        => Stdlib::Port,
    portend     => Optional[Stdlib::Port],
    description => Optional[String[1]],
    aliases     => Optional[Array[Pattern[/\w+/]]],
}]
