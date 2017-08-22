# == Define ferm::client
# Uses ferm def &CLIENT or &R_CLIENT to allow outbound
# connections on the specific protocol and destination port.
#
# If $drange is not provided, all destination addresses will be allowed.
# otherwise only traffic towards $drange will be allowed.
#
define ferm::client(
    $proto,
    $port,
    $ensure  = present,
    $desc    = '',
    $prio    = '10',
    $drange  = undef,
    $notrack = false,
) {
    @file { "/etc/ferm/conf.d/${prio}_${name}_client":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('ferm/client.erb'),
        require => File['/etc/ferm/conf.d'],
        notify  => Service['ferm'],
        tag     => 'ferm',
    }
}
