class profile::alertmanager::phab (
    Stdlib::HTTPSUrl $url = lookup('profile::alertmanager::phab::url'),
    String $username  = lookup('profile::alertmanager::phab::username'),
    String $token  = lookup('profile::alertmanager::phab::token'),
    Array[Stdlib::Host] $prometheus_nodes = lookup('prometheus_nodes'),
) {
    class { 'alertmanager::phab':
        url      => 'https://phabricator.wikimedia.org',
        username => $username,
        token    => $token,
    }

    $hosts = join($prometheus_nodes, ' ')
    ferm::service { 'alertmanager-phab':
        proto  => 'tcp',
        port   => 8292,
        srange => "@resolve((${hosts}))",
    }
}
