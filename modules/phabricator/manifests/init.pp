# puppet module for phabricator
#
# currently just tries to be a puppet translation of
# the upstream install script 'install_ubuntu.sh'
# compare it to:
# http://www.phabricator.com/rsrc/install/install_ubuntu.sh
#
class phabricator (
    $phabdir = '/srv/phab',
) {

    # dependencies for phabricator
    # packages installed by the upstream install script (install_ubuntu.sh)

    #package { 'mysql-server': ensure => present } # include a role instead
    #package { 'apache2':      ensure => present } # include webserver::php5 or other
    #package { 'dpkg-dev':     ensure => present } # not sure yet why

    ## PHP packages
    package { 'php5':       ensure => present }
    package { 'php5-mysql': ensure => present }
    package { 'php5-gd':    ensure => present }
    package { 'php5-dev':   ensure => present }
    package { 'php5-curl':  ensure => present }
    package { 'php5-apc':   ensure => present }
    package { 'php5-cli':   ensure => present }
    package { 'php5-json':  ensure => present }

    apache_module { 'mod_rewrite': name => 'rewrite' }

    # upstream install script installs pcntl, how do we puppetize this?
    # apt-get source php5 ; PHP5=`ls -1F | grep '^php5-.*/$'`
    # (cd $PHP5/ext/pcntl && phpize && ./configure && make && sudo make install)


    # a collection of PHP utility classes
    # https://secure.phabricator.com/book/libphutil/
    git::clone { 'libphutil':
        directory => "${phabdir}/libphutil",
        branch    => 'master',
        origin    => 'https://github.com/facebook/libphutil.git'
    }

    # command line interface for Phabricator
    # https://secure.phabricator.com/book/arcanist/
    git::clone { 'arcanist':
        directory => "${phabdir}/arcanist",
        branch    => 'master',
        origin    => 'https://github.com/facebook/arcanist.git'
    }

    # open software engineering platform and fun adventure game
    # http://phabricator.org/
    git::clone { 'phabricator':
        directory => "${phabdir}/phabricator",
        branch    => 'master',
        origin    => 'https://github.com/facebook/phabricator.git'
    }

