# Add scap to $PATH for non-root wikidevs
if [ "$(id -u)" -ne "0" ] && (groups $USER | grep -q ' wikidev\b'); then
    export PATH="$PATH:/srv/deployment/scap/scap/bin"
fi
