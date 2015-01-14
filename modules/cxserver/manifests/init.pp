# == Class: cxserver
#
# cxserver is a node.js backend for the content translation tool.
# https://www.mediawiki.org/wiki/Content_translation
#
# === Parameters
#
# [*base_path*]
#   Path to the cxserver code.
# [*node_path*]
#   Path to the node modules cxserver depends on.
# [*conf_path*]
#   Where to place the config file. Currently cxserver experts it to be next to
#   Server.js, so you might want to place the config outside the repository and
#   place symlink to this file.
# [*log_dir*]
#   Place where cxserver can put log files. Assumed to be already existing and
#   have write access to cxserver user.
# [*parsoid*]
#   Url to parsoid service.
# [*apertium*]
#   Url to apertium service.
# [*port*]
#   Port where to run the cxserver service. Defaults to 8080.
class cxserver(
    $base_path = '/srv/deployment/cxserver/cxserver',
    $node_path = '/srv/deployment/cxserver/deploy/node_modules',
    $conf_path = '/srv/deployment/cxserver/cxserver/config.js',
    $log_dir = '/var/log/cxserver',
    $parsoid = 'http://parsoid-lb.eqiad.wikimedia.org',
    $apertium = 'http://apertium.svc.eqiad.wmnet:2737',
    $port = 8080,
) {
    # dictd-* packages for dictionary server.
    require_package('nodejs')

    package { [
             'cxserver/cxserver',
             'cxserver/deploy',
            ]:
        ensure   => present,
        provider => 'trebuchet',
    }

    group { 'cxserver':
        ensure => present,
        name   => 'cxserver',
        system => true,
    }

    user { 'cxserver':
        gid        => 'cxserver',
        home       => '/var/lib/cxserver',
        managehome => true,
        system     => true,
    }

    package { [ 'dictd',
                'dict-freedict-eng-spa',
                'dict-freedict-spa-eng',
                'dict-freedict-eng-hin',
            ]:
        ensure => present,
    }

    $log_file = "${log_dir}/main.log"

    file { $log_dir:
        ensure => directory,
        owner  => 'cxserver',
        group  => 'cxserver',
        mode   => '0775',
    }

    file { $conf_path:
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('cxserver/config.erb'),
        notify  => Service['cxserver'],
    }

    # The upstart configuration
    file { '/etc/init/cxserver.conf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('cxserver/upstart.erb'),
    }

    file { '/etc/logrotate.d/cxserver':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('cxserver/logrotate.erb'),
    }

    # Link with upstart-job
    file { '/etc/init.d/cxserver':
        ensure => 'link',
        target => '/lib/init/upstart-job',
    }

    service { 'cxserver':
        ensure     => running,
        hasstatus  => true,
        hasrestart => true,
        provider   => 'upstart',
        require    => [
            File[$log_dir],
            File['/etc/init.d/cxserver']
        ],
        subscribe  => File['/etc/init/cxserver.conf'],
    }
}
