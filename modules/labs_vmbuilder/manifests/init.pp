class labs_vmbuilder($vmbuilder_version) {
    package { 'python-vm-builder':
        ensure => present,
    }

    $vmbuilder_filepath = '/etc/vmbuilder/files'

    file { '/etc/vmbuilder.cfg':
        mode    => '0444',
        content => template('labs_vmbuilder/vmbuilder.cfg.erb'),
        require => Package['python-vm-builder'],
    }

    file { '/etc/vmbuilder/postinst/postinst.copy':
        mode    => '0444',
        source  => 'puppet:///modules/labs_vmbuilder/postinst.copy',
        require => Package['python-vm-builder'],
    }

    file { '/etc/vmbuilder/postinst/postinst.sh':
        mode    => '0555',
        source  => 'puppet:///modules/labs_vmbuilder/postinst.sh',
        require => Package['python-vm-builder'],
    }

    file { '/etc/vmbuilder/firstscripts/firstboot.sh':
        mode    => '0555',
        source  => 'puppet:///modules/labs_vmbuilder/firstboot.sh',
        require => Package['python-vm-builder'],
    }

    file { '/etc/vmbuilder/files/cloud.cfg':
        mode    => '0444',
        source  => 'puppet:///modules/labs_vmbuilder/cloud.cfg',
        require => Package['python-vm-builder'],
    }

    file { $vmbuilder_filepath:
        ensure => directory,
        mode   => '0555',
    }

    file { "${vmbuilder_filepath}/install_sudo.sh":
        mode    => '0555',
        source  => 'puppet:///modules/labs_vmbuilder/install_sudo.sh',
        require => [Package['python-vm-builder'],
                    File[$vmbuilder_filepath],
                    ],
    }

    file { "${vmbuilder_filepath}/vmbuilder.partition":
        mode    => '0555',
        source  => 'puppet:///modules/labs_vmbuilder/vmbuilder.partition',
        require => [Package['python-vm-builder'],
                    File[$vmbuilder_filepath],
                    ],
    }

    file { 'vmbuilder_version':
        path    => '/etc/vmbuilder/files/vmbuilder_version',
        mode    => '0444',
        content => $vmbuilder_version,
        require => [Package['python-vm-builder'],
                    File[$vmbuilder_filepath],
                    ],
    }

    # Overwrite the sudoers.tmpl that ships with python-vm-builder
    #  The built-in one diverges from the actual sudoers file
    #  in modern Trusty versions; that causes apt to get upset
    #  about config file changes.
    #
    # This can be removed if https://bugs.launchpad.net/ubuntu/+source/vm-builder/+bug/1618899
    #  is ever fixed.
    file { '/etc/vmbuilder/ubuntu/sudoers.tmpl':
        mode    => '0444',
        source  => 'puppet:///modules/labs_vmbuilder/sudoers.tmpl',
        require => Package['python-vm-builder'],
    }

    # FIXME - top-scope var without namespace, will break in puppet 2.8
    # lint:ignore:variable_scope
    $projectregex = "s/${labsproject}/_PROJECT_/g"
    # lint:endignore
    $fqdnregex    = "s/${::fqdn}/_FQDN_/g"

    # We can't just use $::servername here because the master
    #  returns labcontrol1001 vs. the service name, labs-puppetmaster-eqiad
    $puppetmaster = hiera('puppetmaster')
    $masterregex = "s/${puppetmaster}/_MASTER_/g"

    Exec { path => '/bin' }

    exec { "cp /etc/security/access.conf ${vmbuilder_filepath}/access.conf":
        subscribe => File['vmbuilder_version'],
    } ~>

    exec { "sed -i '${projectregex}' ${vmbuilder_filepath}/access.conf":
    }

    exec { "cp /etc/nslcd.conf ${vmbuilder_filepath}/nslcd.conf":
        subscribe => File['vmbuilder_version'],
    } ~>

    exec { "sed -i '${projectregex}' ${vmbuilder_filepath}/nslcd.conf":
    }

    exec { "cp /etc/ldap/ldap.conf ${vmbuilder_filepath}/nss_ldap.conf":
        subscribe => File['vmbuilder_version'],
    } ~>

    exec { "sed -i '${projectregex}' ${vmbuilder_filepath}/nss_ldap.conf":
    }

    exec { "cp /etc/puppet/puppet.conf ${vmbuilder_filepath}/puppet.conf":
        subscribe => File['vmbuilder_version'],
    } ~>

    exec { "sed -i '${fqdnregex}' ${vmbuilder_filepath}/puppet.conf":
    } ~>

    exec { "sed -i '${masterregex}' ${vmbuilder_filepath}/puppet.conf":
    } ~>

    exec { "sed -i '${projectregex}' ${vmbuilder_filepath}/puppet.conf":
    }
}
