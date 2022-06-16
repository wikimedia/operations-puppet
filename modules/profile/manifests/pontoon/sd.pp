# Pontoon Service Discovery
#
# The default implementation of sd: all routable services will be pointed to the first host
# running the pontoon::lb role. Other DNS queries will be sent to DNS resolvers listed in
# sd_nameservers.
class profile::pontoon::sd (
    Array[Stdlib::IP::Address] $sd_nameservers = lookup('profile::pontoon::sd_nameservers'),
    Array[Stdlib::IP::Address] $local_nameservers = lookup('profile::resolving::nameservers'),
    Array[Stdlib::Fqdn] $lbs = pontoon::hosts_for_role('pontoon::lb'), # lint:ignore:wmf_styleguide
) {
    unless length($local_nameservers) == 1 and $local_nameservers[0] == '127.0.0.53' {
        fail("Local nameservers ${local_nameservers} misconfigured")
    }

    if empty($lbs) {
        fail('No LBs configured')
    }

    if empty($sd_nameservers) {
        fail('No upstream nameservers configured')
    }

    # Announce all services with 'role' keyword. The LB will take care of routing to backend hosts.
    $role_services = wmflib::service::fetch().filter |$name, $config| {
        ('role' in $config)
    }

    class { 'pontoon::sd':
        lb_address      => ipresolve($lbs[0], 4),
        nameservers     => $sd_nameservers,
        services_config => $role_services,
        # Make sure the local resolver used for SD
        # is installed before /etc/resolv.conf is changed
        before          => Class['resolvconf'],
    }
}
