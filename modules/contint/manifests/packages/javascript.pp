# == Class contint::packages::javascript
#
# Install npm from npmjs.com with pinned versions
#
class contint::packages::javascript {

    requires_realm('labs')

    if os_version('debian == jessie') {
      package { 'npm':
          ensure => present,
          notify => Exec['pin npm'],
      }
    } else {
      package { 'npm':
          ensure => 'purged',
          notify => Exec['pin npm'],
      }
    }

    # DO NOT CHANGE VERSION WITHOUT INVOLVING Krinkle OR hashar
    #
    # https://wikitech.wikimedia.org/wiki/Nova_Resource:Integration/Setup
    $versions = {
        'npm'       => '3.8.3',
    }

    # Provide 'node' alias for 'nodejs' because Debian already has a package
    # called 'node'
    package { 'nodejs-legacy':
        ensure => present,
        # Brings up 'nodejs' from upstream which we then override
        before => Package['npm'],
    }

    exec { 'pin npm':
        command => "/usr/bin/npm install -g npm@${versions['npm']}",
        onlyif  => "/usr/bin/test \"`/usr/bin/npm --version`\" != \"${versions['npm']}\"",
        require => Package['npm'],
    }

}
