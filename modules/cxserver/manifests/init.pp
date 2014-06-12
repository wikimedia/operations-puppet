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
# [*port*]
#   Port where to run the cxserver service. Defaults to 8080.

#
class cxserver(
    $base_path,
    $node_path,
    $conf_path,
    $log_dir,
    $parsoid,
    $port=8080
) {
    # apertium-* packages are for machine translation.
    # dictd-* packages for dictionary server.
    package { ['nodejs',
               'apertium',
               'apertium-es-ca',
               'dictd',
               'dict-freedict-eng-spa',
               'dict-freedict-spa-eng',
               'dict-freedict-eng-hin'
              ]:
        ensure => present,
    }

    $log_file = "{$log_dir}/main.log"

    file { $log_dir:
        ensure => directory,
        owner  => cxserver,
        group  => cxserver,
        mode   => '0775',
    }

    file { $conf_path:
        ensure  => present,
        owner   => cxserver,
        group   => cxserver,
        mode    => '0555',
        content => template('cxserver/config.erb'),
    }

    # The upstart configuration
    file { '/etc/init/cxserver.conf':
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0444',
        content => template('cxserver/upstart.erb'),
    }

    file { '/etc/logrotate.d/cxserver':
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0444',
        content => template('cxserver/logrotate.erb'),
    }

    service { 'cxserver':
        ensure     => running,
        hasstatus  => true,
        hasrestart => true,
        provider   => 'upstart',
        require    => File[$log_dir],
        subscribe  => File['/etc/init/cxserver.conf'],
    }
}
