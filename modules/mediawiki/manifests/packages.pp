class mediawiki::packages {
    package { [
        'imagemagick',
        'python-imaging',
        'libmemcached10',       # XXX still needed?
        'php-apc',
        'php-pear',
        'php5-cli',
        'php5-common',
    ]:
        ensure => present,
    }

    # Standard PHP extensions
    package { [
        'php5-curl',
        'php5-geoip',
        'php5-intl',
        'php5-memcached',
        'php5-mysql',
        'php5-redis',
        'php5-xmlrpc',
    ]:
        ensure => present,
    }

    # Wikimedia-specific PHP extensions
    package { [
        'php-luasandbox',
        'php-wikidiff2',
        'php5-fss',
    ]:
        ensure => present,
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

    if $::lsbdistcodename == 'precise' {
        package { [
            'libmemcached11',  # formerly a dependency for php5-memcached
            'php5-igbinary',   # no longer in use
            'php5-wmerrors',   # functionality built-in to HHVM
        ]:
            ensure => present,
        }
    }
}
