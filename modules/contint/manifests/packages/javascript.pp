# == Class contint::packages::javascript
#
# Install npm from npmjs.com with pinned versions
#
class contint::packages::javascript {

    requires_realm('labs')

    package { 'npm':
        ensure => present,
        notify => Exec['pin npm'],
    }

    # DO NOT CHANGE VERSION WITHOUT INVOLVING Krinkle OR hashar
    #
    # https://wikitech.wikimedia.org/wiki/Nova_Resource:Integration/Setup
    $versions = {
        'npm'       => '2.15.2',
    }

    $npm_options = $::lsbdistcodename ? {
        # Default npm that ships with Ubuntu Precise's node predates npmjs.org SSL
        # http://blog.npmjs.org/post/78085451721/npms-self-signed-certificate-is-no-more
        'precise' => '--ca=null --force',
        default   => '',
    }

    if (os_version('ubuntu >= trusty') or os_version('debian >= jessie')) {
        # Provide 'node' alias for 'nodejs' because Debian/Ubuntu
        # already has a package called 'node'
        package { 'nodejs-legacy':
            ensure => present,
            # Brings up 'nodejs' from upstream which we then override
            before => Package['npm'],
        }
    }

    exec { 'pin npm':
        command => "/usr/bin/npm install ${npm_options} -g npm@${versions['npm']}",
        onlyif  => "/usr/bin/test \"`/usr/bin/npm --version`\" != \"${versions['npm']}\"",
        require => Package['npm'],
    }

}
