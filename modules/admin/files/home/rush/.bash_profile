if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi

if [ -d ${HOME}/.bash.completion.d ]; then
 for file in ${HOME}/.bash.completion.d/* ; do
   source $file
 done
fi
