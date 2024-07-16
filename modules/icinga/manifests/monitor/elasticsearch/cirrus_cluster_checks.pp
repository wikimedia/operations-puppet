# == Class icinga::monitor::elasticsearch::cirrus_cluster_checks
class icinga::monitor::elasticsearch::cirrus_cluster_checks(
    Integer $shard_size_warning,
    Integer $shard_size_critical,
    String $threshold,
    Integer $timeout,
){
    $ports = [9243, 9443, 9643]
    $sites = ['eqiad', 'codfw']
    $scheme = 'https'

    $sites.each |$site| {
        $host = "search.svc.${site}.wmnet"

        # Create the Icinga host for search.
        # The service::catalog integration used to create these hosts
        # automatically via 'monitoring' section (now deprecated).
        # See also https://phabricator.wikimedia.org/T291946
        @monitoring::host { $host:
            ip_address    => ipresolve($host, 4),
            contact_group => 'admins',
            group         => 'lvs',
            critical      => false,
        }

        icinga::monitor::elasticsearch::base_checks { $host:
            host                => $host,
            scheme              => $scheme,
            ports               => $ports,
            shard_size_warning  => $shard_size_warning,
            shard_size_critical => $shard_size_critical,
            timeout             => $timeout,
            threshold           => $threshold,
        }

        icinga::monitor::elasticsearch::cirrus_checks { $host:
            host   => $host,
            scheme => $scheme,
            ports  => $ports,
        }
    }

}
