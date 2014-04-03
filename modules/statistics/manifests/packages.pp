#Packages needed for building wikistats
class statistics::packages{ 

    # Perl packages needed for wikistats
    package { [
        'libjson-xs-perl',
        'libtemplate-perl',
        'libnet-patricia-perl',
        'libregexp-assemble-perl',
    ]:
        ensure => installed,
    }
    # pigz is used to unzip squid archive files in parallel
    package { 'pigz':
        ensure => installed,
    }

    #plotting libraries RT #2163
    package { [
            'ploticus',
            'libploticus0',
            'r-base',
            'r-cran-rmysql',
            'libcairo2',
            'libcairo2-dev',
            'libxt-dev'
        ]:
        ensure => installed,
    }
}

