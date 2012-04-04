<?php
# FIXME - replace this ugly beast
if (isset($_GET['sort'])) {

	switch ($_GET['sort']) {
	case "name_asc":
		$sort = "name asc";
	break;
	case "name_desc":
		$sort = "name desc";
	break;
	case "good_asc":
		$sort = "good asc";
	break;
	case "good_desc":
		$sort = "good desc";
	break;
	case "total_asc":
		$sort = "total asc";
	break;
	case "total_desc":
		$sort = "total desc";
	break;
	case "edits_asc":
		$sort = "edits asc";
	break;
	case "edits_desc":
		$sort = "edits desc";
	break;
	case "views_asc":
		$sort = "views asc";
	break;
	case "views_desc":
		$sort = "views desc";
	break;
	case "admins_asc":
		$sort = "admins asc";
	break;
	case "admins_desc":
		$sort = "admins desc";
	break;
	case "users_asc":
		$sort = "users asc";
	break;
	case "users_desc":
		$sort = "users desc";
	break;
	case "ausers_asc":
		$sort = "activeusers asc";
	break;
	case "ausers_desc":
		$sort = "activeusers desc";
	break;
	case "activeusers_asc":
		$sort = "activeusers asc";
	break;
	case "activeusers_desc":
		$sort = "activeusers desc";
	break;
	case "ts_asc":
		$sort = "ts asc";
	break;
	case "ts_desc":
		$sort = "ts desc";
	break;
	case "ratio_asc":
		$sort = "ratio asc";
	break;
	case "ratio_desc":
		$sort = "ratio desc";
	break;
	case "started_asc":
		$sort = "started asc";
	break;
	case "started_desc":
		$sort = "started desc";
	break;
	case "type_asc":
		$sort = "type asc";
	break;
	case "type_desc":
		$sort = "type desc";
	break;
	case "images_asc":
		$sort ="images asc";
	break;
	case "images_desc":
		$sort = "images desc";
	break;
	case "prefix_asc":
		$sort = "prefix asc";
	break;
	case "prefix_desc":
		$sort = "prefix desc";
	break;
	case "lang_asc":
		$sort = "lang asc";
	break;
	case "lang_desc":
		$sort = "lang desc";
	break;
	case "loclang_asc":
		$sort = "loclang asc";
	break;
	case "loclang_desc":
		$sort = "loclang desc";
	break;
	case "version_asc":
		$sort = "substring(version,3,2) asc";
	break;
	case "version_desc":
		$sort = "substring(version,3,2) desc";
	break;
	case "gettype_asc":
		$sort = "gettype asc";
	break;
	case "gettype_desc":
		$sort = "gettype desc";
	break;
	case "domain_asc":
		$sort = "tld asc";
	break;
	case "domain_desc":
		$sort = "tld desc";
	break;
	case "stype_asc":
		$sort = "textstats asc,http asc";
	break;
	case "stype_desc":
		$sort = "textstats desc,http asc";
	break;
	case "id_asc":
		$sort = "id asc";
	break;
	case "id_desc":
		$sort = "id desc";
	break;
	case "http_asc":
		$sort = "http asc";
	break;
	case "http_desc":
		$sort = "http desc";
	break;
	case "hexip_asc":
		$sort = "hexip asc";
	break;
	case "hexip_desc":
		$sort = "hexip desc";
	break;
	case "link_asc":
		$sort = "link asc";
	break;
	case "link_desc":
		$sort = "link desc";
	break;
	case "title_asc":
		$sort = "title asc";
	break;
	case "title_desc":
		$sort = "title desc";
	break;
	case "numwikis_asc":
		$sort = "numwikis asc";
	break;
	case "numwikis_desc":
	$sort = "numwikis desc";
	break;

	default:
	$sort = "good desc,total desc";
	}
} else {
	$sort = "good desc,total desc";
}
?>
