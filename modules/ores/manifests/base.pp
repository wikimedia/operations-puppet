class ores::base(
    $branch = 'deploy',
    $config_path = '/srv/ores/config',
    $venv_path = '/srv/ores/venv',
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

    # Spellcheck packages for supported languages
    require_package('aspell-ar', 'aspell-id', 'aspell-pl',
                    'hunspell-vi',
                    'myspell-de-at', 'myspell-de-ch', 'myspell-de-de',
                    'myspell-en-au', 'myspell-en-gb', 'myspell-en-us',
                    'myspell-es',
                    'myspell-et',
                    'myspell-fa',
                    'myspell-fr',
                    'myspell-he',
                    'myspell-it',
                    'myspell-nl',
                    'myspell-pt',
                    'myspell-uk')

    file { '/srv/ores':
        ensure => directory,
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0775',
    }

    file { $config_path:
        ensure  => directory,
        owner   => 'www-data',
        group   => 'www-data',
        require => File['/srv/ores'],
    }
}
