# role classes for download servers

# common classes included by all download servers
class role::download::common {

    include download,
            standard,
            admins::roots,
            groups::wikidev,
            accounts::catrope

}

# additional classes on a primary server
class role::download::primary {

    system::role { 'role::download::primary': description => 'primary download server' }

    include role::download::common,
            download::primary,
            download::kiwix

}

# additional classes on a secondary server
class role::download::secondary {

    system::role { 'role::download::primary': description => 'secondary download server' }

    include role::download::common,
            download::mirror,
            download::gluster


}
