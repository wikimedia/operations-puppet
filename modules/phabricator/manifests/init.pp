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
#   A php.ini compatible timezone
#   http://www.php.net//manual/en/datetime.configuration.php
#
# [*lock_file*]
#   The path on disk to place a file for holding a tag
#   in the repos until the phab_update_tag command is run by root.
#
# [*git_tag*]
#   The tag in the Phabricator repos to maintain.
#
#    NOTE:
#
#    If the lockfile is set this tag will not be honored by an existing
#    install until the phab_update_tag command is run.  This needs to be an
#    interactive and monitored process to allow for the necessary DB and
#    schema changes.
#
#    For more info on tag forwarding see git::install
#
# [*settings*]
#   A hash of configuration options for the local settings json file.
#   https://secure.phabricator.com/book/phabricator/article/advanced_configuration/#configuration-sources
#
# === Examples
#
#  class { 'phabricator':
#    git_tag   => 'demo',
#    lock_file => '/var/run/phab_repo_lock',
#     settings  => {
#      'phabricator.base-uri' => 'http://myurl.domain',
#    },
#  }
#
# Navigate to base-uri for post install setup
#

class phabricator (
    $phabdir    = '/srv/phab',
    $timezone   = 'America/Los_Angeles',
    $lock_file  = '',
    $git_tag    = 'HEAD',
    $settings   = {},
) {

    #A combination of static and dynamic conf parameters must be merged
    $module_path = get_module_path($module_name)
    $fixed_settings = loadyaml("${module_path}/data/fixed_settings.yaml")
    #per stdlib merge the dynamic settings will take precendence for conflicts
    $phab_settings = merge($fixed_settings, $settings)

    package {
        ['git-core', 'php5', 'php5-mysql', 'php5-gd', 'php-apc',
         'php5-dev', 'php5-curl', 'php5-cli', 'php5-json', 'php5-ldap']:
            ensure => present;
    }

    include apache::mod::rewrite

    $phab_fqdn = regsubst($phab_settings['phabricator.base-uri'], 'http://', '')
    apache::site { $phab_fqdn:
        template => 'phabricator/phabricator-default.conf.erb',
    }

    git::install { 'phabricator/libphutil':
        directory  => "${phabdir}/libphutil",
        git_tag    => $git_tag,
        lock_file  => $lock_file,
        before     => Git::Install['phabricator/arcanist'],
    }

    git::install { 'phabricator/arcanist':
        directory  => "${phabdir}/arcanist",
        git_tag    => $git_tag,
        lock_file  => $lock_file,
        before     => Git::Install['phabricator/phabricator'],
    }

    git::install { 'phabricator/phabricator':
        directory => "${phabdir}/phabricator",
        git_tag    => $git_tag,
        lock_file  => $lock_file,
        notify     => Exec["ensure_lock_${lock_file}"],
    }

    #we ensure lock exists if string is not null
    exec {"ensure_lock_${lock_file}":
        command     => "touch ${lock_file}",
        unless      => "test -z ${lock_file} || test -e ${lock_file}",
        path        => '/usr/bin:/bin',
    }

    file { '/etc/php5/apache2filter/php.ini':
        content => template('phabricator/php.ini.erb'),
        notify  => Service[apache2],
    }

    file { '/srv/phab/phabricator/conf/local/local.json':
        content => template('phabricator/local.json.erb'),
        require => Git::Install['phabricator/phabricator'],
    }

    #default location for phabricator tracked repositories
    file { $phab_settings['repository.default-local-path']:
        ensure => directory,
        owner  => www-data,
        group  => www-data,
        require => Git::Install['phabricator/phabricator'],
    }

    file { '/usr/local/sbin/phab_update_tag':
        content => template('phabricator/phab_update_tag.erb'),
        owner  => root,
        group  => root,
        mode   => '0500',
    }

    #https://secure.phabricator.com/book/phabricator/article/managing_daemons/
    $phd = "/srv/phab/phabricator/bin/phd"
    service { 'phd':
        ensure   => running,
        provider => base,
        binary   => $phd,
        start    => "${phd} start",
        stop     => "${phd} stop",
        status   => "${phd} status",
        require => Git::Install['phabricator/phabricator'],
    }
}
