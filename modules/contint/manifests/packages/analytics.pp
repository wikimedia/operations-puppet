# == class contint::packages::analytics
#
# Includes packages needed for building
# analytics and statistics related packages.
class contint::packages::analytics {

    # need geoip to build udp-filter
    include ::geoip

    # these are needed to build libanon and udp-filter
    package { ['pkg-config', 'libpcap-dev', 'libdb-dev']:
        ensure => 'installed',
    }

    # these packages are used by the tests for wikistats to parse the
    # generated reports to see if they are correct
    package { [
        'libhtml-treebuilder-xpath-perl',
        'libjson-xs-perl',
        'libnet-patricia-perl',
        'libtemplate-perl',
        'libweb-scraper-perl',
        ]:
        ensure => 'installed',
    }


}
