# Add scap to $PATH for non-root users
if [ "$(id -u)" -ne "0" ]; then
    export PATH="$PATH:/srv/deployment/scap/scap/bin"
fi
