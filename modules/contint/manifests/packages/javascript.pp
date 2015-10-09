# == Class contint::packages::javascript
#
# Install npm/grunt-cli from npmjs.com with pinned versions
#
class contint::packages::javascript {

    requires_realm('labs')

    package { 'npm':
        ensure => present,
    }

    # DO NOT CHANGE VERSIONS
    #
    # https://wikitech.wikimedia.org/wiki/Nova_Resource:Integration/Setup
    $versions = {
        'npm'       => '2.7.6',
        'grunt-cli' => '0.1.13',
    }

    $npm_options = $::lsbdistcodename ? {
        # npm is terribly outdated
        'precise' => '--ca=null',
        default   => '',
    }

    exec { 'pin npm':
        path    => '/usr/local/bin:/usr/bin',
        command => "npm install ${npm_options} -g npm@${versions['npm']}",
        onlyif  => "/usr/bin/test \"`/usr/local/bin/npm --version`\" != \"${versions['npm']}\"",
        require => Package['npm'],
    }

    file { '/usr/bin/npm':
        ensure  => link,
        target  => '/usr/local/bin/npm',
        require => Exec['pin npm'],
    }

    exec { 'pin grunt-cli':
        command => "/usr/local/bin/npm install -g grunt-cli@${versions['grunt-cli']}",
        onlyif  => "/usr/bin/test \"`/usr/local/bin/grunt --version`\" != \"grunt-cli v${versions['grunt-cli']}\"",
        require => File['/usr/local/bin/npm'],
    }

}
