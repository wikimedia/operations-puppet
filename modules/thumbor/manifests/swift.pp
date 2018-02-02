# == Define: thumbor::swift
#
# Sets up Thumbor's result storage to write to a Swift cluster.
#
# === Parameters
#
# [*name*]
#   Service port.
#    $swift_key,
#    $swift_account = 'thumbor',
#    $swift_user = 'thumbor',
#    $swift_sharded_containers = [],
#    $swift_private_containers = [],
#    $swift_private_containers_secret,
#    $swift_host = "https://ms-fe.svc.${::site}.wmnet",
#
# === Examples
#
#   thumbor::instance { '8888':
#   }
#

class thumbor::swift (
    $swift_key,
    $swift_account = 'mw',
    $swift_user = 'thumbor',
    $swift_sharded_containers = [],
    $swift_private_containers = [],
    $swift_private_containers_secret = '',
    $swift_host = "https://ms-fe.svc.${::site}.wmnet",
) {
    file { '/etc/thumbor.d/80-thumbor-swift.conf':
        ensure  => present,
        owner   => 'thumbor',
        group   => 'thumbor',
        mode    => '0440',
        content => template('thumbor/swift.conf.erb'),
        require => Package['python-thumbor-wikimedia'],
        notify  => Service['thumbor-instances'],
    }
}
