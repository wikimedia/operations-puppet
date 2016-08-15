alias pupt='sudo puppet agent -tv'
alias mya='mysql --defaults-extra-file=/etc/mysql/conf.d/analytics-research-client.cnf '
alias myr='mysql --defaults-extra-file=/etc/mysql/conf.d/research-client.cnf '
alias cdr='cd /srv/deployment/analytics/refinery'
alias hproxy="export http_proxy=http://webproxy.eqiad.wmnet:8080; export HTTPS_PROXY=http://webproxy.eqiad.wmnet:8080;"
alias slog='sudo tail -n 200 -f /var/log/syslog'
alias pvl='pv -l > /dev/null'