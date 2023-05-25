# @summary create a file for outbound client traffic
# @param proto the protocol to use
# @param port the port to use
# @param ensure the ensureabl parameter
# @param desc the description
# @param drange the destination range
# @param notrack if true dont track state
define ferm::client(
    Enum['tcp', 'udp']  $proto,
    Ferm::Port          $port,
    Wmflib::Ensure      $ensure  = present,
    Integer[0,99]       $prio    = 10,
    Boolean             $notrack = false,
    Array[String[1]]    $drange  = [],
    Optional[String[1]] $desc    = undef
) {
    $_port = $port ? {
        String  => "(${port})",
        default => $port,
    }
    $_drange = $drange.size ? {
        0       => undef,
        1       => $drange[0],
        default => "({drange.join(' ')})"
    }
    @file { '/etc/ferm/conf.d/%02d_%s_client'.sprintf($prio, $name):
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
