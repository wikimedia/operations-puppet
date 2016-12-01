# This class sets up a node as an execution environment for tool labs.
# This is a "sub" role included by the actual tool labs roles and would
# normally not be included directly in node definitions.
#
# Actual runtime dependencies for tools live here.
#

class toollabs::exec_environ(
    $packages,
) {

    include locales::extended
    include identd
    include ::redis::client::python

    # Mediawiki fontlist no longer supports precise systems
    if os_version('ubuntu precise') {
        include ::toollabs::legacy::fonts
    } else {
        include ::mediawiki::packages::fonts
    }

    # T65000
    include ::imagemagick::install

    package { $packages:
        ensure => latest,
    }

    file { '/etc/mysql/conf.d/override.my.cnf':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/toollabs/override.my.cnf',
    }

    # Packages that are different between precise and trusty go here.
    # Note: Every package *must* have equivalent package in both the
    # branches. If one is unavailable, please mark it as such with a comment.
    if $::lsbdistcodename == 'precise' {
        include toollabs::genpp::python_exec_precise
        package { [
            'libboost-python1.48.0',
            'libgdal1-1.7.0',              # T58995
            'libmpc2',
            'libprotobuf7',                # T58995
            'libtime-local-perl',          # now part of perl-modules
            'libthreads-shared-perl',      # now part of perl
            'libthreads-perl',             # now part of perl
            'libvips15',
            'mysql-client',                # mariadb-client just... doesn't work on precise. Apt failures
            'pyflakes',                    # T59863
            'tclthread',                   # now called tcl-thread
            # no nodejs-legacy             (presumably, -legacy makes a symlink that is default in precise)
            ]:
            ensure => latest,
        }
    } elsif $::lsbdistcodename == 'trusty' {
        include toollabs::genpp::python_exec_trusty
        # No obvious package available for libgdal
        package { [
            'hhvm',                        # T78783
            'libboost-python1.54.0',
            'libmpc3',
            'libprotobuf8',
            'libbytes-random-secure-perl', # T123824
            'libvips37',
            'nodejs-legacy',               # T1102
            'mariadb-client',              # For /usr/bin/mysql, is broken on precise atm
            'python-flake8',
            'python3-flake8',
            'tcl-thread',
            ]:
            ensure => latest,
        }

        # T135861: PHP 5.5 sessionclean cron job hanging on tool labs bastions
        file { '/usr/lib/php5/sessionclean':
            ensure  => 'present',
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
            source  => 'puppet:///modules/toollabs/sessionclean',
            require => Package['php5-cli'],
        }
        # Using a file resource instead of a cron resource here as this is
        # overwriting a file added by the php5-common deb.
        file { '/etc/cron.d/php5':
            ensure  => 'present',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            source  => 'puppet:///modules/toollabs/php5.cron.d',
            require => Package['php5-cli'],
        }
    } elsif $::lsbdistcodename == 'jessie' {
        include toollabs::genpp::python_exec_jessie
        # No obvious package available for libgdal
        package { [
            'hhvm',                        # T78783
            'libboost-python1.55.0',
            'libmpc3',
            'libprotobuf9',
            'libbytes-random-secure-perl', # T123824
            'libvips38',
            'nodejs-legacy',               # T1102
            'mariadb-client',              # For /usr/bin/mysql, is broken on precise atm
            'python-flake8',
            'python3-flake8',
            'tcl-thread',
            ]:
            ensure => latest,
        }
    }

    package { 'misctools':
        ensure => latest,
    }

    file { '/usr/bin/sql':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/toollabs/sql',
    }

    sysctl::parameters { 'tool labs':
        values => {
            'vm.overcommit_memory' => 2,
            'vm.overcommit_ratio'  => 95,
        },
    }
}
