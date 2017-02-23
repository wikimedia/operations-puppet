# Class mediawiki::conftool
#
# Adds credentials and conftool scripts to a mediawiki host
class mediawiki::conftool {

    include ::conftool::scripts
    conftool::credentials { 'mwdeploy': }

    # Will re-enable a mediawiki appserver after running scap pull
    file { '/usr/local/bin/mw-pool':
        ensure => present,
        source => 'puppet:///modules/mediawiki/mw-pool',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
}
