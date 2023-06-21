# == Define ferm::service
# Uses ferm def &SERVICE or &R_SERVICE to allow incoming
# connections on the specific protocol and port.
#
# If $srange is not provided, all source addresses will be allowed.
# otherwise only traffic coming from $srange will be allowed.
#
# If $drange is not provided, all dest addresses will be allowed.
# otherwise only traffic incoming to $drange will be allowed.
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
define ferm::service(
    Ferm::Protocol $proto,
    Optional[Ferm::Port] $port = undef,
    Optional[Ferm::Portrange] $port_range = undef,
    Wmflib::Ensure $ensure  = present,
    String $desc    = '',
    Integer[0,99] $prio    = 10,
    Optional[Ferm::Hosts] $srange = undef,
    Optional[Ferm::Hosts] $drange = undef,
    Boolean $notrack = false,
) {
    if $port == undef and $port_range == undef {
        fail('One of port or port_range must be passed to ferm::service.')
    }
    if $port and $port_range {
        fail('You can only pass a port definition or a port range.')
    }

    $_srange = $srange.then |$x| { ferm::join_hosts($x) }
    $_drange = $drange.then |$x| { ferm::join_hosts($x) }

    if $port {
        $_port = $port ? {
            Array           => $port.join(','),
            default         => $port,
        }
    } elsif $port_range {
        $_port = $port_range.join(':')
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
