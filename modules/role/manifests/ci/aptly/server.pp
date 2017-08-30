# == Class role::ci::aptly::server
#
class role::ci::aptly::server {

    include role::labs::lvm::srv
    class { '::aptly':
        require => Class['role::labs::lvm::srv'],
    }

    ::aptly::repo { 'Port of Zend PHP 5.5 to Jessie':
        distribution => 'jessie',
        component    => 'php55',
        publish      => true,
    }

}
