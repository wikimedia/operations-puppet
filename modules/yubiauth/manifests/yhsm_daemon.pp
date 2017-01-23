# yhsm-daemon - Allow multiple users of a YubiHSM
class yubiauth::yhsm_daemon(
    $yhsmdevice = '/dev/ttyACM0',
) {

    require_package('yhsm-daemon')

    file { 'yhsm-daemon-default':
        mode    => '0440',
        owner   => 'root',
        group   => 'root',
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





