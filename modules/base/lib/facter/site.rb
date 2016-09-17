# Copyright (c) 2016 Wikimedia Foundation, Inc.
# Author: Giuseppe Lavagetto <joe@wikimedia.org>
#
# Fact: site
#
# Purpose: find the site the server is located in, from its ip address
#
Facter.add("site") do
  setcode do
    case Facter.value(:main_ipaddress)
    when /^208\.80\.15[23]\./, /^10\.19[26]\./
      'codfw'
    when /^208\.80\.15[45]\./, /^10\.6[48]\./
      'eqiad'
    when /^91\.198\.174\./, /^10\.20\.0\./
      'esams'
    when /^198\.35\.26\.([0-9]|[1-5][0-9]|6[0-2])/, /^10\.128\./
      'ulsfo'
    else
      '(undefined)'
    end
  end
end
