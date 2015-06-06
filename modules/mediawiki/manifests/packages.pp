class mediawiki::packages {
    include ::mediawiki::packages::php5
    require ::apt

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

    # PDF and DjVu
    package { [
        'djvulibre-bin',
        'librsvg2-bin',
        'libtiff-tools',
        'poppler-utils',
    ]:
        ensure => present,
    }

    # Fonts
    package { [
        'fonts-wqy-zenhei', # T84777
    ]:
        ensure => presemt,
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
