# == class profile::kerberos::keytabs
#
# Deploy keytabs based on metadata provided in input.
#
# == Parameters
#  [*keytabs_metadata*]
#    Array of hash tables having the following format:
#    [{'role' => 'hadoop', 'owner': 'hdfs', group: 'hdfs', filename: 'hdfs.keytab', parent_dir_grp: 'hadoop'} ..]
#    Keytabs needs to be present in the private puppet repository.
#    The user indicated as 'owner' of the keytab needs to be present in the catalog
#    (since it is required to properly create the keytab). The related groups are not
#    explicitly required, as it is assumed to be present.
#    The 'parent_dir_grp is optional, if not set it defaults to the value of 'group'.
#
class profile::kerberos::keytabs (
    Array $keytabs_metadata = lookup('profile::kerberos::keytabs::keytabs_metadata', { 'default_value' => [] })
){

    $keytabs_metadata.each |Hash $keytab_metadata| {

        if !defined(File["/etc/security/keytabs/${keytab_metadata['role']}"]) {
            $parent_dir_grp = $keytab_metadata['parent_dir_grp'] ? {
                undef   => $keytab_metadata['group'],
                default => $keytab_metadata['parent_dir_grp'],
            }
            file { "/etc/security/keytabs/${keytab_metadata['role']}":
                ensure  => 'directory',
                owner   => $keytab_metadata['owner'],
                group   => $parent_dir_grp,
                mode    => '0550',
                require => File['/etc/security/keytabs']
            }
        }

        file { "/etc/security/keytabs/${keytab_metadata['role']}/${keytab_metadata['filename']}":
            ensure    => 'present',
            owner     => $keytab_metadata['owner'],
            group     => $keytab_metadata['group'],
            mode      => '0440',
            content   => secret("kerberos/keytabs/${::fqdn}/${keytab_metadata['role']}/${keytab_metadata['filename']}"),
            show_diff => false,
            require   => [File["/etc/security/keytabs/${keytab_metadata['role']}"], User[$keytab_metadata['owner']]]
        }
    }
}
