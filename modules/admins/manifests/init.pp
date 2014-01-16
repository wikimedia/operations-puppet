class admins {
    include admins::data

    # used as primary gid for most groups; may be redefined elsewhere
    @group { 'wikidev':
        ensure    => present,
        name      => 'wikidev',
        allowdupe => false,
    }
    Group <| title == 'wikidev' |> {
        gid    => $admins::gids['wikidev'],
    }

    # remove everyone that's a member of the special-named group "revoked"
    admins::group { 'revoked':
        ensure => absent,
    }

    # ugh, this is ugly. create home directories
    if !defined(Class['nfs::home']) {
        File <| tag == 'account/home' |>
    }
}

# compatibility classes for migration; too ugly to follow autoload pattern
class admins::roots inherits admins {
    # note the "ops" instead of "roots"
    admins::group { 'ops': }
}
class admins::mortals inherits admins {
    admins::group { 'mortals': }
}
class admins::restricted inherits admins {
    admins::group { 'restricted': }
}
class admins::labs inherits admins {
    admins::group { 'labs': }
}
class admins::jenkins inherits admins {
    admins::group { 'jenkins': }
}
class admins::dctech inherits admins {
    admins::group { 'dctech': }
}
class admins::globaldev inherits admins {
    admins::group { 'globaldev': }
}
class admins::privatedata inherits admins {
    admins::group { 'privatedata': }
}
class admins::fr-tech inherits admins {
    admins::group { 'fr-tech': }
}
class admins::parsoid inherits admins {
    admins::group { 'parsoid': }
}
