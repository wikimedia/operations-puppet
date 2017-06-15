# server hosting Mediawiki releases
# https://releases.wikimedia.org/mediawiki/
class profile::releases::mediawiki {

    class { '::jenkins':
        access_log => true,
        http_port  => '8080',
        prefix     => '/jenkins',
        umask      => '0002',
    }

    backup::set { 'srv-org-wikimedia': }
}
