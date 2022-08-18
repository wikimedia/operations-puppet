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
# [*config_deploy_vars*]
#     Variables used by scap3 during config deployment.
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

    package { [
        'python3-pygments',
        'python-phabricator',
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

    scap::target { $deploy_target:
        deploy_user => $deploy_user,
        key_name    => 'phabricator',
        manage_user => $manage_scap_user,
        require     => File['/usr/local/sbin/phab_deploy_finalize'],
        sudo_rules  => [
            'ALL=(root) NOPASSWD: /usr/local/sbin/phab_deploy_promote',
            'ALL=(root) NOPASSWD: /usr/local/sbin/phab_deploy_rollback',
            'ALL=(root) NOPASSWD: /usr/local/sbin/phab_deploy_finalize',
        ],
    }

    # Provide secrets and host-specific configuration that scap3 will use for
    # its config deploy templates
    file { '/etc/phabricator':
        ensure => 'directory',
        owner  => 'root',
        group  => $deploy_user,
        mode   => '0750',
    }

    file { '/etc/phabricator/config.yaml':
        ensure  => present,
        owner   => 'root',
        group   => $deploy_user,
        mode    => '0640',
        content => $config_deploy_vars.to_yaml(),
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

    file { '/usr/local/sbin/phab_deploy_promote':
        content => file('phabricator/phab_deploy_promote.sh'),
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
        content => file('phabricator/phab_deploy_rollback.sh'),
        owner   => 'root',
        group   => 'root',
        mode    => '0700',
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
        ensure  => 'link',
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
        ensure         => 'present',
        content        => systemd_template('phd'),
        require        => Class['::phabricator::phd'],
        service_params => {
            ensure     => $phd_service_ensure,
            hasrestart => true,
        },
    }

    # mysql read access for phab admins, in production (T238425)
    if $::realm == 'production' {
        $::admin::data['groups']['phabricator-admin']['members'].each |String $user| {
            file { "/home/${user}/.my.cnf":
                content => template('phabricator/my.cnf.erb'),
                owner   => $user,
                group   => 'root',
                mode    => '0440',
            }
        }
    }
}
