0ac117e050b8233df19b0abb265b4bbdb8107414# == Class: phabricator
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
# [*mysql_admin_user*]
#   Specify to use a different user for schema upgrades and database maintenance
#   Requires: mysql_admin_pass
#
# [*mysql_admin_pass*]
#   Specify to use a different password for schema upgrades and database maintenance
#   Requires: mysql_admin_user
#
# [*auth_type*]
#   Specify a template to match the provided login mechanisms
#
# [*libext_tag*]
#   Track extension revision
#
# [*extension_tag*]
#   Track extension revision
#
# [*extensions*]
#   Array of extensions to load
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
# See README for post install instructions
#

class phabricator (
    $phabdir          = '/srv/phab',
    $timezone         = 'UTC',
    $lock_file        = '',
    $git_tag          = 'HEAD',
    $libext_tag       = '',
    $libraries        = {},
    $extension_tag    = '',
    $extensions       = [],
    $settings         = {},
    $mysql_admin_user = '',
    $mysql_admin_pass = '',
    $serveradmin      = '',
    $auth_type        = '',
) {

    include phabricator::migration

    #A combination of static and dynamic conf parameters must be merged
    $module_path = get_module_path($module_name)
    $fixed_settings = loadyaml("${module_path}/data/fixed_settings.yaml")

    #per stdlib merge the dynamic settings will take precendence for conflicts
    $phab_settings = merge($fixed_settings, $settings)

    # depending on what type of auth we use (SUL,LDAP,both,others) we change
    # which template we use for the login message
    case $auth_type {
        'local':  { $auth_template = 'auth_log_message_local.erb' }
        'sul':  { $auth_template = 'auth_log_message_sul.erb' }
        'dual': { $auth_template = 'auth_log_message_dual.erb'}
        default: { fail ('please set an auth type for the login message') }
    }

    $phab_settings['auth.login-message'] = template("phabricator/${auth_template}")

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

    package { [
        'python-phabricator',
        'php5',
        'php5-mysql',
        'php5-gd',
        'php-apc',
        'php5-mailparse',
        'php5-dev',
        'php5-curl',
        'php5-cli',
        'php5-json',
        'php5-ldap']:
            ensure => present;
    }

    include apache::mod::php5
    include apache::mod::rewrite
    include apache::mod::headers

    $docroot = "${phabdir}/phabricator/webroot"
    $phab_servername = $phab_settings['phabricator.base-uri']
    apache::site { 'phabricator':
        content => template('phabricator/phabricator-default.conf.erb'),
    }

    file { $phabdir:
        ensure => directory,
    }

    git::install { 'phabricator/libphutil':
        directory => "${phabdir}/libphutil",
        git_tag   => $git_tag,
        lock_file => $lock_file,
        before    => Git::Install['phabricator/arcanist'],
    }

    git::install { 'phabricator/arcanist':
        directory => "${phabdir}/arcanist",
        git_tag   => $git_tag,
        lock_file => $lock_file,
        before    => Git::Install['phabricator/phabricator'],
    }

    git::install { 'phabricator/phabricator':
        directory => "${phabdir}/phabricator",
        git_tag   => $git_tag,
        lock_file => $lock_file,
        notify    => Exec["ensure_lock_${lock_file}"],
    }

    if ($libext_tag) {

        file { "${phabdir}/libext":
            ensure => 'directory',
        }

        $phab_settings['load-libraries'] = $libraries

        $libext_lock_path = "${phabdir}/library_lock_${libext_tag}"

        phabricator::libext { 'Sprint':
            rootdir          => $phabdir,
            libext_tag       => $libext_tag,
            libext_lock_path => $libext_lock_path,
        }
    }

    if ($extension_tag) {

        $ext_lock_path = "${phabdir}/extension_lock_${extension_tag}"

        git::install { 'phabricator/extensions':
            directory => "${phabdir}/extensions",
            git_tag   => $extension_tag,
            lock_file => $ext_lock_path,
            notify    => Exec[$ext_lock_path],
            before    => Git::Install['phabricator/phabricator'],
        }

        exec {$ext_lock_path:
            command => "touch ${ext_lock_path}",
            unless  => "test -z ${ext_lock_path} || test -e ${ext_lock_path}",
            path    => '/usr/bin:/bin',
        }

        phabricator::extension { $extensions:
            rootdir => $phabdir,
            require => Git::Install['phabricator/extensions'],
        }

    }

    #we ensure lock exists if string is not null
    exec {"ensure_lock_${lock_file}":
        command => "touch ${lock_file}",
        unless  => "test -z ${lock_file} || test -e ${lock_file}",
        path    => '/usr/bin:/bin',
    }

    case $::operatingsystemrelease {
        '12.04': { $php_ini = '/etc/php5/apache2filter/php.ini' }
        default: { $php_ini = '/etc/php5/apache2/php.ini'}
    }

    file { $php_ini:
        content => template("phabricator/${lsbdistcodename}_php.ini.erb"),
        notify  => Service['apache2'],
        require => Package['php5'],
    }

    file { "${phabdir}/phabricator/conf/local/local.json":
        content => template('phabricator/local.json.erb'),
        require => Git::Install['phabricator/phabricator'],
        notify  => Service[apache2],
    }

    #default location for phabricator tracked repositories
    file { $phab_settings['repository.default-local-path']:
        ensure  => directory,
        owner   => 'www-data',
        group   => 'www-data',
        require => Git::Install['phabricator/phabricator'],
    }

    file { '/usr/local/sbin/phab_update_tag':
        content => template('phabricator/phab_update_tag.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0500',
    }

    # Phabricator needs an initial index built and from there
    # will update as appropriate.
    if ($phab_settings['search.elastic.host']) {
        $create_index = "${phabdir}/phabricator/bin/search index --all"
        exec { 'elastic_search_setup':
            command   => "${create_index} && touch ${phabdir}/needs_es_indexed_false",
            creates   => "${phabdir}/needs_es_indexed_false",
            logoutput => true,
            require   => File["${phabdir}/phabricator/conf/local/local.json"],
        }
    }

    #https://secure.phabricator.com/book/phabricator/article/managing_daemons/
    $phd = "${phabdir}/phabricator/bin/phd"
    service { 'phd':
        ensure   => running,
        provider => base,
        binary   => $phd,
        start    => "${phd} start",
        stop     => "${phd} stop",
        status   => "${phd} status",
        require  => Git::Install['phabricator/phabricator'],
    }
}

define phabricator::extension($rootdir='/') {
    file { "${rootdir}/phabricator/src/extensions/${name}":
        ensure => link,
        target => "${rootdir}/extensions/${name}",
    }
}

define phabricator::redirector($mysql_user, $mysql_pass, $mysql_host, $rootdir='/') {
    file { "${rootdir}/phabricator/support/preamble.php":
        source => 'puppet:///modules/phabricator/preamble.php'
        require => File["${rootdir}/phabricator/support/redirect_config.json"]
    }

    file { "${rootdir}/phabricator/support/redirect_config.json":
        content => template('phabricator/redirect_config.json.erb')
    }
}
