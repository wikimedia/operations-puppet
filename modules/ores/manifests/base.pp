# SPDX-License-Identifier: Apache-2.0
class ores::base(
    Stdlib::Unixpath $config_path = '/srv/deployment/ores/deploy',
    Stdlib::Unixpath $venv_path = '/srv/deployment/ores/deploy/venv',
) {
    # Let's use a virtualenv for maximum flexibility - we can convert
    # this to deb packages in the future if needed. We also install build tools
    # because they are needed by pip to install scikit.
    # FIXME: Use debian packages for all the packages needing compilation
    ensure_packages([
        'virtualenv', 'python3-dev', 'build-essential', 'gfortran', 'libopenblas-dev', 'liblapack-dev',
        # Install scipy via debian package so we don't need to build it via pip
        # takes forever and is quite buggy
        'python3-scipy',
        # It requires the enchant debian package
        'enchant',
    ])

    # this package got renamed in buster
    $hunspell_nl = debian::codename::lt('buster') ? {
        true    => 'myspell-nl',
        default => 'hunspell-nl',
    }
    # Spellcheck packages for supported languages
    ensure_packages([
        'aspell-ar',
        'aspell-el',
        'aspell-hi',
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
        'myspell-pt-pt',
        'myspell-pt-br',
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
    if debian::codename::ge('buster') {
        ensure_packages('hunspell-id')
    } else {
        ensure_packages('aspell-id')
    }
}
