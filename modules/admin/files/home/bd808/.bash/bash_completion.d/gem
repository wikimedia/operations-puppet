#!/bin/bash
# -*- mode: bash -*-
#
#     ---------------------------
#   --= bash completion for the =--
#   --= rubygems "gem" program  =--
#     ---------------------------
#
# Copyright C 2011 Brent Sanders <git@thoughtnoise.net>
#  -> Derived losely from "git-completion.sh" in the git-sh
#     package, copyright C 2006,2007 Shawn O. Pearce <spearce@spearce.org>
#      -> Conceptually based on gitcompletion (http://gitweb.hawaga.org.uk/).
#         Distributed under the GNU General Public License, version 2.0.
#
# I have tested with these rubygems versions during development
# and several months of practical use:
#      - 1.8.10
#      - 1.8.11
#      - 1.8.15
#
# It almost certainly works on related versions, as the interface
# dosn't change THAT often. You will run into trouble on very old versions,
# though, and who knows what the future brings. When in doubt, compare the
# relevant "_git_FOO" function with the output of "gem help FOO"
#
# Writing your own aliases?
# Wrapping gem in some function?
#  ||
#  |+-> See the end of this file for examples of
#  +--> extending completion into your stuff!!!
#
#
# ChangeLog:
#
#   * 2012/01/27 - added some comments, added example of
#                  aliasing gem with completion, cleaned
#                  up the wrapping sanity-check
#
#   * 2011/12/16 - added matching filenames, filtered by extension,
#                  which is used already in a few places
#
#   * 2011/12/16 - remove use of stale bash features. (defining funs
#                  with the keyword 'function' is apparently not POSIX)
#
#   * 2011/11/30 - Initial Release
#


#########################
# first, a SANITY CHECK #
#########################

__gem_iscmd()   {
    command hash "$1" 2>&-
}
__gem_missing() {
    ! __gem_iscmd gem
}
__gem_cleanable="__gem_cleanable __gem_iscmd __gem_missing"

if __gem_missing ; then
    # We should play nice with the bash environment, and not
    # pollute the namespace if we can't actually do anything useful.
    unset ${__gem_cleanable}
    return 1
fi
# good, 'gem' exists - proceed with init


###################
# compgen wrapper #
###################

__gemcomp() {
    local all c s=$'\n' IFS=' '$'\t'$'\n'
    local cur="${COMP_WORDS[COMP_CWORD]}"
    if [[ $# -gt 2 ]] ; then
        cur="$3"
    fi
    for c in $1; do
        case "$c$4" in
            --*=*) all="$all$c$4$s" ;;
            *.)    all="$all$c$4$s" ;;
            *)     all="$all$c$4 $s" ;;
        esac
    done
    IFS=$s
    COMPREPLY=($(compgen -P "$2" -W "$all" -- "$cur"))
    return
}


##########################
# <EXTERNAL> completions #
##########################

__gem_complete_file() {
    local IFS=$'\n'
    local EXT cur="${COMP_WORDS[COMP_CWORD]}"
    [[ -n "$1" ]] && EXT=".$1" || EXT=''
    COMPREPLY=( "${COMPREPLY[@]}" $( command ls -aF1d $cur*$EXT 2>/dev/null | sed -e 's/[*@|=]$//g' -e 's/[^\/]$/& /g' -e "s/^/$1/") )
}

__gem_complete_gemname() {
    __gemcomp "$(gem list --no-details --no-versions)"
}

__gem_complete_gemnameversion() {
    __gem_complete_gemname
}


######################################
# Standard Options for most commands #
######################################

__gem_stdopt_short() {
    echo "-h -V -q"
}

__gem_stdopt_long() {
    echo "--help --verbose --no-verbose --quiet --config-file= --backtrace --debug"
}

__gem_options() {
    local cur="${COMP_WORDS[COMP_CWORD]}" short="$1" long="$2"
    shift 2
    case "$cur" in
        --*)
            __gemcomp "$(__gem_stdopt_long) ${long}"
            return
            ;;
        -*)
            __gemcomp "$(__gem_stdopt_short) ${short}"
            return
            ;;
    esac
    COMPREPLY=()
}

__gem_localremote_options() {
    local short="$1" long="$2"
    shift 2
    __gem_options "-l -r -b -B -p ${short}" "\
        --local
        --remote
        --both
        --bulk-threshold=
        --clear-sources
        --source=
        ${long}"
}

__gem_installupdate_options() {
    local short="$1" long="$2"
    shift 2
    __gem_localremote_options "-i -n -d -E -f -w -P -W ${short}" "\
        --install-dir=
        --bindir=
        --rdoc --no-rdoc
        --ri --no-ri
        --env-shebang --no-env-shebang
        --force --no-force
        --wrappers --no-wrappers
        --trust-policy=
        --ignore-dependencies
        --include-dependencies
        --format-executable --no-format-executable
        --user-install --no-user-install
        --development
        --conservative
        ${long}"
}

