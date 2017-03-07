# == Class authdns::ns
# A class to implement Wikimedia's authoritative DNS servers
#
class authdns::ns(
    $nameservers = [ $::fqdn ],
    $gitrepo = undef,
    $monitoring = true,
    $conftool_prefix = hiera('conftool_prefix'),
    $lvs_services,
    $discovery_services,
) {
    require ::geoip::data::puppet

    class authdns {
        nameservers => $nameservers,
        gitrepo     => $gitrepo,
        config_dir  => '/etc/gdnsd',
        clone_data  => true,
        run_service => true,
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
