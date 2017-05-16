#!/usr/bin/env bash

# compatible with virtualenvwrapper created envs
: ${VENV_DIR=${WORKON_HOME:=${HOME}/.virtualenvs}}

venv () {
  local vdir=${VENV_DIR:=${HOME}/.venv}
  local cmd=${1}
  shift

  [[ -d $vdir ]] || mkdir -p "${vdir}"

  case "$cmd" in
    create)
      local name=${1:?env NAME required}
      shift
      if [[ -d "${vdir}/${name}" ]]; then
        printf "${name} already exists. Continue? (y/N) "
        read -e VERIFY
        if [ "y" = "${VERIFY}" -o "Y" = "${VERIFY}" ]; then
          venv destroy "${name}" &&
          venv create "${name}"
          return $?
        else
          echo "Aborting." 1>&2
          return 64
        fi
      fi
      virtualenv --prompt='$(__venv_prompt)' \
        --distribute "$@" "${vdir}/${name}"
      venv use ${name}
      ;;

    destroy)
      local name=${1:?env NAME required}
      shift
      if [[ "${vdir}/${name}" = "${VIRTUAL_ENV}" ]]; then
        printf "${name} is active. Continue? (y/N) "
        read -e VERIFY
        if [ "y" = "${VERIFY}" -o "Y" = "${VERIFY}" ]; then
          deactivate
        else
          echo "Aborting." 1>&2
          return 65
        fi
      fi
      rm -r "${vdir}/${name}"
      ;;

    use|activate)
      local name=${1:?env NAME required}
      shift
      source "${vdir}/${name}/bin/activate"
      ;;

    current)
      echo "${VIRTUAL_ENV:=No virtualenv active.}"
      ;;

    deactivate)
      if builtin type deactivate &>/dev/null; then
        deactivate
      else
        echo "No virtualenv active." 1>&2
      fi
      ;;

    ls)
      for n in ${vdir}/*; do
        [[ -d $n ]] && echo ${n#${vdir}/}
      done
      ;;

    *)
      echo "venv [create <name>]"
      echo "     [destroy <name>]"
      echo "     [use <name>]"
      echo "     [current]"
      echo "     [deactivate]"
      echo "     [ls]"
      ;;
  esac
}

__venv_prompt () {
  echo -e "\[\033[1;30m\][venv:$(basename "$VIRTUAL_ENV")]\[\033[0m\] "
}

__venv_completion () {
  local cur prev opts
  local venvs="$(venv ls)"
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  opts="create destroy use current deactivate ls"

  case "${prev}" in
    destroy)
      COMPREPLY=( $(compgen -W "${venvs}" -- ${cur}) )
      ;;
    use)
      COMPREPLY=( $(compgen -W "${venvs}" -- ${cur}) )
      ;;
    *)
      COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
      ;;
  esac
}
complete -F __venv_completion venv
