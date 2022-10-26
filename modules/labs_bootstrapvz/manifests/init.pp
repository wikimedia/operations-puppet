class labs_bootstrapvz() {

    $python_package = debian::codename::lt('buster') ? {
        true    => 'bootstrap-vz',
        default => 'python-bootstrap-vz',
    }

    ensure_packages(['nbd-client', 'zerofree', 'kpartx', $python_package])

    $bootstrap_filepath = '/etc/bootstrap-vz/'

    ['', 'manifests', 'firstscript', 'puppet'].each |$subdir| {
        file {"${bootstrap_filepath}/${subdir}":
            ensure => directory,
        }
    }

    file {
        default:
            mode    => '0444';
        "${bootstrap_filepath}/manifests/labs-stretch.manifest.yaml":
            source  => 'puppet:///modules/labs_bootstrapvz/labs-stretch.manifest.yaml';
        "${bootstrap_filepath}/manifests/cloud-buster.manifest.yaml":
            source  => 'puppet:///modules/labs_bootstrapvz/cloud-buster.manifest.yaml';
    }

    $projectregex = "s/${::wmcs_project}/_PROJECT_/g"
    $fqdnregex = "s/${::fqdn}/_FQDN_/g"

    # We can't just use $::servername here because the master
    #  returns cloud-puppetmaster-03 vs. the service name, puppetmaster.cloudinfra.wmflabs.org
    $puppetmaster = lookup('puppetmaster')
    $masterregex = "s/${puppetmaster}/_MASTER_/g"

    Exec { path => '/bin' }

    exec { "cp /etc/security/access.conf ${bootstrap_filepath}/access.conf":
    }

    ~> exec { "sed -i '${projectregex}' ${bootstrap_filepath}/access.conf":
    }

    if debian::codename::lt('buster') {
        exec { "cp /etc/nslcd.conf ${bootstrap_filepath}/nslcd.conf":
        }

        ~> exec { "sed -i '${projectregex}' ${bootstrap_filepath}/nslcd.conf":
        }
    }

    exec { "cp /etc/ldap/ldap.conf ${bootstrap_filepath}/nss_ldap.conf":
    }

    ~> exec { "sed -i '${projectregex}' ${bootstrap_filepath}/nss_ldap.conf":
    }

    exec { "cp /etc/puppet/puppet.conf ${bootstrap_filepath}/puppet/puppet.conf":
        require => File["${bootstrap_filepath}/puppet"],
    }

    ~> exec { "sed -i '${fqdnregex}' ${bootstrap_filepath}/puppet/puppet.conf":
    }

    ~> exec { "sed -i '${masterregex}' ${bootstrap_filepath}/puppet/puppet.conf":
    }

    exec { "sed -i '${projectregex}' ${bootstrap_filepath}/puppet/puppet.conf":
    }

    # The bootstrap run tends to time out during apt
    ~> apt::conf { 'bootstrap-timeout':
        priority => '99',
        key      => 'Acquire::http::Timeout',
        value    => '3000',
    }
}
