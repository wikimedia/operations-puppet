# == Class: phabricator
#
# Phabricator is a collection of open source web applications
# that help software companies build better software.
#
# Phabricator has forked into Phorge. (https://we.phorge.it/)
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
# [*config_deploy_vars*]
#     Variables used by scap3 during config deployment.
#
# [*manage_scap_user*]
#     Specify whether to create a User resource for the $deploy_user.
#     This should be set to false if you have defined the user elsewhere.
#     Default: true
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
# [*serveraliases*]
#     Alternative domains on which to respond too
#
# [*deploy_user*]
#     The username that is used for scap deployments
#
# [*deploy_target*]
#     The name of the scap3 deployment repo, e.g. phabricator/deployment
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
#
class phabricator (
    Stdlib::Unixpath        $phabdir            = '/srv/phab',
    Stdlib::Unixpath        $confdir            = '/srv/phab/phabricator/conf',
    String                  $timezone           = 'UTC',
    Array                   $trusted_proxies    = [],
    Array                   $libraries          = [],
    Hash                    $settings           = {},
    Hash                    $config_deploy_vars = {},
    String                  $mysql_admin_user   = '',
    String                  $mysql_admin_pass   = '',
    String                  $serveradmin        = '',
    Array                   $serveraliases      = [],
    String                  $deploy_user        = undef,
    String                  $deploy_target      = 'phabricator/deployment',
    Integer                 $opcache_validate   = 0,
    Stdlib::Ensure::Service $phd_service_ensure = running,
    Boolean                 $phd_service_enable = true,
    Boolean                 $manage_scap_user   = undef,
    Boolean                 $enable_vcs         = undef,
) {
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

    # First installs can trip without this
    exec {'apt_update_php':
        command     => '/usr/bin/apt-get update',
        refreshonly => true,
        logoutput   => true,
    }

    if debian::codename::ge('bullseye') {
        $python_phab_package = 'python3-phabricator'
    } else {
        $python_phab_package = 'python-phabricator'
    }

    package { [
        'python3-pygments',
        $python_phab_package,
        'apachetop',
        'subversion',
        's-nail']:
            ensure => present;
    }

    $docroot = "${phabdir}/phabricator/webroot"

    $phab_servername = $phab_settings['phabricator.base-uri']

    httpd::site { 'phabricator':
        content => template('phabricator/phabricator-default.conf.erb'),
        require => $base_requirements,
    }

    class { '::phabricator::config':
        phabdir            => $phabdir,
        deploy_root        => $deploy_root,
        deploy_user        => $deploy_user,
        deploy_target      => $deploy_target,
        manage_scap_user   => $manage_scap_user,
        config_deploy_vars => $config_deploy_vars,
        storage_user       => $storage_user,
        storage_pass       => $storage_pass,
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
    }

    file { '/usr/local/bin/arc':
        ensure  => link,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        target  => '/srv/phab/arcanist/bin/arc',
        require => $base_requirements,
    }

    if $enable_vcs {

        class { '::phabricator::vcs':
            basedir     => $phabdir,
            phd_log_dir => $fixed_settings['phd.log-directory'],
            phd_user    => $fixed_settings['phd.user'],
            vcs_user    => $fixed_settings['diffusion.ssh-user'],
            require     => $base_requirements,
        }
    }

    class { '::phabricator::phd':
        basedir     => $phabdir,
        phd_user    => $fixed_settings['phd.user'],
        phd_log_dir => $fixed_settings['phd.log-directory'],
        require     => $base_requirements,
    }

    systemd::service { 'phd':
        ensure         => present,
        content        => systemd_template('phd'),
        require        => Class['::phabricator::phd'],
        service_params => {
            ensure     => $phd_service_ensure,
            enable     => $phd_service_enable,
            hasrestart => true,
        },
    }
}
