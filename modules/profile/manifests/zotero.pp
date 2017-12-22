# Zotero is a free and open-source reference management software
# for bibliographic data and related research materials.
# See <https://en.wikipedia.org/wiki/Zotero>.
#
class profile::zotero {

    class { '::zotero': }

    ferm::service { 'zotero_http_1969':
        proto => 'tcp',
        port  => '1969',
    }

    # The check command is specific enough to warrant its own nagios command
    monitoring::service { 'zotero':
        description   => 'zotero',
        check_command => 'check_http_zotero!1969',
    }
}
