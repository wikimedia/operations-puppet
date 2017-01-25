# Establish the ability to do Host Based Auth from bastions/submit hosts to execs/webgrid
#
# Add hosts we want to be able to SSH to all hosts not protected by the
# toollabs::infrastructure mechanism to both the shosts.equiv file
# and the pam access control line manually.

class toollabs::hba {

    file { '/usr/local/sbin/project-make-shosts':
        ensure => absent,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/toollabs/project-make-shosts',
    }

    file { '/usr/local/sbin/project-make-access':
        ensure => absent,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/toollabs/project-make-shosts',
    }

    file { '/etc/ssh/shosts.equiv':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/toollabs/ssh_shosts.equiv',
    }

    $pam_access_d_for_hba = '+:ALL: 10.68.16.44 10.68.23.58 10.68.23.74 10.68.16.228 10.68.16.17 10.68.16.31'
    security::access::config { 'toollabs-hba':
        content => $pam_access_d_for_hba,
        require => Exec['make-access'],
    }
}
