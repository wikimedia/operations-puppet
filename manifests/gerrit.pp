# manifests/gerrit.pp

# Our Gerrit configuration
class gerrit::gerrit_config {

	include openstack::nova_config,
		passwords::gerrit

	$gerrit_hostname = "gerrit.wikimedia.org"
	$gerrit_username = "gerrit2"
	$gerrit_pass = $passwords::gerrit::gerrit_pass
	$gerrit_sshport = "29418"
	$gerrit_url = 'https://gerrit.wikimedia.org/r/'
	$gerrit_db_host = "db9.pmtpa.wmnet"
	$gerrit_db_name = "reviewdb"
	$gerrit_db_user = "gerrit"
	$gerrit_db_pass = $passwords::gerrit::gerrit_db_pass
	$gerrit_ldap_host = ["$openstack::nova_config::nova_ldap_host", "virt1000.wikimedia.org"]
	$gerrit_ldap_base_dn = $openstack::nova_config::nova_ldap_base_dn
	$gerrit_ldap_proxyagent = $openstack::nova_config::nova_ldap_proxyagent
	$gerrit_ldap_proxyagent_pass = $openstack::nova_config::nova_ldap_proxyagent_pass
	$gerrit_listen_url = 'proxy-https://127.0.0.1:8080/r/'
	$gerrit_session_timeout = "90 days"

}
