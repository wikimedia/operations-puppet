# == Define ferm::service
# Uses ferm def &SERVICE or &R_SERVICE to allow incoming
# connections on the specific protocol and port.
#
# If neither $srange nor $src_sets are provided, all source
# addresses will be allowed. Otherwise only traffic coming from
# $srange (specified as hosts/networks) and/or $src_sets
# (specified via predefined sets of servers, for Ferm a macro
# and for nft a set definition)will be allowed.
#
# If neither $drange nor $dst_sets are provided, all dest
# addresses will be allowed. Otherwise only traffic incoming to
# $drange (specified as hosts/networks) and/or $dst_sets
# (specified via predefined sets of servers, for Ferm a macro
# and for nft a set definition) will be allowed.
#
# The range of ports can be specified in two ways:
# 1. $port represents a single port or an array of ports. In can
#    be set in two separate methods:
#    - The legacy setting takes Ferm-specific syntax (either a
#      string which gets directly passed to Ferm (e.g. "22", but
#      also accepts service names from /etc/services (e.g. "http")
#    - The preferred new type is to pass an array of Stdlib::Port
#      (which is agnostic to the underlying firewall solution in use)
# 2. $port_range selects an entire range of IPs, it gets passed as
#    a tuple of Stdlib::Port entries representing the lower and upper
#    ports of the range
# Only one of $port ot $port_range can be given
#
# $qos can be one of "high/normal/low/control" to mark traffic with DSCP
define ferm::service(
    Wmflib::Protocol $proto,
    Optional[Ferm::Port] $port = undef,
    Optional[Firewall::Portrange] $port_range = undef,
    Wmflib::Ensure $ensure  = present,
    String $desc    = '',
    Integer[0,99] $prio    = 10,
    # TODO: we should move to the stricter Firewall::Range type
    Optional[Firewall::Hosts] $srange = undef,
    Optional[Firewall::Hosts] $drange = undef,
    Optional[Array[String[1]]] $src_sets = undef,
    Optional[Array[String[1]]] $dst_sets = undef,
    Boolean $notrack = false,
    Optional[Firewall::Qos] $qos = undef,
) {
    if $port == undef and $port_range == undef {
        fail('One of port or port_range must be passed to ferm::service.')
    }
    if $port and $port_range {
        fail('You can only pass a port definition or a port range.')
    }

    $_srange = $srange.then |$x| { ferm::join_hosts($x) }
    $_drange = $drange.then |$x| { ferm::join_hosts($x) }

    if $src_sets {
        $sets_base_src = $src_sets.map | $set | { sprintf('$%s', $set) }

        # If more than one entry is given the srange needs to be wrapped in brackets
        if $sets_base_src.length > 1 {
            $_src_sets = sprintf('(%s)', join($sets_base_src, ' '))
        } else {
            $_src_sets = join($sets_base_src, ' ')
        }
    }

    if $dst_sets {
        $sets_base_dst = $dst_sets.map | $set | { sprintf('$%s', $set) }

        # If more than one entry is given the drange needs to be wrapped in brackets
        if $sets_base_dst.length > 1 {
            $_dst_sets = sprintf('(%s)', join($sets_base_dst, ' '))
        } else {
            $_dst_sets = join($sets_base_dst, ' ')
        }
    }

    if $port {
        $_port = $port ? {
            Array[Stdlib::Port,1,1] => $port[0],
            Array                   => sprintf('(%s)', $port.join(' ')),
            default                 => $port,
        }
    } elsif $port_range {
        $_port = $port_range.join(':')
    }

    if $qos != undef {
        $dscp = firewall::qos2dscp($qos)
    }

    @file { '/etc/ferm/conf.d/%02d_%s'.sprintf($prio, $name):
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('ferm/service.erb'),
        require => File['/etc/ferm/conf.d'],
        notify  => Service['ferm'],
        tag     => 'ferm',
    }
}
