class yubiauth::yhsm_daemon(
) {

    require_package('yhsm-daemon')

    file { 'yhsm-daemon-default':
        mode    => '0440',
        owner   => root,
        group   => root,
        path    => '/etc/default/yhsm-daemon',
        content => template('yubiauth/yhsm-daemon-default.erb'),
    }

    service { 'yhsm-daemon':
        enable  => true,
        require => [
                    Package['yhsm-daemon'],
                    File['/etc/default/yhsm-daemon'],
                    ],
    }
}





