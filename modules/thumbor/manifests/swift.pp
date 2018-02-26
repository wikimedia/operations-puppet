# == Define: thumbor::swift
#
# Sets up Thumbor's result storage to write to a Swift cluster.
#
# === Parameters
#
# [*name*]
#   Service port.
#    $swift_key = '',
#    $swift_account = 'thumbor',
#    $swift_user = 'thumbor',
#    $swift_private_key = '',
#    $swift_private_account = 'thumbor',
#    $swift_private_user = 'thumbor-private',
#    $swift_sharded_containers = [],
#    $swift_private_containers = [],
#    $thumbor_mediawiki_shared_secret,
#    $swift_host = "https://ms-fe.svc.${::site}.wmnet",
#
# === Examples
#
#   thumbor::instance { '8888':
#   }
#

class thumbor::swift (
    $swift_key = '',
    $swift_account = 'mw',
    $swift_user = 'thumbor',
    $swift_private_key = '',
    $swift_private_account = 'mw',
    $swift_private_user = 'thumbor-private',
    $swift_sharded_containers = [],
    $swift_private_containers = [],
    $thumbor_mediawiki_shared_secret = '',
    $swift_host = "https://ms-fe.svc.${::site}.wmnet",
) {
    file { '/etc/thumbor.d/80-thumbor-swift.conf':
        ensure  => present,
        owner   => 'thumbor',
        group   => 'thumbor',
        mode    => '0440',
        content => template('thumbor/swift.conf.erb'),
        require => Package['python-thumbor-wikimedia'],
    }

    file { '/etc/thumbor.d/80-thumbor-swift-secret.conf':
        ensure    => present,
        owner     => 'thumbor',
        group     => 'thumbor',
        mode      => '0440',
        content   => template('thumbor/swift-secret.conf.erb'),
        require   => Package['python-thumbor-wikimedia'],
        show_diff => false,
    }
}
