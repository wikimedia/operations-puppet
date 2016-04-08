# === Class mediawiki::packages
#
# Packages needed for mediawiki
class mediawiki::packages {
    # Precise is still used on CI slaves for PHP 5.3 tests
    if os_version('ubuntu < trusty') {
        include ::mediawiki::packages::legacy
    } else {
        include ::mediawiki::packages::php5
    }

    include ::mediawiki::packages::math
    include ::mediawiki::packages::tex
    require ::apt

    package { [
        'imagemagick',
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
}
