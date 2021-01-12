class sbuild (
) {
    ensure_packages([
        'sbuild',
        'apt-cacher-ng',
        'schroot',
    ])
}
