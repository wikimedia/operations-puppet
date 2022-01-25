class profile::alertmanager::phab (
    Stdlib::HTTPSUrl $url = lookup('profile::alertmanager::phab::url'),
    String $username  = lookup('profile::alertmanager::phab::username'),
    String $token  = lookup('profile::alertmanager::phab::token'),
) {
    class { 'alertmanager::phab':
        url      => 'https://phabricator.wikimedia.org',
        username => $username,
        token    => $token,
    }
}
