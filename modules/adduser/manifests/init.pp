# SPDX-License-Identifier: Apache-2.0
class adduser (
    Stdlib::Unixpath           $default_shell     = '/bin/bash',
    Stdlib::Unixpath           $default_home      = '/home',
    Boolean                    $use_group_homes   = false,
    Boolean                    $use_letter_homes  = false,
    Stdlib::Unixpath           $skel_dir          = '/etc/skel',
    Integer[1]                 $first_system_uid  = 100,
    Integer[1]                 $last_system_uid   = 499,
    Integer[1]                 $first_system_gid  = 100,
    Integer[1]                 $last_system_gid   = 499,
    Integer[1]                 $first_uid         = 1000,
    Integer[1]                 $last_uid          = 59999,
    Integer[1]                 $first_gid         = 1000,
    Integer[1]                 $last_gid          = 59999,
    Boolean                    $use_usergroups    = true,
    Integer[1]                 $users_gid         = 100,
    Stdlib::Filemode           $dir_mode          = '0755',
    Boolean                    $home_setgid       = false,
    String                     $quota_user        = '',
    String                     $skel_ignore_regex = 'dpkg-(old|new|dist|save)',
    Optional[Array[String[1]]] $extra_groups      = [],
    Optional[String[1]]        $name_regex        = undef,
) {
    if $first_system_uid > $last_system_uid {
        fail("\$first_system_uid (${first_system_uid}) must be smaller then \$last_system_uid (${last_system_uid})")
    }
    if $first_system_gid > $last_system_gid {
        fail("\$first_system_gid (${first_system_gid}) must be smaller then \$last_system_gid (${last_system_gid})")
    }
    if $first_uid > $last_uid {
        fail("\$first_uid (${first_uid}) must be smaller then \$last_uid (${last_uid})")
    }
    if $first_gid > $last_gid {
        fail("\$first_gid (${first_gid}) must be smaller then \$last_gid (${last_gid})")
    }
    if $first_uid < $last_system_uid {
        fail("\$last_system_uid (${last_system_uid}) must be smaller then \$first_uid (${first_uid})")
    }
    if $first_gid < $last_system_gid {
        fail("\$last_system_gid (${last_system_gid}) must be smaller then \$first_gid (${first_gid})")
    }
    file {'/etc/adduser.conf':
        ensure  => file,
        mode    => '0644',
        content => template('adduser/etc/adduser.conf.erb'),
    }

    systemd::sysuser { 'sysusers-base-config':
        usertype => 'range',
        username => '-',
        id       => "${first_system_uid}-${last_system_uid}",
    }

    # For historical reasons, users in modules/admin/data/data.yaml
    # (for production) and in LDAP (for Labs) start at uid/gid 500, so
    # we need to guard against system users being created in that
    # range.
    file_line { 'login.defs-SYS_UID_MAX':
        path  => '/etc/login.defs',
        match => '#?SYS_UID_MAX\b',
        line  => "SYS_UID_MAX               ${last_system_uid}",
    }
    file_line { 'login.defs-SYS_GID_MAX':
        path  => '/etc/login.defs',
        match => '#?SYS_GID_MAX\b',
        line  => "SYS_GID_MAX               ${last_system_gid}",
    }
}
