# Installs the puppet compiler and all the other software we need.
class puppet_compiler(
    $version = '0.1.0',
    $rootdir = '/opt/wmf',
    $ensure  = present,
    $user    = 'www-data'
    ) {

    include puppet_compiler::packages

    $install_dir = "${rootdir}/software"
    $program_dir = "${install_dir}/compare-puppet-catalogs"
    $puppetdir = "${program_dir}/external/puppet"

    nginx::site {'puppet-compiler':
        ensure  => $ensure,
        content => template('puppet_compiler/nginx_site.erb'),
    }

    # This wrapper defines the env variables for running.
    file {'run_wrapper':
        ensure   => $ensure,
        path     => '/usr/local/bin/puppet-compiler',
        content  => template('puppet_compiler/run_wrapper.erb'),
        mode     => '0555'
    }


    if $ensure != 'present' {
        file{'root_dir':
            ensure  => 'absent',
            path    => $rootdir,
            owner   => $user,
            recurse => true,
            force   => true,
        }
    } else {
        file{'root_dir':
            ensure => 'directory',
            path   => $rootdir,
            owner  => $user,
            before => Git::Install['operations/software'],
        }

        git::install {'operations/software':
            ensure        => 'present',
            directory     => $install_dir,
            owner         => $user,
            git_tag       => "compare-puppet-catalogs-${version}",
            require       => Nginx::Site['puppet-compiler'],
        }

        exec {'install_puppet_compare_requirements':
            command => '/usr/bin/pip install requests simplediff',
            user    => 'root',
            require => Git::Install['operations/software'],
        }

        puppet_compiler::bundle {['2.7', '3']: }

        # Now install the puppet repo

        exec {'install_puppet_repositories':
            command => "${program_dir}/shell/helper install",
            user    => $user,
            creates => $puppetdir,
            require => Git::Install['operations/software'],
            notify  => Class['puppet_compiler::differ']
        }

        exec {'install_naggen':
            command => "/bin/cp ${program_dir}/external/puppet/modules/puppetmaster/files/naggen /usr/local/bin/naggen",
            creates => '/usr/local/bin/naggen',
            require => Exec['install_puppet_repositories']
        }


        class {'puppet_compiler::differ':
            require => [Exec['install_puppet_repositories'],Exec['install_naggen']]
        }

        file {["${program_dir}/output", "${program_dir}/output/html","${program_dir}/output/diff", "${program_dir}/output/compiled",]:
            ensure  => directory,
            owner   => $user,
            mode    => '0775',
            require => Exec['install_puppet_repositories']
        }

        $mysql_query = template('puppet_compiler/mysql_queries.erb')
        exec {'mysql queries':
            command => "/usr/bin/mysql -NBe ${mysql_query}",
            unless  => "/usr/bin/mysql puppet -NBe 'SELECT 1' ",
            require => Package['mysql-server']
        }
    }
}
