# MariaDB WMF patched build installed in /opt.
# Unless you're setting up a production server,
# you probably want vanilla mariadb::packages

class mariadb::packages_wmf(
    $mariadb10 = true,        # deprecated parameter, do not use
    $package   = 'wmf-mariadb10',
#    $version   = None,          # reserved for future usage
    ) {

    package { [
        'libaio1',            # missing dependency on packages < 10.0.27
        'percona-toolkit',
        'percona-xtrabackup',
        'libjemalloc1',       # missing dependency on packages < 10.0.27
        'pigz',
        'grc',
    ]:
        ensure => present,
    }

    # mariadb10 parameter is deprecated, and it will be eliminates as soon
    # as the last mariadb 5.5 server is upgraded
    if ($mariadb10 == false) {
        package { 'wmf-mariadb':
            ensure => present,
        }
        class { 'mariadb::mysqld_safe':
            package => 'wmf-mariadb',
        }
    }
    else {
        case $package {
            'wmf-mariadb', 'wmf-mariadb10', 'wmf-mariadb101', 'wmf-mysql57' :
            {
                package { $package:
                    ensure => present,
                }

                # if you have installed the wmf mariadb package,
                # create a custom, safer mysqld_safe
                # New packages include it, but old packages have
                # to be overwritten still - do not retire at least
                # until version > 10.0.27
                class { 'mariadb::mysqld_safe':
                    package => $package,
                }
            }
            default :
            {
                fail("Invalid package version \"${package}\". \
The only allowed versions are: wmf-mariadb10, wmf-mariadb101 or wmf-mysql57")
            }
        }
    }
}
