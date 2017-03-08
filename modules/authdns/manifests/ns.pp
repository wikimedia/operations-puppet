# == Class authdns::ns
# A class to implement Wikimedia's authoritative DNS servers
#
class authdns::ns(
    $nameservers = [ $::fqdn ],
    $gitrepo = undef,
    $monitoring = true,
    $conftool_prefix = hiera('conftool_prefix'),
) {
    $lvs_services = hiera('lvs::configuration::lvs_services')
    $discovery_services = hiera('discovery::services')

    class { 'authdns':
        nameservers => $nameservers,
        gitrepo     => $gitrepo,
        config_dir  => '/etc/gdnsd',
    }

    if $monitoring {
        include ::authdns::monitoring
    }

    # confd statefile templating for discovery
    class { 'confd':
        prefix => $conftool_prefix,
    }
    create_resources(::authdns::discovery_statefile, $discovery_services, { lvs_services => $lvs_services })
}
