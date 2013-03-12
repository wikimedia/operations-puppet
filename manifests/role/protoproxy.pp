class role::protoproxy::ssl {
  $cluster = "ssl"

  $enable_ipv6_proxy = true

  include standard,
    certificates::wmf_ca,
    protoproxy::proxy_sites

  monitor_service { "https": description => "HTTPS", check_command => "check_ssl_cert!*.wikimedia.org", critical => true }
}
