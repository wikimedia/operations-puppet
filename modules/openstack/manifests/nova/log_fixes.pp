# Allow unprivileged users to look at nova logs
class openstack::nova::log_fixes(
    $log_users = 'labnet-users',
    ) {

    file { '/var/log/nova':
        ensure  => 'directory',
        owner   => 'nova',
        group   => $log_users,
        mode    => '0750',
        require => Package['nova-common'],
    }
}
