# = Class: nagios_common::contacts
#
# Sets up appropriate contacts for notifications
#
# [*ensure*]
#   present or absent, to make the definition
#   present or absent. Defaults to present
#
# [*config_dir*]
#   The base directory to put configuration directory in.
#   Defaults to '/etc/icinga/'
#
# [*owner*]
#   The user which should own the check config files.
#   Defaults to 'icinga'
#
# [*group*]
#   The group which should own the check config files.
#   Defaults to 'icinga'
#
# [*contacts*]
#   The list of contacts to include in the configuration.
#
# [*source*]
#   Allows to input a prewritten file as a source.  Overrides "content" if
#   defined, but "content" is used if this is undefined.
# [*content*]
#   Allows to input the data as a content string.  The default is
#   template('nagios_common/contacts.cfg.erb')
#
class nagios_common::contacts(
    $ensure = present,
    $config_dir = '/etc/icinga',
    $source = undef,
    $content = undef,
    $owner = 'icinga',
    $group = 'icinga',
    $contacts = [],
) {
    if ($source != undef) {
        file { "${config_dir}/contacts.cfg":
            ensure    => $ensure,
            source    => $source,
            owner     => $owner,
            group     => $group,
            mode      => '0600', # Only $owner:$group can read/write
            show_diff => false,
        }
    } else {
        if ($content == undef or empty($content)) {
            $real_content = template('nagios_common/contacts.cfg.erb')
        } else {
            $real_content = $content
        }

        file { "${config_dir}/contacts.cfg":
            ensure    => $ensure,
            content   => $real_content,
            owner     => $owner,
            group     => $group,
            mode      => '0600', # Only $owner:$group can read/write
            show_diff => false,
        }

        $contacts = hiera('icinga_contact_secrets')
        # This 'new' file exists only temp during careful transition of contacts
        # from private repo and is not actually included by Icinga. --dz 20170505
        file { "${config_dir}/contacts-new.cfg":
            ensure  => $ensure,
            content => template('nagios_common/contacts-new.cfg.erb'),
            owner   => $owner,
            group   => $group,
            mode    => '0400',
        }
    }
}
