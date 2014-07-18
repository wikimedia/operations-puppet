class mediawiki::packages {
    package { [
        'python-imaging',
        'libmemcached10',       # XXX still needed?
        'libmemcached11',
        'php5-common',
    ]:
        ensure => present,
    }

    # FIXME: This conflicted with contint::packages
    ensure_packages([
        'imagemagick',
        'php-pear',
        'php5-cli',
    ])

    # FIXME: This conflicted with contint::packages
    if ! defined ( Package['php-apc'] ) {
        package { 'php-apc':
            ensure => present,
        }
    }

    # Standard PHP extensions
    package { [
        'php5-geoip',
        'php5-igbinary',
        'php5-memcached',
        'php5-redis',
        'php5-xmlrpc',
    ]:
        ensure => present,
    }
    # FIXME: This conflicted with contint::packages
    ensure_packages([
        'php5-curl',
        'php5-mysql',
        'php5-intl',
    ])

    # Wikimedia-specific PHP extensions
    package { [
        'php-wikidiff2',
        'php5-wmerrors',
        'php5-fss',
    ]:
        ensure => present,
    }
    # FIXME: This conflicted with contint::packages
    if ! defined ( Package['php-luasandbox'] ) {
        package { 'php-luasandbox':
            ensure => present,
        }
    }

    # Pear modules
    package { [
        'php-mail',
        'php-mail-mime',
    ]:
        ensure => present,
    }

    # TeX packages
    package { [
        'texlive',
        'texlive-bibtex-extra',
        'texlive-font-utils',
        'texlive-fonts-extra',
        'texlive-lang-all',
        'texlive-latex-extra',
        'texlive-math-extra',
        'texlive-pictures',
        'texlive-pstricks',
        'texlive-publishers',
    ]:
        ensure => present,
    }

    # Math
    package { [
        'dvipng',
        'gsfonts',
        'make',
        'ocaml',
        'ploticus',
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
    ]:
        ensure => present,
    }
    # timidity recommends timidity-daemon, but we don't need it.
    package { 'timidity-daemon':
      ensure => absent,
    }

    # Tidy
    package { [
        'libtidy-0.99-0',
        'tidy',
    ]:
        ensure => present,
    }
}
