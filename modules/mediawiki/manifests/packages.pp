# === Class mediawiki::packages
#
# Packages needed for mediawiki
class mediawiki::packages(
  $php7 = false,
) {
    if os_version('ubuntu == trusty') {
        include ::mediawiki::packages::php5
    }
    if os_version('debian == stretch') {
        if ($php7 == true) {
            apt::pin { 'php-luasandbox':
                package  => 'php-luasandbox',
                pin      => 'release a=stretch-backports',
                priority => '1010',
            }
            include ::mediawiki::packages::php7
        }
    }

    include ::mediawiki::packages::math
    include ::mediawiki::packages::tex

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
    # timidity recommends timidity-daemon, but we don't need it.
    package { 'timidity-daemon':
      ensure => absent,
    }

    require_package('firejail')
}
