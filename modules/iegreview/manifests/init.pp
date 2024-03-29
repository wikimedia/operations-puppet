# SPDX-License-Identifier: Apache-2.0
# = Class: iegreview
#
# This class provisions the IEG grant review application.
#
# == Parameters:
# [+hostname+]
#   Hostname for apache vhost. Default iegreview.wikimedia.org.
#
# [+deploy_dir+]
#   Directory application is deployed to.
#   Default /srv/deployment/iegreview/iegreview.
#
# [+cache_dir+]
#   Directory for caching twig templates. Default /var/cache/iegreview.
#
# [+log_dest+]
#   Log destination. Default udp://udplog:8420/iegreview
#
# [+serveradmin+]
#   Administrative contact email address. Default noc@wikimedia.org.
#
# [+mysql_host+]
#   MySQL database server. Default localhost.
#
# [+mysql_db+]
#   MySQL database. Default iegreview.
#
# [+smtp_host+]
#   Outgoing email relay. Default localhost.
#
# [+restbase_url+]
#   RESTBase API url for wikitext to html conversion.
#   Default https://en.wikipedia.org/api/rest_v1/transform/wikitext/to/html
#
# == Sample usage:
#
#   class { 'iegreview': }
#
class iegreview(
    $hostname             = 'iegreview.wikimedia.org',
    $deploy_dir           = '/srv/deployment/iegreview/iegreview',
    $cache_dir            = '/var/cache/iegreview',
    $log_dest             = 'udp://udplog:8420/iegreview',
    $mysql_host           = 'localhost',
    $mysql_db             = 'iegreview',
    $smtp_host            = 'localhost',
    $restbase_url         = 'https://en.wikipedia.org/api/rest_v1/transform/wikitext/to/html',
) {

    include passwords::mysql::iegreview

    system::role { 'iegreview':
        description => 'Grants review application server - iegreview.wikimedia.org',
    }

    scap::target { 'iegreview/iegreview':
        service_name => 'iegreview',
        deploy_user  => 'deploy-service',
    }

    ensure_packages(['php-mysql', 'php-curl'])

    httpd::site { $hostname:
        content => template('iegreview/apache.conf.erb'),
    }

    ensure_resource('file', '/srv/deployment', {'ensure' => 'directory' })

    file { '/etc/iegreview.ini':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('iegreview/env.erb'),
        notify  => Service['apache2'],
    }

    file { $cache_dir:
        ensure => directory,
        owner  => 'www-data',
        group  => 'root',
        mode   => '0755',
    }
}
# vim:sw=4 ts=4 sts=4 et:
