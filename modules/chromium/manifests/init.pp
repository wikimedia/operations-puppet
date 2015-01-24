# == Class: chromium
#
# Chromium is the open source web browser project from which Google
# Chrome draws its source code. This Puppet module provisions a browser
# instance that runs in headless mode and that can be automated by
# various tools.
#
# === Parameters
#
# [*display*]
#   X display number. Default: 99.
#
# [*incognito*]
#   If true, runs Chromium in "incognito" mode, meaning history and
#   session data will not persist across runs. Default: true.
#
# [*remote_debugging_port*]
#   Port on which Chromium will listen for remote debugging clients.
#   See <https://developers.google.com/chrome-developer-tools/docs/debugger-protocol>.
#   Default: 9222.
#
# [*extra_args*]
#   Additional arguments to pass to Chromium.
#   See <http://peter.sh/experiments/chromium-command-line-switches/>.
#   Default: no additional arguments.
#
# === Examples
#
#  class { 'chromium':
#     extra_args => '--user-data-dir=/srv/chromium',
#  }
#
class chromium(
    $ensure                = present,
    $display               = 99,
    $incognito             = true,
    $remote_debugging_port = 9222,
    $extra_args            = '--',
) {
    include xvfb

    group { 'chromium':
        ensure => $ensure,
    }

    user { 'chromium':
        ensure     => $ensure,
        gid        => 'chromium',
        shell      => '/bin/false',
        home       => '/var/lib/chromium',
    }

    apt::repository { 'chromium_dev':
        ensure     => $ensure,
        uri        => 'http://ppa.launchpad.net/saiarcot895/chromium-dev/ubuntu',
        dist       => 'trusty',
        components => 'main',
        keyfile    => 'puppet:///modules/chromium/chromium-ppa.key',
    }

    package { 'chromium-browser':
        ensure  => $ensure,
        require => Apt::Repository['chromium_dev'],
    }

    file { '/etc/init/chromium.conf':
        ensure  => $ensure,
        content => template('chromium/chromium.conf.erb'),
        require => User['chromium'],
    }

    service { 'chromium':
        ensure    => ensure_service($ensure),
        provider  => 'upstart',
        subscribe => [
            Service['xvfb'],
            Package['chromium-browser'],
            File['/etc/init/chromium.conf'],
        ],
    }
}
