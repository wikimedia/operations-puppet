# === Class mediawiki::packages
#
# Packages needed for mediawiki
class mediawiki::packages {
    include ::mediawiki::packages::math
    include ::mediawiki::packages::tex

    include ::imagemagick::install

    package { [
        'python-imaging',
        'tidy',
        'libvips-tools',
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
        'ghostscript',
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
