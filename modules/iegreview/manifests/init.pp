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
# [+parsoid_url+]
#   Parsoid API url for wikitext to html conversion.
#   Default http://parsoid.svc.eqiad.wmnet:8000/enwiki/
#
# [+require_upstream_ssl+]
#   Should upstream ssl termination be required? Default false.
#
# == Sample usage:
#
#   class { 'iegreview':
#       require_upstream_ssl => true,
#   }
#
class iegreview(
    $hostname             = 'iegreview.wikimedia.org',
    $deploy_dir           = '/srv/deployment/iegreview/iegreview',
    $cache_dir            = '/var/cache/iegreview',
    $log_dest             = 'udp://udplog:8420/iegreview',
    $mysql_host           = 'localhost',
    $mysql_db             = 'iegreview',
    $smtp_host            = 'localhost',
    $parsoid_url          = 'http://parsoid.svc.eqiad.wmnet:8000/enwiki/',
    $require_upstream_ssl = false,
) {
    include ::apache
    include ::apache::mod::php5
    include ::apache::mod::rewrite
    include ::apache::mod::headers

    include passwords::mysql::iegreview

    system::role { 'iegreview':
        description => 'Grants review application server - iegreview.wikimedia.org',
    }

    package { 'iegreview/iegreview':
        provider => 'trebuchet',
    }

    require_package('php5-mysql')
    require_package('php5-curl')

    apache::site { $hostname:
        content => template('iegreview/apache.conf.erb'),
    }

    ensure_resource('file', '/srv/deployment', {'ensure' => 'directory' })

    file { [ '/srv/deployment/iegreview', $deploy_dir ]:
        ensure => directory,
    }

    file { "${deploy_dir}/.env":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('iegreview/env.erb'),
        require => Package['iegreview/iegreview'],
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
