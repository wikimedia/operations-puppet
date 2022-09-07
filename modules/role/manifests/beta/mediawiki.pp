class role::beta::mediawiki {
    include profile::beta::mediawiki
    # Install locally needed packages T317128
    include profile::beta::mediawiki_packages
}
