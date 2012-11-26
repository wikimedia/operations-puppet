# !this file is managed by puppet!
# set umask to 0002 for wikidev users
# to prevent broken repos per RT-804
if groups | grep -w -q wikidev; then
  umask 0002
else
  umask 0022
fi
