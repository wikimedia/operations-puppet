# WARNING: TOTALLY DEPRECATED, DO NOT USE
#  Install Mediawiki from git and then leave it alone.
#
#  Uses the mediawiki_singlenode class with no alterations or customizations.
class role::deprecated::mediawiki::install {

    requires_realm('labs')

    include ::memcached

    class { 'mediawiki_singlenode':
        ensure => present,
    }
}
