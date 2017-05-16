#!/bin/bash
__pwdln() {

   # Doing PE from the beginning of the string is needed
   # so we get a string of 0 len to break the until loop.

   pwdmod="${PWD}/"
   itr=0
   until [[ -z "$pwdmod" ]];do
      itr=$(($itr+1))
      pwdmod="${pwdmod#*/}"
   done
   echo -n $(($itr-1))

}

__vagrantinvestigate() {

    if [ -f "${PWD}/.vagrant" -o -d "${PWD}/.vagrant" ];then
      echo "${PWD}/.vagrant"
      return 0
   else
      #  Since we didn't find a $PWD/.vagrant, we're going to pop
      #  a directory off the end of the $pwdmod2
      #  stack until we come across a ./.vagrant. /home/igneous/proj/1
      #  will start at /home/igneous/proj because of our loop starting
      #  at 2.
      pwdmod2="${PWD}"
      for (( i=2; i<=$(__pwdln); i++ ));do
         pwdmod2="${pwdmod2%/*}"
         if [ -f "${pwdmod2}/.vagrant" -o -d "${pwdmod2}/.vagrant" ];then
            echo "${pwdmod2}/.vagrant"
            return 0
         fi
      done
   fi

   return 1

}

_vagrant()
{
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    commands="box destroy halt help init package provision reload resume ssh ssh-config status suspend up version"

    if [ $COMP_CWORD == 1 ]
    then
      COMPREPLY=($(compgen -W "${commands}" -- ${cur}))
      return 0
    fi

    if [ $COMP_CWORD == 2 ]
    then
        case "$prev" in
            "init")
              local box_list=$(find $HOME/.vagrant.d/boxes -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
              COMPREPLY=($(compgen -W "${box_list}" -- ${cur}))
              return 0
            ;;
            "ssh"|"provision"|"reload"|"halt"|"suspend"|"resume"|"ssh-config")
              vagrant_state_file=$(__vagrantinvestigate) || return 1
              #Got lazy here.. I'd like to eventually replace this with a pure bash solution.
	      if [[ -f $vagrant_state_file ]]; then 
		  running_vm_list=$(grep 'active' $vagrant_state_file | sed -e 's/"active"://' | tr ',' '\n' | cut -d '"' -f 2 | tr '\n' ' ')
	      else 
		  running_vm_list=$(find $vagrant_state_file -type f -name "id" | awk -F"/" '{print $(NF-2)}')
	      fi
              COMPREPLY=($(compgen -W "${running_vm_list}" -- ${cur}))
              return 0
            ;;
            "box")
              box_commands="add help list remove repackage"
              COMPREPLY=($(compgen -W "${box_commands}" -- ${cur}))
              return 0
            ;;
            "help")
              COMPREPLY=($(compgen -W "${commands}" -- ${cur}))
              return 0
            ;;
            *)
            ;;
        esac
    fi

    if [ $COMP_CWORD == 3 ]
    then
      action="${COMP_WORDS[COMP_CWORD-2]}"
      if [ $action == 'box' ]
      then
        case "$prev" in
            "remove"|"repackage")
              local box_list=$(find $HOME/.vagrant.d/boxes -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
              COMPREPLY=($(compgen -W "${box_list}" -- ${cur}))
              return 0
              ;;
            *)
            ;;
        esac
      fi
    fi

}
complete -F _vagrant vagrant

