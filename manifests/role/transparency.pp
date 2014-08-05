# == Class: role::transparency
#
# This role provisions the Wikimedia Transparency Report static site,
# hosted at <http://transparency.wikimedia.org>.
#
class role::transparency {
    include ::apache

    $repo_path = '/srv/TransparencyReport'
    $site_path = "${repo_path}/build"

    git::clone { 'wikimedia/TransparencyReport':
        ensure    => latest,
        directory => '/srv/TransparencyReport',
    }

    apache::site { 'transparency.wikimedia.org':
        content => template('apache/sites/transparency.wikimedia.org.erb'),
    }

    ferm::service { 'transparency_http':
        proto => 'tcp',
        port  => '80',
    }
}
