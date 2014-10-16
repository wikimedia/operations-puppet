class mediawiki::packages {
    include mediawiki::packages::php5

    package { [
        'imagemagick',
        'libmemcached10', # TODO: remove this?
        'python-imaging',
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
        'mediawiki-math-texvc',
    ]:
        ensure => present,
    }

    # on trusty, mediawiki-math-texvc brings mysql with it!
    if ubuntu_version('>= trusty') {
        package { [
            'mysql-server',
            'mysql-server-5.5',
        ]:
            ensure => absent,
        }
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
}
