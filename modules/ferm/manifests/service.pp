# == Define ferm::service
# Uses ferm def &SERVICE or &R_SERVICE to allow incoming
# connections on the specific protocol and port.
#
# If $srange is not provided, all source addresses will be allowed.
# otherwise only traffic coming from $srange will be allowed.
#
define ferm::service(
    $proto,
    $port,
    $ensure = 'present',
    $desc   = '',
    $prio   = '10',
    $srange = undef,
) {
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
