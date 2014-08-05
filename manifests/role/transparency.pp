# == Class: role::transparency
#
# This role provisions the Wikimedia Transparency Report static site,
# hosted at <http://transparency.wikimedia.org>.
#
class role::transparency {
    include ::apache
    include ::apache::mod::rewrite

    $repo_dir = '/srv/TransparencyReport'
    $docroot  = "${repo_dir}/build"

    git::clone { 'wikimedia/TransparencyReport':
        ensure    => latest,
        directory => $repo_dir,
    }

    apache::site { 'transparency.wikimedia.org':
        content => template('apache/sites/transparency.wikimedia.org.erb'),
    }

    ferm::service { 'transparency_http':
        proto => 'tcp',
        port  => '80',
    }
}
