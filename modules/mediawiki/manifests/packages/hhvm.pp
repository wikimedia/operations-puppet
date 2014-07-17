# == Class: mediawiki::packages::hhvm
#
# Installs all the packages needed for a working hhvm installation.
#
# This class should be directly included wherever you need hhvm to run.
# It works on Trusty and newer distros.
#
class mediawiki::packages::hhvm {
    if versioncmp($::lsbdistrelease, '14.04') < 0 {
        fail('HHVM is requires Ubuntu 14.04+')
    }

    package { 'hhvm':
        ensure => latest,
    }

    package { [ 'hhvm-luasandbox', 'hhvm-fss', 'hhvm-wikidiff2' ]:
        ensure => latest,
    }
}
