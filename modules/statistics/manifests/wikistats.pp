# == Class statistics::wikistats
# wikistats configuration for generating
# stats.wikimedia.org data.
#
# TODO: puppetize clone of wikistats?
class statistics::wikistats {
    Class['::statistics'] -> Class['::statistics::wikistats']

    # Perl packages needed for wikistats
    package { [
        'libjson-xs-perl',
        'libtemplate-perl',
        'libnet-patricia-perl',
        'libregexp-assemble-perl',
    ]:
        ensure => 'installed',
    }
    # this cron uses pigz to unzip squid archive files in parallel
    package { 'pigz':
        ensure => 'installed',
    }
}
