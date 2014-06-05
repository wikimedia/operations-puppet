#  Install the 'php5-mysql' package which will
#  include mysql and apache via dependencies.
class webserver::php5-mysql {

    include webserver::base

    package { 'php5-mysql':
        ensure => 'present',
        }
}

