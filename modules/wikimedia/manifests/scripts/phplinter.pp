# vim: ts=2 sw=2 expandtab
# A fast PHP linter
#
# php does not let you recursively lint a directory since php -l only accepts
# one argument which must be a file.  People ends up having to find the list
# of php file and execute php -l on each of them, that means a full PHP
# initialization on each file which is slow.
# The linting script provided by this class accept a directory as argument,
# it will then recursively find PHP files and uses the php5-parsekit to verify
# the syntax. That saves us the PHP initialization overhead and is much faster.

class wikimedia::scripts::phplinter( $scriptpath = '/usr/local/bin' ) {

  package { 'php5-parsekit': ensure => present; }

  file {
    "${scriptpath}/lint":
      owner => root,
      group => root,
      mode => '0555',
      require => Package[ 'php5-parsekit' ], # bug 37076
      source => 'puppet:///modules/wikimedia/scripts/lint';
    "${scriptpath}/lint.php":
      owner => root,
      group => root,
      mode => '0555',
      require => Package[ 'php5-parsekit' ], # bug 37076
      source => 'puppet:///modules/wikimedia/scripts/lint.php';
  }

}
