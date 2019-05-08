# == Class: phabricator
#
# Phabricator is a collection of open source web applications
# that help software companies build better software.
#
# === Parameters
#
# [*phabdir*]
#    The path on disk to clone the needed repositories
#
# [*timezone]
#     A php.ini compatible timezone
#     http://www.php.net//manual/en/datetime.configuration.php
#
# [*settings*]
#     A hash of configuration options for the local settings json file.
#     https://secure.phabricator.com/book/phabricator/article/advanced_configuration/#configuration-sources
#
# [*conf_files*]
#    hash of hashes which define phabricator::conf_env resources
#
# [*mysql_admin_user*]
#     Specify to use a different user for schema upgrades and database
#     maintenance
#     Requires: mysql_admin_pass
#
# [*mysql_admin_pass*]
#     Specify to use a different password for schema upgrades and database
#     maintenance
#     Requires: mysql_admin_user
#
#
# [*serveraliases*]
#     Alternative domains on which to respond too
#
# [*deploy_user*]
#     The username that is used for scap deployments
#
# [*deploy_target*]
#     The name of the scap3 deployment repo, e.g. phabricator/deployment
#
# [*enable_php_fpm*]
#     Weather to enable php-fpm, defaults to false.
#
# [*opcache_validate*]
#     Allows you to enable opcache revalidation.
#

# === Examples
#
#    class { 'phabricator':
#        settings    => {
#            'phabricator.base-uri' => 'http://myurl.domain',
#        },
#    }
#
# See README for post install instructions
#

