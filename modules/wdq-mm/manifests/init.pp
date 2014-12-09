# == Class: wdq-mm
# 
# Class for setting up an instance of Magnus' WDQ
class wdq-mm {
    package { 'wdq-mm':
        ensure => latest,
    }

    service { 'wdq-mm':
        ensure  => running,
        require => Package['wdq-mm'],
    }
}
