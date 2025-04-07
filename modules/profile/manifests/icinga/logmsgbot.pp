class profile::icinga::logmsgbot(
    String        $active_host = lookup('profile::icinga::active_host'),
    Array[String] $partners    = lookup('profile::icinga::partners'),
) {
    class{ '::profile::tcpircbot':
        ensure => $active_host == $facts['networking']['fqdn'] ? {
            false => absent,
            true  => present,
        }
    }
}
