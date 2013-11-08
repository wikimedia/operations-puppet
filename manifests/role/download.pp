# role classes for download servers

class role::download::common {

    include download,
            standard,
            admins::roots,
            groups::wikidev,
            accounts::catrope

}

class role::download::primary {

    include role::download::common,
            download::primary,
            download::kiwix-mirror

}

class role::download::secondary {

    include role::download::common,
            download::mirror,
            download::gluster


}
