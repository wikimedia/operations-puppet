# Class: puppetmaster::dashboard
#
# This class installs a Puppet Dashboard interface for managing all Puppet
# clients
#
# Parameters:
#    - $dashboard_environment:
#        The RAILS environment dashboard should run in (production,
#        development, test)
#    - $db_host
#        Hostname of the MySQL database server to use
class puppetmaster::dashboard(
                            $dashboard_environment='production',
                            $db_host='localhost') {
    require puppetmaster::passenger, passwords::puppetmaster::dashboard

    system::role { 'puppetmaster::dashboard':
        description => 'Puppet Dashboard interface' }

    $db_pass = $passwords::puppetmaster::dashboard::db_pass

    package { 'puppet-dashboard': ensure => latest }

    File { mode => 0444 }
    file {
        '/etc/apache2/sites-available/dashboard':
            content => template('puppetmaster/dashboard/dashboard.erb');
        '/etc/puppet-dashboard/database.yml':
            require => Package['puppet-dashboard'],
            content => template('puppetmaster/dashboard/database.yml.erb');
        '/etc/puppet-dashboard/settings.yml':
            require => Package['puppet-dashboard'],
            content => template('puppetmaster/dashboard/settings.yml.erb');
        '/etc/default/puppet-dashboard':
            content => template('puppetmaster/dashboard/puppet-dashboard.default.erb');
        '/etc/default/puppet-dashboard-workers':
            content => template('puppetmaster/dashboard/puppet-dashboard-workers.default.erb');
    }

    apache_site { 'dashboard':
        name    => 'dashboard',
        require => Exec['migrate database']
    }

    Exec {
        path        => '/usr/bin:/bin',
        cwd         => '/usr/share/puppet-dashboard',
        subscribe   => Package['puppet-dashboard'],
        refreshonly => true
    }
    exec {
        'create database':
            require => File['/etc/puppet-dashboard/database.yml'],
            command => "rake RAILS_ENV=${dashboard_environment} db:create";
        'migrate database':
            command => "rake RAILS_ENV=${dashboard_environment} db:migrate";
    }
    Exec['create database'] -> Exec['migrate database'] -> Service['puppet-dashboard-workers']

    service { 'puppet-dashboard-workers': ensure => running }

    # Temporary fix for dashboard under Lucid
    # http://projects.puppetlabs.com/issues/8800
    if $::lsbdistid == 'Ubuntu' and versioncmp($::lsbdistrelease, '10.04') == 0 {
        file { '/etc/puppet-dashboard/dashboard-fix-requirements-lucid.patch':
            require => Package['puppet-dashboard'],
            before  => Exec['migrate database'],
            source  => 'puppet:///modules/puppetmaster/dashboard-fix-requirements-lucid.patch'
        }

        exec { 'fix gem-dependency.rb':
            command     => 'patch -p0 < /etc/puppet-dashboard/dashboard-fix-requirements-lucid.patch',
            cwd         => '/usr/share/puppet-dashboard/vendor/rails/railties/lib/rails',
            require     => File['/etc/puppet-dashboard/dashboard-fix-requirements-lucid.patch'],
            before      => [Apache_site[dashboard], Service['puppet-dashboard-workers']],
            subscribe   => Package['puppet-dashboard'],
            refreshonly => true
        }
    }
}
