# the update scripts fetching data (input) for wikistats
# and writing it to local mariadb
#FIXME - this was used in labs in the past but is gone unfortunately
#require misc::mariadb::server
class wikistats::updates {

    # update scripts are PHP-cli
    package { 'php5-cli': ensure => latest; }

    # log dir for wikistats
    file { '/var/log/wikistats':
        ensure => directory,
        mode   => '0664',
        owner  => 'wikistatsuser',
        group  => 'wikistatsuser',
    }

    # update cron jobs: usage: <project prefix>@<hour>
    wikistats::cronjob { [
                'wp@0',  # Wikipedias
                'lx@1',  # LXDE
                'wt@2',  # Wiktionaries
                'ws@3',  # Wikisources
                'wn@4',  # Wikinews
                'wb@5',  # Wikibooks
                'wq@6',  # Wikiquotes
                'os@7',  # OpenSUSE
                'gt@8',  # Gentoo
                'an@9',  # Anarchopedias
                'wf@10', # Wikifur
                'wv@11', # Wikiversities
                'sc@12', # Scoutwikis
                'ne@13', # Neoseeker
                'wr@14', # Wikitravel
                'et@15', # EditThis
                'mt@16', # Metapedias
                'un@17', # Uncylomedias
                'wx@18', # Wikimedia Special
                'mw@19', # Mediawikis
                'sw@20', # Shoutwikis
                'ro@21', # Rodovid
                'wk@21', # Wikkii
                're@22', # Referata
                'pa@23', # Pardus
                ]: }

}
