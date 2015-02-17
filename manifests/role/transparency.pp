# == Class: role::transparency
#
# This role provisions the Wikimedia Transparency Report static site,
# hosted at <http://transparency.wikimedia.org>.
#
class role::transparency {
    include ::apache
    include ::apache::mod::rewrite

    $repo_dir = '/srv/org/wikimedia/TransparencyReport'
    $docroot  = "${repo_dir}/build"

    # The repo is currently not publicly clonable by private request.
    # Hence, turning cloning off for now, without removing the content
    # until the repo is public again
    # T89640
    #git::clone { 'wikimedia/TransparencyReport':
    #    ensure    => latest,
    #    directory => $repo_dir,
    #}

    apache::site { 'transparency.wikimedia.org':
        content => template('apache/sites/transparency.wikimedia.org.erb'),
    }

    ferm::service { 'transparency_http':
        proto => 'tcp',
        port  => '80',
    }
}
