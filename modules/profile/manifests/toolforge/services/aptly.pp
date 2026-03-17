class profile::toolforge::services::aptly () {
    # wmcs-package-build uses this to "back up" aptly contents to NFS
    ensure_packages(['rsync'])

    ['trixie', 'bookworm', 'bullseye'].each |Debian::Codename $distro| {
        aptly::repo { [
            "${distro}-tools",
            "${distro}-toolsbeta",
        ]:
            publish => true,
        }
    }
}
