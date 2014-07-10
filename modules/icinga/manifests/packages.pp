
class icinga::packages {

    # icinga: icinga itself
    # icinga-doc: files for the web-frontend

    package { [ 'icinga', 'icinga-doc' ]:
        ensure => latest,
    }

}

