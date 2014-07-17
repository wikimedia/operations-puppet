class mediawiki::packages::hhvm {
    package { ['hhvm', 'hhvm-luasandbox', 'hhvm-fss', 'hhvm-wikidiff2']:
        # For now, we want to always install the latest and the shiniest
        ensure => latest
    }
}
