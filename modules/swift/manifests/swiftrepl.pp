# SPDX-License-Identifier: Apache-2.0
class swift::swiftrepl (
  $ensure,
  $destination_site,
  $source_site = $::site,
) {
    ensure_packages(['python-cloudfiles', 'time'])

    $basedir = '/srv/software'
    $account = 'mw:media'

    group { 'swiftrepl':
        ensure => present, # don't clean up groups to avoid gid reuse
        name   => 'swiftrepl',
    }

    user { 'swiftrepl':
        ensure     => present, # don't clean up users to avoid uid reuse
        name       => 'swiftrepl',
        home       => $basedir,
        shell      => '/bin/sh',
        comment    => 'swiftrepl user',
        gid        => 'swiftrepl',
        managehome => false,
        system     => true,
    }

    file { '/var/log/swiftrepl':
        ensure  => directory, # don't clean up logs immediately, tidy{} eventually will
        owner   => 'swiftrepl',
        group   => 'swiftrepl',
        mode    => '0750',
        force   => true,
        require => User['swiftrepl'],
    }

    tidy { '/var/log/swiftrepl':
        age     => '15w',
        recurse => true,
        matches => '*.log',
    }

    git::clone { 'operations/software':
        ensure    => $ensure,
        directory => $basedir,
        branch    => 'master',
        owner     => 'swiftrepl',
        group     => 'swiftrepl',
    }

    file { '/usr/local/bin/swiftrepl-mw':
        ensure => $ensure,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => "puppet:///modules/${module_name}/swiftrepl-mw.sh",
    }

    $timer_interval = $source_site ? {
        'eqiad' => 'Mon *-*-* 08:00:00',
        'codfw' => 'Wed *-*-* 08:00:00',
    }

    systemd::timer::job { 'swiftrepl-mw':
        ensure          => $ensure,
        command         => '/usr/local/bin/swiftrepl-mw repl commons notcommons unsharded global timeline transcoded',
        description     => 'Ensure mediawiki containers are synchronized across sites',
        interval        => {'start' => 'OnCalendar', 'interval' => $timer_interval},
        logging_enabled => false,
        user            => 'swiftrepl',
    }

    # TODO(filippo) credentials for both source and destination sites are needed
    #file { "${basedir}/swiftrepl/swiftrepl.conf":
    #    owner   => 'swiftrepl',
    #    group   => 'swiftrepl',
    #    mode    => '0700',
    #    content => "${account}\n${password}\nhttps://ms-fe.svc.${destination_site}.wmnet/auth/v1.0\n",
    #}
}
