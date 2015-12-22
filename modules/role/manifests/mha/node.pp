class mha::node {
    package { 'mha4mysql-node':
        ensure => latest,
    }

    file { [ '/home/mysql', '/home/mysql/.ssh' ]:
        ensure  => directory,
        owner   => 'mysql',
        group   => 'mysql',
        mode    => '0700',
        require => User['mysql'],
    }

    file { '/home/mysql/.ssh/mysql.key':
        owner  => 'mysql',
        group  => 'mysql',
        mode   => '0400',
        content => secret('ssh/mysql/mysql.key'),
    }

    ssh::userkey { 'mysql':
        ensure  => present,
        content => 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDryVraiGfd0eQzV0QB/xXvgiPvpp8qt/BEqT9xWpohPNC1MevM+SMGmpimCLyvv35JDmz1DiJwJf72GKakDqWdbp/pBHitr0VV3eANpLyYiDTWir75SEF9F/WxkRTbEe/tErJc0tsksVGIm+36r3eHrrz68AkJJZVhcQMMXPx6Ye1NIy5qJ/i7cSSAxkanHlXiX+lnGMIxYUKuiVVl7kxrGDAvaLeszZKdYn8WkMH32MuL/M66ff9vBY7pGGM8MubjGMxL878hpimhTrLcmay7l4nuAMW6UUnkqufx6ArT80RWDWz5woFvyheBdVDnQZI06cJzj3WG6rWt8eG/A1SL mha@production',
    }
}

