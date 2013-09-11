# == Class dclass::data
#
class dclass::data {
    require dclass

    # Used for mobile device classification in Kraken:
    package { 'libdclass-data': ensure => 'installed' }
}