class role::dnsbox {
    system::role { 'dnsbox': description => 'DNS/NTP Site Infra Server' }

    include ::profile::standard
    include ::profile::dnsbox
}
