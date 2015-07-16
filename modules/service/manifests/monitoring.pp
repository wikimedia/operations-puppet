# === Class service::monitoring
#
# this is intended to include all shared resources used for monitoring
# services defined via service::node

class service::monitoring {
    require_package 'python-yaml', 'python-urllib3'

    file { '/usr/local/lib/nagions/plugins/service_checker':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => '0555',
        source => 'puppet:///modules/service/checker.py',
    }
}
