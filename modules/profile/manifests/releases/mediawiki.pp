# server hosting MediaWiki releases
# https://releases.wikimedia.org/mediawiki/
class profile::releases::mediawiki (
    $sitename = lookup('profile::releases::mediawiki::sitename'),
    $sitename_jenkins = lookup('profile::releases::mediawiki::sitename_jenkins'),
    $prefix = lookup('profile::releases::mediawiki::prefix'),
    $http_port = lookup('profile::releases::mediawiki::http_port'),
    $server_admin = lookup('profile::releases::mediawiki::server_admin'),
    $active_server = lookup('releases_server'),
    $passive_server = lookup('releases_server_failover'),
    $jenkins_agent_username = lookup('jenkins_agent_username'),
    $jenkins_agent_key = lookup('profile::releases::mediawiki::jenkins_agent_key'),
){
    class { '::jenkins':
        access_log => true,
        http_port  => $http_port,
        prefix     => $prefix,
        umask      => '0002',
    }

    base::service_auto_restart { 'jenkins': }

    # Master connect to itself via the fqdn / primary IP ipaddress
    class { 'jenkins::slave':
        ssh_key => $jenkins_agent_key,
        user    => $jenkins_agent_username,
        workdir => '/srv/jenkins-slave',
    }

    class { '::releases':
        sitename         => $sitename,
        sitename_jenkins => $sitename_jenkins,
        http_port        => $http_port,
        prefix           => $prefix,
    }

    class { '::contint::composer': }

    $php7_packages = [
        'php7.0-cli',
        'php7.0-common',
        'php7.0-curl',
        'php7.0-gmp',
        'php7.0-intl',
        'php-memcached',
        'php7.0-mysql',
        'php-redis',
        'php7.0-xmlrpc',
        'php7.0-dev',
        'php7.0-ldap',
        'php7.0-gd',
        'php7.0-pgsql',
        'php7.0-sqlite3',
        'php7.0-tidy',
        'php7.0-phpdbg',
        'php7.0-zip',
        'php7.0-bcmath','php7.0-mbstring',
        'php7.0-xml',
        'php-imagick',
        'php-tideways',
        'php-ast',
    ]

    package { $php7_packages :
        ensure  => present,
    }
    # PHP Extensions dependencies (mediawiki/php/*.git)
    package { [
        'libthai-dev',      # wikidiff2
        'luajit',           # luasandbox
        'liblua5.1-0-dev',  # luasandbox
    ]:
        ensure => present
    }

    class { '::httpd':
        modules => ['rewrite', 'headers', 'proxy', 'proxy_http'],
    }

    httpd::site { $sitename:
        content => template('releases/apache.conf.erb'),
    }

    httpd::site { $sitename_jenkins:
        content => template('releases/apache-jenkins.conf.erb'),
    }

    monitoring::service { 'http_releases':
        description   => "HTTP ${sitename}",
        check_command => "check_http_url!${sitename}!/",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Releases.wikimedia.org',
    }

    monitoring::service { 'http_releases_jenkins':
        description   => "HTTP ${sitename_jenkins}",
        check_command => "check_http_url!${sitename_jenkins}!/login",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Releases.wikimedia.org#Jenkins',
    }

    ferm::service { 'releases_http':
        proto  => 'tcp',
        port   => '80',
        srange => '$CACHES',
    }

    backup::set { 'srv-org-wikimedia': }

    rsync::quickdatacopy { 'srv-org-wikimedia-releases':
      ensure      => present,
      auto_sync   => true,
      source_host => $active_server,
      dest_host   => $passive_server,
      module_path => '/srv/org/wikimedia/releases',
    }
}
