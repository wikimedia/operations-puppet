# == Class icinga::monitor::elasticsearch::cirrus_cluster_checks
class icinga::monitor::elasticsearch::cirrus_cluster_checks{
    $ports = [9243, 9443, 9643]
    $hosts = ['search.svc.eqiad.wmnet', 'search.svc.codfw.wmnet']
    $scheme = 'https'

    $hosts.each |$host| {
        icinga::monitor::elasticsearch::base_checks { $host:
            host   => $host,
            scheme => $scheme,
            ports  => $ports,
        }

        icinga::monitor::elasticsearch::cirrus_checks { $host:
            host   => $host,
            scheme => $scheme,
            ports  => $ports,
        }
    }
}