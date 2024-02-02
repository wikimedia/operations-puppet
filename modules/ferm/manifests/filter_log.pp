# defines a custom ferm rule to filter logs
define ferm::filter_log (
    Wmflib::Ensure                $ensure = present,
    Optional[Enum['tcp', 'udp']]  $proto = undef,
    Optional[Stdlib::IP::Address] $saddr = undef,
    Optional[Stdlib::IP::Address] $daddr = undef,
    Optional[Stdlib::Port]        $sport = undef,
    Optional[Stdlib::Port]        $dport = undef,
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
  ferm::rule { "filter_log_${name}":
    ensure => $ensure,
    rule   => "${_proto} ${_saddr} ${_daddr} ${_sport} ${_dport} DROP;",
    prio   => '98',
  }
}
