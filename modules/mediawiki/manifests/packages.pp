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
        'tidy',
    ]:
        ensure => present,
    }

    # Pygments uses Python 3, and bundles
    # its own copy of the library.
    package { 'python3':
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
