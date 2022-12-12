# bash-rsi

Allow folks who use vi mode in bash to intermarry with those folks who use
emacs mode. This approach was inspired by tpope's
[vim-rsi](https://github.com/tpope/vim-rsi) which brings emacs bindings to vim.

This config allows setting the bash readline mode to vi, but keeps all the
shortcuts from emacs mode intact.

In addition it sets the cursor to a vertical bar(❙) when in the hybrid emacs-vi
insert mode, and a block cursor(▮) when in vi command mode.

## Trying it out via a debian docker image

```
git clone https://github.com/lollipopman/bash-rsi.git ~/.bash-rsi
cd .bash-rsi
bash ./test
```

## Install

```
git clone https://github.com/lollipopman/bash-rsi.git ~/.bash-rsi
printf '$include ~/.bash-rsi/inputrc\n' >> ~/.inputrc
printf '# shellcheck source=.bash-rsi/bashrc\nsource ~/.bash-rsi/bashrc\n' >> ~/.bashrc
```
