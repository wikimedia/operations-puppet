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
define ferm::service(
    $proto,
    $port,
    $ensure  = present,
    $desc    = '',
    $prio    = '10',
    Optional[Ferm::Hosts] $srange = undef,
    Optional[Ferm::Hosts] $drange = undef,
    $notrack = false,
) {
    $_srange = $srange.then |$x| { ferm::join_hosts($x) }
    $_drange = $drange.then |$x| { ferm::join_hosts($x) }

    @file { "/etc/ferm/conf.d/${prio}_${name}":
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
