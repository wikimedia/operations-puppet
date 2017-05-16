#!/usr/bin/env bash
# foundational functions that other homedir scripts rely on

# Source a file if it exists
# arg *: file to source
source_file () {
  [[ ( -f "$*" ) && ( -r "$*" ) ]] && source "$*"
}

# Insert a new component in a list var (eg PATH)
#
# arg 1: list var to add to (PATH,MANPATH,etc)
# arg 2: new element to add
# arg 3: index or element to find (bash regex)
# arg 4: set to anything to insert after index rather than default before
list_insert () {
  local _var _new _idx _after _list _found
  _var=${1:?VAR required}
  _new=${2:?NEW required}
  _idx=${3:?INDEX required}
  _after=$4

  IFS=:
  _list=(${!_var})
  unset IFS

  if [[ $_idx =~ ^-?[0-9]+$ ]]; then
    # idx is a numeric position
    # convert negative index to distance from end of list
    [[ $_idx -lt 0 ]] && _idx=$((${#_list[@]} + $_idx))
    # advance to next item if inserting "after"
    [[ -n $_after ]] && _idx=$((_idx + 1))

  else
    # idx is value to search for
    _found=$_idx
    for ((i=0; i<=${#_list[@]}; ++i)); do
      if [[ ${_list[${i}]} =~ $_idx ]]; then
        _found=$i
        break;
      fi
    done

    if [[ $_found = $_idx ]]; then
      # value not found in list
      if [[ -n $_after ]]; then
        # append to list for "after"
        _idx=${#_list[@]}

      else
        # prepend to list
        _idx=0
      fi

    else
      # found the index of the desired item
      _idx=$_found
      # advance to next item if inserting "after"
      [[ -n $_after ]] && _idx=$((_idx + 1))
    fi
  fi

  # construct new list in place
  # (head new tail)
  [[ $_idx -lt 0 ]] && _idx=0
  _list=(${_list[@]:0:$_idx} $_new ${_list[@]:$_idx})

  IFS=:
  export $_var="${_list[*]}"
  unset IFS
} #end list_insert

# Check to see if a list var (eg PATH) contains a given element
#
# arg 1: list to check (PATH,MANPATH,etc)
# arg 2: element to find
list_contains () {
  local _var _elm _escelm _re
  _var=$1
  _elm=$2
  _escelm=${_elm//\\//\\\\}
  for c in \[ \] \( \) \. \^ \$ \? \* \+; do
    _escelm=${_escelm//"$c"/"\\$c"}
  done
  _re="(^|:)${_escelm}(:|$)"
  [[ ${!_var} =~ $_re ]]
}

# Add a new component to a list var (eg PATH) if it exists on the file system
# and it isn't already in the list.
#
# arg 1: list to add to (PATH,MANPATH,etc)
# arg 2: dir to add
# arg 3: set for append instead of push (optional)
# arg 4: index or element to find (bash regex) (optional)
list_add_dir () {
  local _var _dir _safedir _re
  _var=$1
  _dir=$2

  if [[ -d $_dir ]]; then
    list_contains $_var $_dir ||
    list_insert $_var $_dir ${4:-$_dir} $3
  fi
} #end list_add_dir


# Add directories to the LD_LIBRARY_PATH
# - Uses DYLD_LIBRARY_PATH on darwin!
# arg *: path to push onto LD_LIBRARY_PATH
add_library_path () {
  local VAR=LD_LIBRARY_PATH
  [[ "Darwin" = "$(uname -s)" ]] && VAR=DYLD_LIBRARY_PATH
  list_add_dir "${VAR}" "$*"
}

# Add well known dirs (bin, man, lib, info, etc) found in the given dir to
# the appropriate environment vars (PATH,MANPATH,LD_LIBRARY_PATH,INFOPATH)
# arg 1: root directory to scan for well known dirs
add_root_dir () {
  local DIR OS
  DIR="$1"
  OS=$(uname -s); OS=${OS/CYGWIN_*/CYGWIN}

  [[ -d "${DIR}/bin"        ]] && list_add_dir PATH "${DIR}/bin"
  [[ -d "${DIR}/bin/${OS}"  ]] && list_add_dir PATH "${DIR}/bin/${OS}"
  [[ -d "${DIR}/sbin"       ]] && list_add_dir PATH "${DIR}/sbin"
  [[ -d "${DIR}/man"        ]] && list_add_dir MANPATH "${DIR}/man"
  [[ -d "${DIR}/share/man"  ]] && list_add_dir MANPATH "${DIR}/share/man"
  [[ -d "${DIR}/info"       ]] && list_add_dir INFOPATH "${DIR}/info"
  [[ -d "${DIR}/share/info" ]] && list_add_dir INFOPATH "${DIR}/share/info"
  # bad things seem to happen with this being applied indescriminantly
  #][ -d "${DIR}/lib"        ]] && add_library_path "${DIR}/lib"
}

# Canonicalize an abstract pathname.
# Resolves symlinks and makes path absolute.
#
# arg 1: Path to make canonical
canonicalize () {
  if hash realpath &>/dev/null ; then
    realpath "${1}"

  else
    if [[ -d "$1" ]] ; then
      cd -P -- "${1}" &>/dev/null && pwd -P
    else
      cd -P -- "$(dirname -- "$1")" &>/dev/null &&
      echo "$(pwd -P)/$(basename -- "$1")"
    fi
  fi
}
# vim: se sw=2 ts=2 sts=2 et syntax=sh :
