# MariaDB packages for a client-only install.
# **Do not add it** if you do a full installation
# (packages.pp or packages_wmf.pp)

class mariadb::packages_client (
    String[1] $package,
) {
    ensure_packages([
        $package,
        'percona-toolkit',       # very useful client utilities
        'grc',                   # used to colorize paged sql output
        'python3-pymysql',       # dependency for some utilities- TODO: delete & add as dependency
        'python3-tabulate',      # dependency for some utilities- TODO: delete & add as dependency
        'mariadb-backup',        # TODO(kormat): this is likely not needed, and could be removed
    ])
}
