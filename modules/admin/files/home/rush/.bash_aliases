#chase's weird list of macros and shortcuts
#tips:
#'<space>command' -- not saved to history in bash
#'> <file>' -- erases file contents
#git config --global http.proxy %HTTP_PROXY%

set_user() {
  #if sudo'ed into root use real id
  if [[ $EUID -ne 0 ]]; then
    echo "$USER"
  else
    echo "$SUDO_USER"     
  fi
}

########USER ENV SETUP###########################
#
USER=$(set_user)
OS=$(uname)
export PATH=$PATH:$HOME/bin
#
########PUPPET###################################
#
limited_puppet_run()
{
    #Update single puppet module
    sudo puppet agent --tags $1 --test
}
#
########RUNIT###################################
#
#restart all runit services
sv_restart() {
for service in $(ls /etc/service); do echo "$service" ; sv restart $service;  done
}
#
##################################################

    extract () {
        if [ -f $1 ] ; then
          case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar e $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.tbz2)      tar xjf $1     ;;
            *.tgz)       tar xzf $1     ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)     echo "'$1' cannot be extracted via extract()" ;;
             esac
         else
             echo "'$1' is not a valid file"
         fi
    }


function testmail () {
    echo "Subject: $1" | sendmail -vf test@test.com $USER@gmail.com
}

function full () {
    readlink -f $1
}

#IP SHORTCUTS
ip () {
    case "$1" in
        'br')
            ip brief
            ;;
        'brief')
            sudo ip addr show | grep inet | grep -v 127 | awk '{print $7, $2}' | grep -v '::'
            ;;
        'alias')
            echo $"Usage: ip 
                         [alias|br|brief]"
            ;;
        *)
        sudo /bin/ip $@
    esac
}


pep8() {
    case "$1" in
        'v')
            pep8 --show-source $2
            ;;
        'vv')
            pep8 --show-source --show-pep8 $2
            ;;
        *)
        echo $"Usage: pep8
                         [v            - show source context
                          vv           - show pep8 context]"
    esac
}

#APITUDE / DPKG
apt() {
    case "$1" in
        'p')
            echo "packages installed:"
            dpkg -l
            ;;
        'l')
            echo "list files a package"
            sudo dpkg -L $2
            ;;
        's')
            echo "search"
            sudo aptitude search $2
            ;;
        'r')
            echo "remove and purge"
            sudo sudo aptitude remove --purge $2
            ;;
        'i')
            echo "install $2"
            sudo aptitude install $2 -y
            ;;
        'u')
            echo "upgrade"
            sudo aptitude upgrade -y
            ;;
        'sim')
            echo "simulate install"
            apt-get -s install $1
            ;;
        *)
        echo $"Usage: apt 
                         [p           - packages installed 
                          u           - upgrade
                          l <package> - files in a packages
                          s <package> - search for a package
                          r <package> - remove and purge a package
                          sim <package> - simulate install
                          i <package>- install a package]"
    esac
}

#DIAMOND
diamond() {
    case "$1" in
        'check')
            /etc/init.d/diamond restart && diamond-setup --print -C $1
            ;;
        'help')
        echo $"Usage: diamond 
                          i <package>- install a package]"
            ;;
        *)
        $@
    esac
}

die() {
    pgrep $1 | xargs kill -9
}

dicheck() {
    /etc/init.d/diamond restart && diamond-setup --print -C $
}

hfromip() {
    #get hostname from an ip
    dig +short -x $1
}

ramdrive() {
    if [[ ${OS} == "Darwin" ]]; then
        diskutil eraseVolume HFS+ RAMDisk `hdid -nomount ram://$((1024*2048))`
    else
        #Should be 'Linux'
        mount -t tmpfs tmpfs /mnt -o size=1024m
    fi
}

function ff(){
  find . -iname $1 | grep -v .svn | grep -v .sass-cache
}

recent_history() {
    #show recent sorted unique history
    history|awk '{print $2}'|awk 'BEGIN {FS="|"} {print $1}'|sort|uniq -c|sort -rn|head -10
}

#Decrypt a file with passphrase
decrypt() {
    dd if=$1  | openssl des3 -d -k $2 |tar zxf -
}

#Encrypt a file with passphrase
encrypt() {
    tar -zcvf - $1 | openssl des3 -salt -k $2 | dd of=$1.des3
}

########GIT###################################
#

gitry() {
    #Need relative path from /git for repo
    #need box name for testing
    sudo rsync -avz --exclude '*.git' -e ssh /Users/rush/git/$1 rush@$2:~
}

newgit() {
    git add -A && git commit -m "$1" && git pull && git push
}

#
##################################################

#serve current dir web interface
serve() {
    python -m SimpleHTTPServer
}

# log command output
function log_cmd() {

    local to_file="$1"
    shift
    if [ -z "$to_file" ]; then
        echo "Need a file to log to." 2>&1
        return 1
    elif [ -z "$*" ]; then
        echo "Need a command to run." 2>&1
        return 1
    fi

    echo "DATE: $(date)" > "$to_file"
    echo "DIR: $(pwd)" >> "$to_file"
    echo "CMD: $*" >> "$to_file"
    echo "OUTPUT:" >> "$to_file"
    echo >> $to_file
    eval "$@ 2>&1 | tee -a '$to_file'"
    return $?
}

