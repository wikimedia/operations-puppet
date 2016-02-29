if [ -n "$BASH_VERSION" -a -n "$PS1" ]; then
  # Extract a particular field from separator-delimited input.
  # For example:
  #
  #   field 2 /var/log/apache2/apache2.log
  #
  # ..is equivalent to:
  #
  #   awk '{ print $2 }' /var/log/apache2/apache2.log
  #
  field() {
    local fieldnum="$1"
    shift
    /usr/bin/awk -v field="$fieldnum" '{print $(field)}' "${@}"
  }

  # Take a line from stdin and show a numbered list of its fields.
  # This helps you know which numeric index to use (with `field`)
  # to extract a particular column.
  #
  # Example:
  #
  #   $ fields /var/log/apache2/other_vhosts_access.log
  #   1 : 2016-02-29T21:50:05
  #   2 : 75415
  #   3 : 10.64.17.9
  #   4 : proxy-server/200
  #   5 : 14623
  #   6 : GET
  #   7 : http://en.wikipedia.org/wiki/Special:BlankPage
  #   8 : -
  #   9 : text/html
  #   10 : -
  #   11 : -
  #   12 : Twisted
  #   13 : PageGetter
  #   14 : -
  #   15 : -
  #   16 : -
  #   17 : 10.64.17.9
  #
  fields() {
    /usr/bin/tail -1 "${@:---}" | /usr/bin/awk 'END { for (i = 1; i <= NF; i++) printf("%s : %s\n", i, $i) }'
  }
fi
