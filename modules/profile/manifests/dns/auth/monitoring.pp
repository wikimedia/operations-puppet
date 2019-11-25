# This is for the monitoring host to monitor the shared public addrs
class profile::dns::auth::monitoring (
    Hash[String, Hash[String, String]] $authdns_addrs = lookup('authdns_addrs'),
) {
    create_resources(authdns::monitoring::global, $authdns_addrs)
}
