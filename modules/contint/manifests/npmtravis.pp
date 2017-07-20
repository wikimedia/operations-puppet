# Unused as of April 8th 2016
#
# T114421 - [RFC] Optional Travis integration for Jenkins
#
class contint::npmtravis {
    # user and private key for Travis integration
    # RT: 8866
    user { 'npmtravis':
        home       => '/home/npmtravis',
        managehome => true,
        system     => true,
    }

    file { '/home/npmtravis/.ssh':
        ensure  => directory,
        owner   => 'npmtravis',
        mode    => '0500',
        require => User['npmtravis'],
    }

    file { '/home/npmtravis/.ssh/npmtravis_id_rsa':
        ensure    => present,
        owner     => 'npmtravis',
        mode      => '0400',
        content   => secret('ssh/ci/npmtravis_id_rsa'),
        require   => File['/home/npmtravis/.ssh'],
        show_diff => false,
    }
}