__gem_gemnames_or_options() {
    case "${COMP_WORDS[COMP_CWORD]}" in
        -*) __gem_options "$@" ;;
        *)  __gem_complete_gemname ;;
    esac
}

__gem_gemnames_or_localremote_options() {
    case "${COMP_WORDS[COMP_CWORD]}" in
        -*) __gem_localremote_options "$@" ;;
        *)  __gem_complete_gemname ;;
    esac
}


__gem_gemnames_or_installupdate_options() {
    case "${COMP_WORDS[COMP_CWORD]}" in
        -*) __gem_installupdate_options "$@" ;;
        *)  __gem_complete_gemname ;;
    esac
}

__gem_files_or_options() {
    case "${COMP_WORDS[COMP_CWORD]}" in
        -*) __gem_options "$@" ;;
        *)  __gem_complete_file ;;
    esac
}


#########################
# <BUILTIN> completions #
#########################

# this looks ugly, but is preparation
# for future automation
read -r -d '' GEM_COMMAND_LIST <<'ALLGEMCOMMANDS'
build
cert
check
cleanup
contents
dependency
environment
fetch
generate_index
help
install
list
lock
outdated
owner
pristine
push
query
rdoc
search
server
sources
specification
stale
uninstall
unpack
update
which
ALLGEMCOMMANDS


_gem_build() {
    case "${COMP_WORDS[COMP_CWORD]}" in
        -*) __gem_options "$@" ;;
        *)  __gem_complete_file gemspec ;;
    esac
}

_gem_cert() {
    __gem_options '-a -l -r -b -C -K -s' '\
        --add=
        --list
        --remove=
        --build=
        --certificate=
        --private-key=
        --sign='
}

_gem_check() {
    __gem_options '-a -v' '\
        --verify=
        --alien
        --version='
}

_gem_cleanup() {
    __gem_gemnames_or_options '-d' '--dryrun'
}

_gem_contents() {
    __gem_gemnames_or_options '-v -s -l' '\
        --version=
        --all
        --spec-dir=
        --lib-only --no-lib-only
        --prefix --no-prefix'
}

_gem_dependency() {
    __gem_gemnames_or_localremote_options '-v -R' '\
        --version=
        --platform=
        --prerelease --no-prerelease
        --reverse-dependencies --no-reverse-dependencies
        --pipe'
}

_gem_environment() {
    case "${COMP_WORDS[COMP_CWORD]}" in
        -*) __gem_options ;;
        *)  __gemcomp "packageversion gemdir gempath version remotsources platform" ;;
    esac
}

_gem_fetch() {
    __gem_gemnames_or_options '-v -B -p', '\
        --version=
        --platform=
        --prerelease --no-prerelease
        --bulk-threshold=
        --http-proxy --no-http-proxy
        --source='
}

_gem_generate_index() {
    __gem_options '-d' '\
        --directory=
        --legacy --no-legacy
        --modern --no-modern
        --update
        --rss-gems-host=
        --rss-host=
        --rss-title='
}

_gem_help() {
    case "${COMP_WORDS[COMP_CWORD]}" in
        -*) __gem_options ;;
        *)  __gemcomp "commands examples ${__gem_commandlist}" ;;
    esac
}

_gem_install() {
    __gem_gemnames_or_installupdate_options '-v' '\
        --platform=
        --version=
        --prerelease --no-prerelease'
}

_gem_list() {
    __gem_options "-i -v -d -a" "\
        --installed --no-installed
        --version
        --details --no-details
        --versions --no-versions
        --all"
}

_gem_lock() {
    case "${COMP_WORDS[COMP_CWORD]}" in
        -*) __gem_options '-s' '--strict --no-strict' ;;
        *)  __gem_complete_gemnameversion ;;
    esac
}

_gem_outdated() {
    __gem_localremote_options '' '--platform='
}

_gem_owner() {
    __gem_options '-k -a -r -p' '\
        --key=
        --add=
        --remote=
        --http-proxy --no-http-proxy'
}

_gem_pristine() {
    __gem_gemnames_or_options '-v' '\
        --all
        --extensions --no-extensions
        --version='
}

_gem_push() {
    case "${COMP_WORDS[COMP_CWORD]}" in
        -*) __gem_options '-k -p' '--key= --host= --http-proxy --no-http-proxy' ;;
        *)  __gem_complete_file gem ;;
    esac
}

_gem_query() {
    __gem_localremote_options '-i -v -n -d -a' '\
      --installed --no-installed
      --version=
      --name-matches=
      --details --no-details
      --versions --no-versions
      --all
      --prerelease --no-prerelease'
}

_gem_rdoc() {
    __gem_gemnames_or_options '-v' '\
        --all
        --rdoc --no-rdoc
        --ri --no-ri
        --overwrite --no-overwrite
        --version='
}

