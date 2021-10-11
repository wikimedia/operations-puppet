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
    $id_type = $id ? {
        '-'                       => 'default',
        Integer                   => 'integer',
        Stdlib::Unixpath          => 'path',
        Pattern[/\A\d+:\d+\z/]    => 'uid:gid',
        Pattern[/\A\d+-\d+\z/]    => 'range',
        Pattern[/\A\d+:[\w-]+\z/] => 'uid:groupname',
        Pattern[/\A[\w-]+\z/]     => 'groupname',
    }

    if $usertype != 'user' and ($description or $home_dir or $shell) {
        fail("usertype: ${usertype} does not support \$description, \$home_dir or \$shell")
    }
    if $usertype ==  'user' and $id_type in ['groupname', 'range'] {
        fail("usertype: ${usertype} does not support ${id_type} id's")
    }
    if $usertype ==  'group' and $id_type in ['groupname', 'range', 'uid:gid', 'uid:groupname'] {
        fail("usertype: ${usertype} does not support ${id_type} id's")
    }
    if $usertype ==  'modify' and !($id_type in ['groupname', 'default', 'range']) {
        fail("usertype: ${usertype} does not support ${id_type} id's")
    }
    if $usertype ==  'range' and !($id_type in ['range', 'default']) {
        fail("usertype: ${usertype} does not support ${id_type} id's")
    }
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
    if $usertype == 'group' and $id_type == 'integer' {
        group { $username:
            ensure => $ensure,
            gid    => $id,
            system => true,
        }
    }
    if $usertype == 'user' and (!($id_type in ['default', 'path']) or $home_dir or $shell) {
        case $id {
            Integer: {
                $uid = $id
                $gid = undef
            }
            # this captures both uid:gid and uid:groupname
            Pattern[/\A\d+:[\w-]+\z/]: {
                $data = $id.split(':')
                $uid = $data[0]
                $gid = $data[1]
            }
            default: {
                $uid = undef
                $gid = undef
            }
        }

        user { $username:
            ensure => $ensure,
            gid    => $gid,
            home   => $home_dir,
            shell  => $shell,
            system => true,
            uid    => $uid,
        }
    }
}
