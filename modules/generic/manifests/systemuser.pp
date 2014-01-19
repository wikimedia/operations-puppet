# Creates a system username with associated group, random uid/gid, and /bin/false as shell
define generic::systemuser($name, $home=undef, $managehome=true, $shell='/bin/false', $groups=undef, $default_group=$name, $ensure=present) {
    # FIXME: deprecate $name parameter in favor of just using $title

    if $default_group == $name {
        group { $default_group:
            ensure => present,
            name   => $default_group,
        }
    }

    $whereis_home = $home ? {
        undef   => "/var/lib/${name}",
        default => $home
    }

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
