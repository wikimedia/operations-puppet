class profile::standard(
    Boolean $has_default_mail_relay = lookup('profile::standard::has_default_mail_relay'),
    Array[Stdlib::IP::Address] $monitoring_hosts = lookup('monitoring_hosts'),
    Boolean $enable_ip6_mapped = lookup('profile::standard::enable_ip6_mapped')
) {
    class { '::standard':
        has_default_mail_relay => $has_default_mail_relay,
        monitoring_hosts       => $monitoring_hosts,
    }
    if $enable_ip6_mapped {
        interface::add_ip6_mapped { 'main': }
    }
}
