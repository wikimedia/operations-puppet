# yubikey-val - One-Time Password (OTP) validation server for YubiKey tokens
class yubiauth::yubikey_val()
{
    require_package('yubikey-val')

    file { 'ykval-config':
        mode    => '0444',
        owner   => root,
        group   => root,
        path    => '/etc/yubico/val/ykval-config.php',
        content => template('yubiauth/ykval-config.erb'),
    }

    service { 'ykval-queue':
        enable  => true,
    }
}
