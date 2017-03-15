define authdns::zone_aliases($destdir, $aliases) {
    authdns::zonefile { $aliases:
        destdir => $destdir,
        tmpl    => $title,
    }
}
