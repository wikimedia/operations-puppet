# === Class mediawiki::packages
#
# Packages needed for mediawiki
class mediawiki::packages {
    if os_version('ubuntu == trusty') {
        include ::mediawiki::packages::php5
    }

    include ::mediawiki::packages::math
    include ::mediawiki::packages::tex
    require ::apt

    include ::imagemagick::install

    package { [
        'python-imaging',
        'python-pygments',
        'tidy',
    ]:
        ensure => present,
    }

    # Pear
    package { [
        'php-pear',
        'php-mail',
        'php-mail-mime',
    ]:
        ensure => present,
    }

    # PDF and DjVu
    package { [
        'djvulibre-bin',
        'librsvg2-bin',
        'libtiff-tools',
        'poppler-utils',
    ]:
        ensure => present,
    }

    # Score
    package { [
        'lilypond',
        'timidity',
        'freepats',
    ]:
        ensure => present,
    }

    # Lilypond missed stretch as it wasn't ported to Guile 2, later versions bundled
    # a local copy of Guile 1.8, install it from backports
    if os_version('debian == stretch') {
        apt::pin { 'lilypond':
            package  => 'lilypond',
            pin      => 'release a=stretch-backports',
            priority => '1001',
            before   => Package['lilypond'],
        }
    }

    # timidity recommends timidity-daemon, but we don't need it.
    package { 'timidity-daemon':
      ensure => absent,
    }

    require_package('firejail')
}
