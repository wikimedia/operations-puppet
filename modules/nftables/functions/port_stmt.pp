# SPDX-License-Identifier: Apache-2.0
function nftables::port_stmt(
    Wmflib::Protocol                     $proto,
    Enum['sport', 'dport']               $dir,
    Optional[Nftables::Port]             $port       = undef,
    Optional[Firewall::Portrange]        $port_range = undef,
) >> String {
    $_port = $port.then |$x| { [$x].flatten }

    # figure out transport protocol statements
    if !$_port.empty() and $port_range {
        fail("${title}: You can only pass an array of ports or a range, but not both")
    } elsif $_port.empty() and !$port_range {
        fail("${title}: You need at least one of port or port_range")
    }

    if !$_port.empty() {
        $port_stmt = "${proto} ${dir} { ${_port.sort.join(', ')} }"
    } elsif $port_range {
        if $port_range[0] >= $port_range[1] {
            fail("${title}: Incorrect port range ${port_range[0]} >= ${port_range[1]}")
        }
        $port_stmt = "${proto} ${dir} ${port_range.join('-')}"
    }
    $port_stmt
}
