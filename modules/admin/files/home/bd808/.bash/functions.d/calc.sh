# quick command line calculator
# arg *: calculator command (eg "1 + 2", "300^34", ...)
calc () {
  echo "$*" | bc -l
}

# vim:ft=sh:

