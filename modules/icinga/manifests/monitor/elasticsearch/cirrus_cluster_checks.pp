# == Class icinga::monitor::elasticsearch::cirrus_cluster_checks
class icinga::monitor::elasticsearch::cirrus_cluster_checks{
    $ports = [9243, 9443, 9643]
    $hosts = ['search.svc.eqiad.wmnet', 'search.svc.codfw.wmnet']
    $scheme = 'https'

    $ports.each |$port| {
        $hosts.each |$host| {
            icinga::monitor::elasticsearch::base_checks { "Base checks - ${host}:${port}":
                host   => $host,
                scheme => $scheme,
                port   => $port,
            }

            icinga::monitor::elasticsearch::cirrus_checks { "Cirrus checks - ${host}:${port}":
                host   => $host,
                scheme => $scheme,
                port   => $port,
            }
        }
    }
}