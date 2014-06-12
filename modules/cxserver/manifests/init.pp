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
# [*log_dir*]
#   Place where cxserver can put log files. Assumed to be already existing and
#   have write access to cxserver user.
#
class cxserver(
    $base_path,
    $node_path,
    $log_file
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
