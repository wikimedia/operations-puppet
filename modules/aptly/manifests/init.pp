# Class: aptly
# Sets up a simple aptly repo server serving over http
#
# Set up to only allow root to add packages
class aptly(
    $manage_nginx=true,
    $owner='root',
    $group='root',
){
    require_package('aptly')
    require_package('graphviz') # for aptly graph

    file { '/srv/packages':
        ensure => directory,
        owner  => $owner,
        group  => $group,
        mode   => '0755',
    }

    file { '/etc/aptly.conf':
        ensure => present,
        source => 'puppet:///modules/aptly/aptly.conf',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    if $manage_nginx {
        nginx::site { 'aptly-server':
            source => 'puppet:///modules/aptly/aptly.nginx.conf',
        }
    }

    ferm::service { 'aptly':
        proto  => 'tcp',
        port   => '80',
        srange => '$DOMAIN_NETWORKS',
    }
}
