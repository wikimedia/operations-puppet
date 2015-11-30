class mediawiki::packages {
    include ::mediawiki::packages::php5
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
    ]:
        ensure => present,
    }

    package { [
        'php-mail',
        'php-mail-mime',
    ]:
        ensure => absent,
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
