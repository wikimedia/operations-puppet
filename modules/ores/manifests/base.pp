class ores::base(
    Stdlib::Unixpath $config_path = '/srv/deployment/ores/deploy',
    Stdlib::Unixpath $venv_path = '/srv/deployment/ores/deploy/venv',
) {
    # Let's use a virtualenv for maximum flexibility - we can convert
    # this to deb packages in the future if needed. We also install build tools
    # because they are needed by pip to install scikit.
    # FIXME: Use debian packages for all the packages needing compilation
    require_package('virtualenv', 'python3-dev', 'build-essential',
                    'gfortran', 'libopenblas-dev', 'liblapack-dev')

    # Install scipy via debian package so we don't need to build it via pip
    # takes forever and is quite buggy
    require_package('python3-scipy')

    # It requires the enchant debian package
    require_package('enchant')

    # this package got renamed in buster
    $hunspell_nl = os_version('debian < buster') ? {
        true    => 'myspell-nl',
        default => 'hunspell-nl',
    }
    # Spellcheck packages for supported languages
    require_package([
        'aspell-ar',
        'aspell-el',
        'aspell-pl',
        'aspell-sv',
        'aspell-ro',
        'aspell-is',
        'aspell-uk',
        'myspell-cs',
        'myspell-de-at',
        'myspell-de-ch',
        'myspell-de-de',
        'myspell-en-au',
        'myspell-es',
        'myspell-et',
        'myspell-fa',
        'myspell-fr',
        'myspell-he',
        'myspell-hu',
        'myspell-lv',
        'myspell-nb',
        'myspell-pt',
        'myspell-ru',
        'myspell-hr',
        $hunspell_nl,
        'hunspell-bs',
        'hunspell-ca',
        'hunspell-en-us',
        'hunspell-en-gb',
        'hunspell-eu',
        'hunspell-gl',
        'hunspell-it',
        'hunspell-sr',
        'hunspell-vi',
    ])

    # NOTE: aspell-id is imported in our apt up to Stretch:
    # https://apt.wikimedia.org/wikimedia/pool/thirdparty/a/aspell-id/
    if os_version('debian >= buster') {
        require_package('hunspell-id')
    } else {
        require_package('aspell-id')
    }
}
