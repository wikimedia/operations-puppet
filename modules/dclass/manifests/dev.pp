# == Class dclass::dev
# Installs libdclass0-dev development header package
#
class dclass::dev {
    require dclass

    package { 'libdclass0-dev': ensure => 'installed' }
}