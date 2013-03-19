# Vrije Universiteit udp2log filter

function savemark(url, code) {
	if (url ~ /action=submit$/ && code == "TCP_MISS/302")
		return "save"
	return "-"
}

$5 !~ /^(145\.97\.39\.|66\.230\.200\.|211\.115\.107\.)/ {
	print $3, $9, savemark($9, $6)
}
