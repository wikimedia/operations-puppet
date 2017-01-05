# == Class standard
# Class for *most* servers, standard includes

class standard(
    $has_default_mail_relay = true,
    $has_admin = true,
    $has_ganglia = true,
    ) {
    include ::base
    include ::standard::ntp

    if hiera('use_timesyncd', false) {
        unless $::fqdn in $::standard::ntp::wmf_peers[$::site] {
            include standard::ntp::timesyncd
        }
    }
    else
    {
        unless $::fqdn in $::standard::ntp::wmf_peers[$::site] {
            include standard::ntp::client
        }
    }

    include ::standard::diamond
    include ::standard::prometheus

    if $has_ganglia {
        include ::ganglia
    } else {
        include ::ganglia::monitor::decommission
    }

    # Some instances have their own exim definition that
    # will conflict with this
    if $has_default_mail_relay {
        include ::standard::mail::sender
    }

    # Some instances in production (ideally none) and labs do not use
    # the admin class
    if $has_admin {
        include ::admin
    }

}
