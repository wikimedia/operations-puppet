# == Class geowiki
# Clones analytics/geowiki python scripts
#
class geowiki {
    include ::geowiki::params
    git::clone { 'geowiki-scripts':
        ensure    => 'latest',
        directory => $::geowiki::params::scripts_path,
        origin    => 'https://gerrit.wikimedia.org/r/p/analytics/geowiki.git',
        owner     => $::geowiki::params::user,
        group     => $::geowiki::params::user,
    }
}