_gem_search() {
    case "${COMP_WORDS[COMP_CWORD]}" in
        -*) __gem_localremote_options '-i -v -d -a' '\
                --installed --no-installed
                --version=
                --details --no-details
                --versions --no-versions
                --all
                --prerelease --no-prerelease'
            ;;
        *) COMPREPLY=() ;;
    esac
}

_gem_server() {
    __gem_options '-p -d -b -l' '\
        --port=
        --dir=
        --daemon --no-daemon
        --bind=
        --launch'
}

_gem_sources() {
    __gem_options '-a -l -r -c -u -p' '\
        --add=
        --list
        --remove=
        --clear-all
        --update
        --http-proxy --no-http-proxy'
}

_gem_specification() {
    case ${COMP_CWORD} in
        2) __gem_complete_gemname ;;
        3) __gemcomp "\
               name
               version
               platform
               authors
               autorequire
               bindir
               cert_chain
               date
               dependencies
               description
               email
               executables
               extensions
               extra_rdoc_files
               files
               homepage
               licenses
               post_install_message
               rdoc_options
               require_paths
               required_ruby_version
               required_rubygems_version
               requirements
               rubyforge_project
               rubygems_version
               signing_key
               specification_version
               summary
               test_files"
            ;;
        *) __gem_localremote_options '-v' '\
               --version=
               --platform=
               --all
               --ruby
               --yaml
               --marshal'
            ;;
    esac
}

_gem_stale() {
    __gem_options
}

_gem_uninstall() {
    __gem_gemnames_or_options '-a -I -x -i -n -v' '\
        --all --no-all
        --ignore-dependencies --no-ignore-dependencies
        --executables --no-executables
        --install-dir=
        --bindir=
        --user-instal --no-user-install
        --format-executable --no-format-executable
        --version=
        --platform='
}

_gem_unpack() {
    __gem_gemnames_or_options '-v' '--target= --spec --version='
}

_gem_update() {
    __gem_gemnames_or_installupdate_options '' '\
        --system
        --platform=
        --prerelease --no-prerelease'
}

_gem_which() {
    __gem_files_or_options '-a -g' '\
        --all --no-all
        --gems-first --no-gems-first'
}


###############################
# toplevel wrapper completion #
###############################

__gem() {
    case "${COMP_WORDS[COMP_CWORD]}" in
        --*=*) COMPREPLY=() ;;
        --*)   __gemcomp "--help --version" ;;
        -*)    __gemcomp "-h -v" ;;
        *)     __gemcomp "${GEM_COMMAND_LIST}" ;;
    esac
}

_gem() {
    local gemcmd

    [[ $COMP_CWORD -gt 1 ]] && gemcmd="${COMP_WORDS[1]}"
    [[ $COMP_CWORD -eq 1 ]] && [[ -z "$gemcmd" ]] && __gem && return

    case "$gemcmd" in
        build)          _gem_build ;;
        cert)           _gem_cert ;;
        check)          _gem_check ;;
        cleanup)        _gem_cleanup ;;
        contents)       _gem_contents ;;
        dependency)     _gem_dependency ;;
        environment)    _gem_environment ;;
        fetch)          _gem_fetch ;;
        generate_index) _gem_generate_index ;;
        help)           _gem_help ;;
        install)        _gem_install ;;
        list)           _gem_list ;;
        lock)           _gem_lock ;;
        outdated)       _gem_outdated ;;
        owner)          _gem_owner ;;
        pristine)       _gem_pristine ;;
        push)           _gem_push ;;
        query)          _gem_query ;;
        rdoc)           _gem_rdoc ;;
        search)         _gem_search ;;
        server)         _gem_server ;;
        sources)        _gem_sources ;;
        specification)  _gem_specification ;;
        stale)          _gem_stale ;;
        uninstall)      _gem_uninstall ;;
        unpack)         _gem_unpack ;;
        update)         _gem_update ;;
        which)          _gem_which ;;
        *)           COMPREPLY=() ;;
    esac
}


###########################################
# Finally, tie it all together with the a #
# single call to the 'complete' builtin.  #
###########################################

# required params:
#   - completion function
#   - command to complete
_gemcomp() {
    complete -o default -o nospace -F "$@"
}
_gemcomp _gem gem


##############################
# EXTENDING completion into  #
# your own functions/aliases #
##############################

# do you want to alias 'gem' itself?
# then use this to tie in the completion
#
#alias rg="command gem"
#_gemcomp _gem rg

# perhaps more useful, might be to alias to an
# internal gem command+options? In that case,
# you can skip _gem and go right to the specific
# completion funcion
#
#alias gi="command gem install --verbose"
#_gemcomp _gem_install gi



######################################
# ...and finally, unload what we can #
######################################

unset ${__gem_cleanable}
return 0
#EOF
