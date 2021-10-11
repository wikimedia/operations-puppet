# @summary  This define creates a system user using systemd-sysusers.
#   This allocates the next available UID and creates a "foo" system
#   user with the home set to /root and nologin as the shell.
#   See the sysusers.d manpage for the full syntax.
# @example
# systemd::sysuser { 'foo':
#   usertype => 'user',
#   'foo daemon',
# }
define systemd::sysuser (
    Wmflib::Ensure             $ensure      = present,
    String                     $username    = $title,
    Systemd::Sysuser::Usertype $usertype    = 'user',
    Systemd::Sysuser::Id       $id          = '-',
    Optional[String[1]]        $description = undef,
    Optional[Stdlib::Unixpath] $home_dir    = undef,
    Optional[Stdlib::Unixpath] $shell       = undef,
) {
    $_usertype = $usertype ? {
        'group'  => 'g',
        'modify' => 'm',
        'range'  => 'r',
        default  => 'u',
    }
    $gecos    = $description ? {
        undef   => '-',
        default => "\"${description}\"",
    }
    $_home_dir = pick($home_dir, '-')
    $_shell    = pick($shell, '-')
    $line      = "${_usertype}\t${username}\t${id}\t${gecos}\t${_home_dir}\t${_shell}\n"
    include systemd
    file { "/etc/sysusers.d/${title.regsubst('[\W_/]', '-', 'G')}.conf":
        ensure  => stdlib::ensure($ensure, 'file'),
        content => $line,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => File['/etc/sysusers.d'],
        notify  => Exec['Refresh sysusers'],
    }
}
