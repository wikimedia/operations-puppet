# == Class standard
# Class for *most* servers, standard includes

class standard {
    include standard::ntp

    unless $facts['fqdn'] in $::ntp_peers[$::site] {
        include standard::ntp::timesyncd
    }
}
