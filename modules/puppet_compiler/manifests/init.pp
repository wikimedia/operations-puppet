# Installs the puppet compiler and all the other software we need.
class puppet_compiler( $version = '0.1.0', $rootdir='/opt/wmf') {

    include puppet_compiler::packages

    nginx::site {'puppet-compiler':
        content => template('puppet_compiler/nginx_site.erb')
    }

    $install_dir = "${rootdir}/software"
    $program_dir = "${install_dir}/compare_puppet-catalogs"
    $puppetdir = "${program_dir}/external/puppet"

    file{'root_dir':
        ensure => 'directory',
        path   => $rootdir,
        owner  => 'www-data',
        before => Git::Install['operations/software'],
    }

    git::install {'operations/software':
        ensure        => 'present',
        directory     => $install_dir,
        owner         => 'www-data',
        git_tag       => "compare-puppet-catalogs-${version}",
        require       => Nginx::Site['puppet-compiler'],
    }



    exec {'install_puppet_compare_requirements':
        command => "/usr/bin/pip -r install ${program_dir}/requirements.txt",
        user    => 'root',
        require => Git::Install['operations/software'],
    }

    puppet_compiler::bundle {['2.7', '3']: }

    # Now install the puppet repo

    exec {'install_puppet_repositories':
        command => "${program_dir}/shell/helper install",
        user    => 'www-data',
        creates => $puppetdir,
        require => Git::Install['operations/software'],
        notify  => Class['puppet_compiler::differ']
    }

    class {'puppet_compiler::differ':
        require => Exec['install_puppet_repositories']
    }

    file {["${program_dir}/output", "${program_dir}/output/html",
           "${program_dir}/output/diff", "${program_dir}/output/compiled",]:
        ensure  => directory,
        owner   => 'www-data',
        mode    => '0775',
        require => Exec['install_puppet_repositories']
    }
}
