class phabricator (
    $phabdir = '/srv/phab',
    $timezone = 'America/Los_Angeles',
    $settings = {},
) {


    if has_key($settings, 'mysql.host') {
        $mysql_server = $settings['mysql.host']
        if $mysql_server == 'localhost' {
            #TEMP FOR LOCALTESTING
            #SET: sql_mode=STRICT_ALL_TABLES
            #package { 'mysql-server': ensure => present }
            #->
            class { 'mysql::config':
                root_password => $settings['mysql.pass'],
            }
        }
    }

    #needed for git::clone
    package { 'git-core': ensure => present }

    package { 'php5':       ensure => present }
    package { 'php5-mysql': ensure => present }
    package { 'php5-gd':    ensure => present }
    package { 'php5-dev':   ensure => present }
    package { 'php5-curl':  ensure => present }

    package { 'php5-cli':   ensure => present }
    package { 'php5-json':  ensure => present }

    #php-apc and not php5-apc ?
    package { 'php-apc':   ensure => present }

    package { 'apache2':   ensure => present }

    apache_module { 'mod_rewrite': name => 'rewrite' }

    git::clone { 'libphutil':
        directory => "${phabdir}/libphutil",
        branch    => 'master',
        origin    => 'https://gerrit.wikimedia.org/r/phabricator/libphutil.git'
    }

    # command line interface for Phabricator
    # https://secure.phabricator.com/book/arcanist/
    git::clone { 'arcanist':
        directory => "${phabdir}/arcanist",
        branch    => 'master',
        origin    => 'https://gerrit.wikimedia.org/r/phabricator/arcanist.git'
    }

    # open software engineering platform and fun adventure game
    # http://phabricator.org/
    git::clone { 'phabricator':
        directory => "${phabdir}/phabricator",
        branch    => 'master',
        origin    => 'https://gerrit.wikimedia.org/r/phabricator/phabricator.git'
    }


    file { '/etc/php5/apache2filter/php.ini':
        content => template('phabricator/php.ini.erb'),
        #source => 'puppet:///modules/phabricator/php.ini',
        notify => Service[apache2],
    }

    file { '/srv/phab/phabricator/conf/local/local.json':
        content => template('phabricator/local.json.erb'),
    }

    #default location for phab repos
    #repository.default-local-path	"/var/repo/"
    file { '/var/repo':
        ensure => directory,
        owner  => www-data,
        group  => www-data,
    }

    #default location for phab repos
    #repository.default-local-path	"/var/repo/"
    file { '/var/phabfiles':
        ensure => directory,
        owner  => www-data,
        group  => www-data,
    }

   #make these a puppet vars
   #set base uri in phab
   #./bin/config set phabricator.base-uri 'http://iridium.wikimedia.org/'
   #./bin/config set storage.upload-size-limit 5M

    service { 'apache2':
        ensure     => running,
        hasrestart => true,
        hasstatus  => true,
    }

    $phd = "/srv/phab/phabricator/bin/phd"
    service { 'phd':
        ensure     => running,
        provider   => base,
        binary => $phd,
        start => "${phd} start",
        stop => "${phd} stop",
        status => "${phd} status",
    }
}
