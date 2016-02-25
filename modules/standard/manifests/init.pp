# == Class standard
# Class for *most* servers, standard includes

class standard(
    $has_default_mail_relay = true,
    $has_admin = true,
    $has_ganglia = true,
    ) {
    include ::base
    include ::standard::ntp

    unless $::fqdn in $::standard::ntp::wmf_all_peers {
        include standard::ntp::client
    }
    include standard::diamond

    if $has_ganglia {
        include ::ganglia
    }

    # Some instances have their own exim definition that
    # will conflict with this
    if $has_default_mail_relay {
        include role::mail::sender
    }

    # Some instances in production (ideally none) and labs do not use
    # the admin class
    if $has_admin {
        include ::admin
    }



}
