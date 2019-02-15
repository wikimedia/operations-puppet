# defines a custom ferm rule to filter logs
define ferm::filter_log (
    Optional[Enum['tcp', 'udp']] $proto = undef,
    Optional[Stdlib::Ip_address] $saddr = undef,
    Optional[Stdlib::Ip_address] $daddr = undef,
    Optional[Stdlib::Port]       $sport = undef,
    Optional[Stdlib::Port]       $dport = undef,
) {
  $_proto = $proto ? {
    undef   => '',
    default => "proto ${proto}",
  }
  $_saddr = $saddr ? {
    undef   => '',
    default => "saddr ${saddr}",
  }
  $_daddr = $daddr ? {
    undef   => '',
    default => "daddr ${daddr}",
  }
  $_sport = $sport ? {
    undef   => '',
    default => "sport ${sport}",
  }
  $_dport = $dport ? {
    undef   => '',
    default => "dport ${dport}",
  }
  ferm::rule {"filter log ${name}":
    rule => "${_proto} ${_saddr} ${_daddr} ${_sport} ${_dport} DROP;",
    prio => '98',
  }
}
