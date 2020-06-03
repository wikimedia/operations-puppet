# == systemd::sysuser ==
#
# This define creates a system user using systemd-sysusers.
#
# Example:
# systemd::sysuser { 'food':
#    content => 'u  food   - "foo daemon"  -  -'
# }
#
# This allocates the next available UID and creates a "foo" system
# user with the home set to /root and nologin as the shell.
# See the sysusers.d manpage for the full syntax.
#
define systemd::sysuser(
    Array[Systemd::Sysuser::Config] $content,
    Wmflib::Ensure $ensure=present,
){
    require systemd

    $safe_title = regsubst($title, '[\W_/]', '-', 'G')
    $conf_path = "/etc/sysusers.d/${safe_title}.conf"

    $_content = $content.reduce('') |$memo, $v| {
        "${memo}${v['usertype']}\t${v['name']}\t${v['id']}\t${v['gecos']}\t${v['home_dir']}\t${v['shell']}\n"
    }

    file { $conf_path:
        ensure  => $ensure,
        content => $_content,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
    }

    exec { 'Refresh sysusers':
        command     => '/bin/systemd-sysusers',
        user        => 'root',
        refreshonly => true,
        subscribe   => File[$conf_path],
    }
}
