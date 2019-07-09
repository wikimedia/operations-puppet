class labs_bootstrapvz() {

    package { 'nbd-client':
        ensure => 'present',
    }

    # This weird greater-than check is to deal with the fact that
    #  Buster doesn't actually have a release number assigned
    #  until it's released.  We need to remove that clause
    #  sometime between Buster and Bullseye.
    if os_version('debian == buster') or os_version('debian > buster')
    {
        # Until upstream packaging catches up, use our custom
        #  package for this.
        package { 'python-bootstrap-vz':
            ensure => present,
        }
    } else {
        package { 'bootstrap-vz':
            ensure => present,
        }
    }

    package { 'zerofree':
        ensure => present,
    }

    package { 'kpartx':
        ensure => present,
    }

    $bootstrap_filepath = '/etc/bootstrap-vz/'

    file { $bootstrap_filepath:
        ensure => directory,
    }

    file { "${bootstrap_filepath}/manifests":
        ensure  => directory,
        require => File[$bootstrap_filepath],
    }

    file { "${bootstrap_filepath}/firstscripts":
        ensure  => directory,
        require => File[$bootstrap_filepath],
    }

    file { "${bootstrap_filepath}/puppet":
        ensure  => directory,
        require => File[$bootstrap_filepath],
    }

    file { "${bootstrap_filepath}/manifests/labs-jessie.manifest.yaml":
        mode    => '0444',
        source  => 'puppet:///modules/labs_bootstrapvz/labs-jessie.manifest.yaml',
        require => File["${bootstrap_filepath}/manifests"],
    }

    file { "${bootstrap_filepath}/manifests/labs-stretch.manifest.yaml":
        mode    => '0444',
        source  => 'puppet:///modules/labs_bootstrapvz/labs-stretch.manifest.yaml',
        require => File["${bootstrap_filepath}/manifests"],
    }

    file { "${bootstrap_filepath}/manifests/cloud-buster.manifest.yaml":
        mode    => '0444',
        source  => 'puppet:///modules/labs_bootstrapvz/cloud-buster.manifest.yaml',
        require => File["${bootstrap_filepath}/manifests"],
    }

    file { "${bootstrap_filepath}/firstscripts/firstboot.sh":
        mode    => '0555',
        source  => 'puppet:///modules/labs_bootstrapvz/firstboot.sh',
        require => File["${bootstrap_filepath}/firstscripts"],
    }

    file { "${bootstrap_filepath}/firstscripts/firstbootrc":
        mode    => '0555',
        source  => 'puppet:///modules/labs_bootstrapvz/firstbootrc',
        require => File["${bootstrap_filepath}/firstscripts"],
    }

    $projectregex = "s/${::labsproject}/_PROJECT_/g"
    $fqdnregex = "s/${::fqdn}/_FQDN_/g"

    # We can't just use $::servername here because the master
    #  returns labpuppetmaster1001 vs. the service name, labs-puppetmaster
    $puppetmaster = hiera('puppetmaster')
    $masterregex = "s/${puppetmaster}/_MASTER_/g"

    Exec { path => '/bin' }

    exec { "cp /etc/security/access.conf ${bootstrap_filepath}/access.conf":
    }

    ~> exec { "sed -i '${projectregex}' ${bootstrap_filepath}/access.conf":
    }

    if os_version('debian < buster') {
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
