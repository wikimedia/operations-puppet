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
#   Where to place the config file. Currently cxserver expects it to be next to
#   Server.js, so you might want to place the config outside the repository and
#   place symlink to this file.
# [*log_dir*]
#   Place where cxserver can put log files. Assumed to be already existing and
#   have write access to cxserver user.
# [*logstash_host*]
#   GELF logging host.
# [*logstash_port*]
#   GELF logging port. Default: 12201
# [*restbase*]
#   Url to Restbase API.
# [*apertium*]
#   Url to Apertium service.
# [*yandex_url*]
#   Url to Yandex service.
# [*yandex_api_key*]
#   API key for Yandex service.
# [*proxy*]
#   Proxy URL for cxserver.
# [*port*]
#   Port where to run the cxserver service. Defaults to 8080.
# [*registry*]
#   Registry to use for language pairs for Content Translation.
# [*jwt_secret*]
#   JWT secret token
class cxserver(
    $base_path = '/srv/deployment/cxserver/deploy',
    $node_path = '/srv/deployment/cxserver/deploy/node_modules',
    $conf_path = '/srv/deployment/cxserver/deploy/src/config.js',
    $log_dir = '/var/log/cxserver',
    $logstash_host  = undef,
    $logstash_port  = 12201,
    $restbase = 'https://@lang.wikipedia.org/api/rest_v1/page/html/@title',
    $apertium = 'http://apertium.svc.eqiad.wmnet:2737',
    $yandex_url = undef,
    $yandex_api_key = undef,
    $proxy = undef,
    $port = 8080,
    $registry = undef,
    $jwt_secret = undef,
) {
    require_package('nodejs')

    if $registry {
        $ordered_registry = ordered_json($registry)
    }

    package { [ 'cxserver/deploy', ]:
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

    $log_file = "${log_dir}/main.log"

    file { $log_dir:
        ensure => directory,
        owner  => 'cxserver',
        group  => 'cxserver',
        mode   => '0775',
        before => Service['cxserver'],
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
