class profile::acme_chief::cloud (
    String $active_host = hiera('profile::acme_chief::active'),
    String $passive_host = hiera('profile::acme_chief::passive'),
) {
    if $::fqdn == $passive_host {
        $active_host_ip = ipresolve($active_host, 4, $::nameservers[0])
        security::access::config { 'acme-chief':
            content  => "+ : acme-chief : ${active_host_ip}\n",
            priority => 60,
        }
    }
}