# Creates a system username with associated group, fixed or random uid/gid, and /bin/false as shell
define generic::systemuser(
    $name,
    $uid=undef,
    $home=undef,
    $managehome=true,
    $ssh_key=undef,
    $shell='/bin/false',
    $groups=undef,
    $default_group=$name,
    $default_group_gid=undef,
    $ensure=present,
    )
{
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
            groups     => $groups,
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
            groups     => $groups,
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
