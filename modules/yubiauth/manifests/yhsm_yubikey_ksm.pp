# yhsm-yubikey-ksm - Yubikey key storage module using a YubiHSM
class yubiauth::yhsm_yubikey_ksm(
    $yhsmdevice = '/dev/ttyACM0',
) {

    require_package('yhsm-yubikey-ksm')

    file { 'yhsm-yubikey-ksm-default':
        mode    => '0440',
        owner   => 'root',
        group   => 'root',
        path    => '/etc/default/yhsm-yubikey-ksm',
        content => template('yubiauth/yhsm-yubikey-ksm-default.erb'),
    }

    service { 'yhsm-yubikey-ksm':
        enable  => true,
        require => [
                    Package['yhsm-yubikey-ksm'],
                    File['/etc/default/yhsm-yubikey-ksm'],
                    ],
    }
}
