# === Class mediawiki::packages
#
# Packages needed for mediawiki
class mediawiki::packages {
    # Precise is still used on CI slaves for PHP 5.3 tests
    if os_version('ubuntu < trusty') {
        include ::mediawiki::packages::legacy
    } elsif os_version('ubuntu == trusty') {
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
    ]:
        ensure => present,
    }

    package { [
        'php-mail',
        'php-mail-mime',
    ]:
        ensure => absent,
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

    if os_version('debian >= jessie || ubuntu >= trusty') {
        require_package('firejail')
    }
}
