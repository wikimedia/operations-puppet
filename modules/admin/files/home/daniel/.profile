#~/.profile: executed when starting a login shell.

# Neat little hack to force TMOUT to a lower value:
# Use exec to replace this shell with another shell 
# that has the desired timeout. We'll leave it to 
# the new shell to read .bashrc.
exec env TMOUT=900 bash --init-file ~/.bashrc

# WE NEVER GET HERE!
# The exec command replaced the current process.
# It never returns here.