#Managing dtach sessions
detach()
{
    SESSION=/tmp/$1
    echo "Creating: $SESSION"
    dtach -c $SESSION bash
}

attach()
{
    SESSION=/tmp/$1
    echo "Creating: $SESSION"
    dtach -a $SESSION
}


all_cron_jobs() {
    for user in $(cut -f1 -d: /etc/passwd); do echo "#### CRONJOBS FOR $user ####:";crontab -u $user -l;  done 
}

sshme() {
  ssh -A -oStrictHostKeyChecking=no $USER@$1
}

tcpdumpshortcuts() {
    #allow tcpdump aliases if no match pass on
    case "$1" in
        'cdp')
            echo "CDP"
            sudo tcpdump -nn -v -i eth0 -s 1500 -c 1 'ether[20:2] == 0x2000'
            ;;
        'lldp')
            echo "LLDP"
            tcpdump -v -s 1500 -c 1 '(ether[12:2]=0x88cc or ether[20:2]=0x2000)'
            ;;
        'dhcp')
            echo "DHCPD & BOOTP"
            sudo tcpdump port 67 or 68
            ;;
        'alias')
            echo $"Usage:
                         [cdp  - dump cdp facts takes up to 60 seconds
                          dhcp - dhcp presets]"
            ;;
        *)
            sudo tcpdump $@
    esac
}

rm_allbut() {
    ls * | grep -v $1  | xargs rm -rR
}

last_new() {
    #run last command sub arg 1 for arg 2
     ^$1^$2
}

#Kill process by name sometimes useful when pkill etc not avail
kname() {
    ps -ef | grep $1 | grep -v grep | awk '{print $2}' | xargs kill -9
}

# Generates a tree view from the current directory
function gtree(){
        pwd
        ls -R | grep ":$" |   \
        sed -e 's/:$//' -e 's/[^-][^\/]*\//--/g' -e 's/^/   /' -e 's/-/|/'
}

#Separator do not remove
#alias_definitions:

#desc [n <file>] nano with word warp, smooth scroll -v
alias n="nano -wES"

#desc 'td alias' for details
alias td='tcpdumpshortcuts'
alias tcpdump='tcpdumpshortcuts'

#desc [g <regex> <file> shortcut to grep -v
alias g='grep'

#desc shortcut to history -v
alias h='history'

#desc [hg <regex>] grep for a command history -v
alias hg='h | g'

#desc [nocomment <file>] show a file without comments
alias nocomment='grep -Ev '\''^(# |$)'\'''

#desc show brief ip address format
alias ips='ip brief'

#desc show global nat IP
alias eip="curl ifconfig.me"

#desc [up <host>] run 3 ping tests
alias up='time ping -c 3'

#desc show open ports
alias ports='netstat -tulanp'

#desc show recent history tag=history
alias rh='recent_history'

#desc show cron jobs
alias crons='all_cron_jobs | nocomment | sort'

#desc back home -v
alias home="cd ~ && pwd && ls"

#desc [dc <new_session_file>] detach a shell session tag=dtach
alias dc="detach"

#desc [da <existing_session_file>] attach to a detached shell session tag=dtach
alias da="attach"

#desc restart all runit services tag=runit
alias svrestart="sv_restart"

#desc update single puppet module only tag=puppet
alias lpr='limited_puppet_run'

#desc kill proc by name  tag=ps
alias kn='kname'

alias EXIT="exit"
alias e='exit'

alias u='cd .. && ls'
alias uu='cd ../.. && ls'
alias uuu='cd ../../.. && ls'
alias uuuu='cd ../../../.. && ls'
alias uuuuu='cd ../../../../..&& ls'
alias uuuuuu='cd ../../../../../.. && ls'
alias uuuuuuu='cd ../../../../../../.. && ls'
alias uuuuuuuu='cd ../../../../../../../.. && ls'
alias cdns='sudo killall -HUP mDNSResponder'
#desc log <file>.log <cmd>
alias log="log_cmd"
alias s="sudo -sE"
alias v="vim"
alias pass="apg -m 15 -t -n 1 -l -M N"
alias mkdir="mkdir -p"
alias myip='curl ip.appspot.com'
alias flushDNS='dscacheutil -flushcache' 

#   ii:  display useful host related informaton
#   -------------------------------------------------------------------
    ii() {
        echo -e "\nYou are logged on ${RED}$HOST"
        echo -e "\nAdditionnal information:$NC " ; uname -a
        echo -e "\n${RED}Users logged on:$NC " ; w -h
        echo -e "\n${RED}Current date :$NC " ; date
        echo -e "\n${RED}Machine stats :$NC " ; uptime
        echo -e "\n${RED}Current network location :$NC " ; scselect
        echo -e "\n${RED}Public facing IP Address :$NC " ;myip
        #echo -e "\n${RED}DNS Configuration:$NC " ; scutil --dns
        echo
    }


    httpDebug () { /usr/bin/curl $@ -o /dev/null -w "dns: %{time_namelookup} connect: %{time_connect} pretransfer: %{time_pretransfer} starttransfer: %{time_starttransfer} total: %{time_total}\n" ; }
