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
# [*lock_file*]
#     The path on disk to place a file for holding a tag
#     in the repos until the phab_update_tag command is run by root.
#
# [*git_tag*]
#     The tag in the Phabricator repos to maintain.
#
#    NOTE:
#
#    If the lockfile is set this tag will not be honored by an existing
#    install until the phab_update_tag command is run.    This needs to be an
#    interactive and monitored process to allow for the necessary DB and
#    schema changes.
#
#    For more info on tag forwarding see git::install
#
# [*settings*]
#     A hash of configuration options for the local settings json file.
#     https://secure.phabricator.com/book/phabricator/article/advanced_configuration/#configuration-sources
#
# [*mysql_admin_user*]
#     Specify to use a different user for schema upgrades and database maintenance
#     Requires: mysql_admin_pass
#
# [*mysql_admin_pass*]
#     Specify to use a different password for schema upgrades and database maintenance
#     Requires: mysql_admin_user
#
# [*sprint_tag*]
#     Track sprint app by tag
#
# [*security_tag*]
#     Track security extension by tag
#
# [*extension_tag*]
#     Track generic / small extensions by tag
#
# [*extensions*]
#     Array of extensions to load
#
# [*serveralias*]
#     Alternative domain on which to respond too
#
# === Examples
#
#    class { 'phabricator':
#        git_tag     => 'demo',
#        lock_file => '/var/run/phab_repo_lock',
#        settings    => {
#            'phabricator.base-uri' => 'http://myurl.domain',
#        },
#    }
#
# See README for post install instructions
#

class phabricator (
    $phabdir          = '/srv/phab',
    $timezone         = 'UTC',
    $trusted_proxies  = [],
    $lock_file        = '',
    $git_tag          = 'HEAD',
    $sprint_tag       = '',
    $security_tag     = '',
    $libraries        = [],
    $extension_tag    = '',
    $extensions       = [],
    $settings         = {},
    $mysql_admin_user = '',
    $mysql_admin_pass = '',
    $serveradmin      = '',
    $serveralias      = '',
) {


    #A combination of static and dynamic conf parameters must be merged
    $module_path = get_module_path($module_name)
    $fixed_settings = loadyaml("${module_path}/data/fixed_settings.yaml")

    #per stdlib merge the dynamic settings will take precendence for conflicts
    $phab_settings = merge($fixed_settings, $settings)

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
        'python-pygments',
        'python-phabricator',
        'php5-mysql',
        'php5-gd',
        'php-apc',
        'php5-mailparse',
        'php5-dev',
        'php5-curl',
        'php5-cli',
        'php5-json',
        'php5-ldap',
        'apachetop',
        'subversion']:

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

    # Robots.txt disallowing to crawl the alias domain
    if $serveralias {
        file {"${phabdir}/robots.txt":
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => "User-agent: *\nDisallow: /\n",
        }
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
        before    => File["${phabdir}/phabricator/.git/config"],
    }

    file { "${phabdir}/phabricator/.git/config":
        source => 'puppet:///modules/phabricator/phabricator.gitconfig',
        before => File["${phabdir}/phabricator/scripts/"],
    }

    file { "${phabdir}/phabricator/scripts/":
        mode    => '0754',
        recurse => true,
        before  => File["${phabdir}/phabricator/scripts/mail/"],
    }

    file { "${phabdir}/phabricator/scripts/mail/":
        mode    => '0755',
        recurse => true,
    }

    if ($libraries) {
        file { "${phabdir}/libext":
            ensure => 'directory',
        }

        $phab_settings['load-libraries'] = $libraries
        $libext_lock_path = "${lock_file}_libext"
    }

    # Would love to do these as an array but the sprint vs Sprint
    # case issue makes this complicated at the moment.
    if ($sprint_tag) {
        phabricator::libext { 'Sprint':
            rootdir          => $phabdir,
            libext_tag       => $sprint_tag,
            libext_lock_path => $libext_lock_path,
        }

    }

    if ($security_tag) {
        phabricator::libext { 'security':
            rootdir          => $phabdir,
            libext_tag       => $security_tag,
            libext_lock_path => $libext_lock_path,
        }
    }

    if ($extension_tag) {
        $ext_lock_name = regsubst($extension_tag, '\W', '-', 'G')
        $ext_lock_path = "${phabdir}/extension_lock_${ext_lock_name}"
        git::install { 'phabricator/extensions':
            directory => "${phabdir}/extensions",
            git_tag   => $extension_tag,
            lock_file => $ext_lock_path,
            notify    => Exec[$ext_lock_path],
            before    => Git::Install['phabricator/phabricator'],
        }

        file { "${phabdir}/phabricator/src/extensions":
            ensure  => 'directory',
            path    => "${phabdir}/phabricator/src/extensions",
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
            require => [
                        Git::Install['phabricator/extensions'],
                        Git::Install['phabricator/phabricator'],
                    ],
        }

        exec {$ext_lock_path:
            command => "touch ${ext_lock_path}",
            unless  => "test -z ${ext_lock_path} || test -e ${ext_lock_path}",
            path    => '/usr/bin:/bin',
        }

        phabricator::extension { $extensions:
            rootdir => $phabdir,
            require => File["${phabdir}/phabricator/src/extensions"],
        }

    }

    #we ensure lock exists if string is not null
    exec {"ensure_lock_${lock_file}":
        command => "touch ${lock_file}",
        unless  => "test -z ${lock_file} || test -e ${lock_file}",
        path    => '/usr/bin:/bin',
    }

    file { '/etc/php5/apache2/php.ini':
        content => template('phabricator/php.ini.erb'),
        notify  => Service['apache2'],
        require => Package['libapache2-mod-php5'],
    }

    file { '/etc/apache2/phabbanlist.conf':
        content => template('phabricator/phabbanlist.conf.erb'),
        require => Package['libapache2-mod-php5'],
        notify  => Service['apache2'],
    }

    file { "${phabdir}/phabricator/conf/local/local.json":
        content => template('phabricator/local.json.erb'),
        require => Git::Install['phabricator/phabricator'],
    }

    # ^Disable PHD autorestart until:
    # https://secure.phabricator.com/T7475
    # notify  => Service[phd],

    #default location for phabricator tracked repositories
    if ($phab_settings['repository.default-local-path']) {
        file { $phab_settings['repository.default-local-path']:
            ensure  => directory,
            mode    => '0755',
            owner   => 'phd',
            group   => 'www-data',
            require => Git::Install['phabricator/phabricator'],
        }
    }

    file { '/usr/local/sbin/phab_update_tag':
        content => template('phabricator/phab_update_tag.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0500',
    }

    file { '/usr/local/bin/arc':
        ensure  => 'link',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        target  => '/srv/phab/arcanist/bin/arc',
        require => Git::Install['phabricator/arcanist'],
    }

    class { 'phabricator::vcs':
        basedir  => $phabdir,
        settings => $phab_settings,
    }

    class { 'phabricator::phd':
        basedir  => $phabdir,
        settings => $phab_settings,
        before   => Service['phd'],
    }

    # This needs to become Upstart managed
    # https://secure.phabricator.com/book/phabricator/article/managing_daemons/
    # Meanwhile upstream has a bug to make an LSB friendly wrapper
    # https://secure.phabricator.com/T8129
    service { 'phd':
        ensure     => running,
        start      => '/usr/sbin/service phd start --force',
        status     => '/usr/bin/pgrep -f phd-daemon',
        hasrestart => true,
        require    => Git::Install['phabricator/phabricator'],
    }
}
