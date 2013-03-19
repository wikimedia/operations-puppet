# University of Minnesota udp2log filter

$5 !~ /^(145\.97\.39\.|66\.230\.200\.|211\.115\.107\.)/ {print $3, $9}