class phabricator (
    Stdlib::Unixpath $phabdir = '/srv/phab',
    Stdlib::Unixpath $confdir = '/srv/phab/phabricator/conf',
    String $timezone          = 'UTC',
    Array $trusted_proxies    = [],
    Array $libraries          = [],
    Hash $settings            = {},
    Hash $conf_files          = {},
    String $mysql_admin_user  = '',
    String $mysql_admin_pass  = '',
    String $serveradmin       = '',
    Array $serveraliases      = [],
    String $deploy_user       = 'phab-deploy',
    String $deploy_target     = 'phabricator/deployment',
    Boolean $enable_php_fpm   = false,
    Integer $opcache_validate = 0,
) {
    validate_hash($conf_files)

    $deploy_root = "/srv/deployment/${deploy_target}"

    # base dependencies to ensure the phabricator deployment root exists
    # save as a var since this will be required by many resources in this class
    $base_requirements = [Package[$deploy_target]]

    #A combination of static and dynamic conf parameters must be merged
    $module_path = get_module_path($module_name)
    $fixed_settings = loadyaml("${module_path}/data/fixed_settings.yaml")

    if ($libraries) {
        phabricator::libext { $libraries:
            rootdir => $phabdir,
            require => $base_requirements,
        }
        $library_settings = { 'load-libraries' => $libraries }
    }

    #per stdlib merge the dynamic settings will take precendence for conflicts
    $phab_settings = merge($fixed_settings, $library_settings, $settings)

    if empty($mysql_admin_user) {
        $storage_user = $phab_settings['mysql.user']
    } else {
        $storage_user = $mysql_admin_user
    }

    if empty($mysql_admin_pass) {
        $storage_pass = $phab_settings['mysql.pass']
    } else {
        $storage_pass = $mysql_admin_pass
    }

    # stretch - PHP (7.2) packages and Apache module
    # warning: currently Phabricator supports PHP 7.1+ but not PHP 7.0
    # https://secure.phabricator.com/rPa2cd3d9a8913d5709e2bc999efb75b63d7c19696
    if os_version('debian >= stretch') {
        apt::repository { 'wikimedia-php72':
            uri        => 'http://apt.wikimedia.org/wikimedia',
            dist       => "${::lsbdistcodename}-wikimedia",
            components => 'component/php72',
            notify     => Exec['apt_update_php'],
        }

        # First installs can trip without this
        exec {'apt_update_php':
            command     => '/usr/bin/apt-get update',
            refreshonly => true,
            logoutput   => true,
        }

        if !$enable_php_fpm {
            package { [
                'php-apcu',
                'php-mailparse',
                'php7.2-mysql',
                'php7.2-gd',
                'php7.2-dev',
                'php7.2-curl',
                'php7.2-cli',
                'php7.2-json',
                'php7.2-ldap',
                'php7.2-mbstring',
                'libapache2-mod-php7.2']:
                    ensure  => present,
                    require => Apt::Repository['wikimedia-php72'],
            }
        }
    } else {
        # jessie - PHP (5.5/5.6) packages and Apache module
        package { [
            'php5-apcu',
            'php5-mysqlnd',
            'php5-gd',
            'php5-mailparse',
            'php5-dev',
            'php5-curl',
            'php5-cli',
            'php5-json',
            'php5-ldap',
            'libapache2-mod-php5']:
                ensure => present;
        }
    }

    # common packages that exist in jessie/stretch
    package { [
        'python-pygments',
        'python-phabricator',
        'apachetop',
        'subversion',
        'heirloom-mailx']:
            ensure => present;
    }

    $docroot = "${phabdir}/phabricator/webroot"

    $phab_servername = hiera('phabricator_servername', $phab_settings['phabricator.base-uri'])

    httpd::site { 'phabricator':
        content => template('phabricator/phabricator-default.conf.erb'),
        require => $base_requirements,
    }

    # git.wikimedia.org hosts rewrite rules to redirect old gitblit urls to
    # equivilent diffusion urls.

    $gitblit_servername = $phab_settings['gitblit.hostname']

    file { '/srv/git.wikimedia.org':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
    }

    httpd::site { 'git.wikimedia.org':
        content => template('phabricator/gitblit_vhost.conf.erb'),
        require => File['/srv/git.wikimedia.org'],
    }

    # Robots.txt disallowing to crawl the alias domain
    if $serveraliases {
        file {"${phabdir}/robots.txt":
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => "User-agent: *\nDisallow: /\n",
        }
    }

    scap::target { $deploy_target:
        deploy_user => $deploy_user,
        key_name    => 'phabricator',
        require     => File['/usr/local/sbin/phab_deploy_finalize'],
        sudo_rules  => [
            'ALL=(root) NOPASSWD: /usr/local/sbin/phab_deploy_promote',
            'ALL=(root) NOPASSWD: /usr/local/sbin/phab_deploy_rollback',
            'ALL=(root) NOPASSWD: /usr/local/sbin/phab_deploy_finalize',
        ],
    }

    file { $phabdir:
        ensure  => 'link',
        target  => $deploy_root,
        require => Package[$deploy_target],
    }

    file { "${phabdir}/phabricator/scripts/":
        mode    => '0754',
        recurse => true,
        before  => File["${phabdir}/phabricator/scripts/mail/"],
        require => $base_requirements,
    }

    file { "${phabdir}/phabricator/scripts/mail/":
        mode    => '0755',
        recurse => true,
        require => $base_requirements,
    }

    if os_version('debian >= stretch') {
        if !$enable_php_fpm {
          file { '/etc/php/7.2/apache2/conf.d/php.ini':
              content => template('phabricator/php72.ini.erb'),
              notify  => Service['apache2'],
              require => Package['libapache2-mod-php7.2'],
          }
        }
    }

    if os_version('debian == jessie') {
      file { '/etc/php5/apache2/php.ini':
          content => template('phabricator/php.ini.erb'),
          notify  => Service['apache2'],
          require => Package['libapache2-mod-php5'],
      }
    }

    file { '/etc/apache2/phabbanlist.conf':
        source  => 'puppet:///modules/phabricator/apache/phabbanlist.conf',
        notify  => Service['apache2'],
        require => Package['apache2'],
    }

    file { $confdir:
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { "${confdir}/local":
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { "${confdir}/local/local.json":
        content => template('phabricator/local.json.erb'),
        require => $base_requirements,
        owner   => 'root',
        group   => 'www-data',
        mode    => '0644',
    }

    file { '/usr/local/sbin/phab_deploy_promote':
        content => template('phabricator/deployment/phab_deploy_promote.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0700',
    }

    file { '/usr/local/sbin/phab_deploy_finalize':
        content => template('phabricator/deployment/phab_deploy_finalize.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0700',
    }

    file { '/usr/local/sbin/phab_deploy_rollback':
        content => template('phabricator/deployment/phab_deploy_rollback.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0700',
    }


    if !empty($conf_files) {
        create_resources(phabricator::conf_env, $conf_files)
    }

    #default location for phabricator tracked repositories
    if ($phab_settings['repository.default-local-path']) {
        $repo_root = $phab_settings['repository.default-local-path']
        file { $repo_root:
            ensure => directory,
            mode   => '0755',
            owner  => 'phd',
            group  => 'www-data',
        }
        file { "${deploy_root}/repos":
            ensure  => 'link',
            target  => $repo_root,
            require => $base_requirements,
        }
    }

    file { '/usr/local/bin/arc':
        ensure  => 'link',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        target  => '/srv/phab/arcanist/bin/arc',
        require => $base_requirements,
    }

    class { '::phabricator::vcs':
        basedir  => $phabdir,
        settings => $phab_settings,
        require  => $base_requirements,
    }

    class { '::phabricator::phd':
        basedir  => $phabdir,
        settings => $phab_settings,
        require  => $base_requirements,
    }

    # phd service is only running on active server set in Hiera
    # will be changed after cluster setup is finished
    $phabricator_active_server = hiera('phabricator_active_server')
    if $::hostname == $phabricator_active_server {
        $phd_service_ensure = 'running'
    } else {
        $phd_service_ensure = 'stopped'
    }

    systemd::service { 'phd':
        ensure         => 'present',
        content        => systemd_template('phd'),
        require        => $base_requirements,
        service_params => {
            ensure     => $phd_service_ensure,
            hasrestart => true,
        },
    }
}
