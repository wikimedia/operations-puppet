class systemuser::groups {
    #ensure the generic systemusers group exists
    #current account management logic expects valid users
    #even service users to be a member of a supplementary group
    group { 'systemusers':
        ensure => present,
    }
}

# Creates a system username with associated group, fixed or random uid/gid, and /bin/false as shell
#
# WARNING
# It is NOT RECOMMENDED to use this anymore. Use regular user/group stanzas, properly marking them
# as system => true. While this definition had started as a thin abstraction layer, it has since acquired
# all the features of user { } and some more, including unnecessary magic.
# WARNING

define generic::systemuser(
    $name,
    $uid=undef,
    $home=undef,
    $managehome=true,
    $ssh_key=undef,
    $shell='/bin/false',
    $groups=[],
    $always_groups=['systemusers'],
    $default_group=$name,
    $default_group_gid=undef,
    $ensure=present,
    )
{
    if !is_array($groups) {
        fail("${name} systemuser must specify an array for groups")
    }

    #creating one list of supplementary groups
    $all_groups = split(inline_template("<%= (always_groups+groups).join(',') %>"),',')

    include systemuser::groups

    # FIXME: deprecate $name parameter in favor of just using $title
    #allowing the gid to be specified or not
    if ($default_group_gid) {
        if $default_group == $name {
            group { $default_group:
                ensure => present,
                name   => $default_group,
                gid   => $default_group_gid,
            }
        }
    } else {
        if $default_group == $name {
            group { $default_group:
                ensure => present,
                name   => $default_group,
            }
         }
     }

    $whereis_home = $home ? {
        undef   => "/var/lib/${name}",
        default => $home
    }

    #allowing the uid to be specified or not
    if ($uid) {
        user { $name:
            ensure     => $ensure,
            uid        => $uid,
            require    => Group[$default_group],
            name       => $name,
            gid        => $default_group,
            home       => $whereis_home,
            managehome => $managehome,
            shell      => $shell,
            groups     => $all_groups,
            system     => true,
        }
    } else {
       user { $name:
            ensure     => $ensure,
            require    => Group[$default_group],
            name       => $name,
            gid        => $default_group,
            home       => $whereis_home,
            managehome => $managehome,
            shell      => $shell,
            groups     => $all_groups,
            system     => true,
        }
     }

    if ($ssh_key) {
        ssh_authorized_key {
            "${name}@systemuser":
                ensure => $ensure,
                user   => $name,
                type   => 'ssh-rsa',
                key    => $ssh_key,
        }
    }
}
