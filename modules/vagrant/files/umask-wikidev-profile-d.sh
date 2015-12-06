# Set umask to 0002 for wikidev users to make shared management of
# mediawiki-vagrant files easier
if groups | grep -w -q wikidev; then
  umask 0002
fi
