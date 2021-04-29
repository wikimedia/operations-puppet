if [ -d "/var/lib/mailman3/lists/$1.lists.wikimedia.org" ]; then
  echo "Already done"
  exit 0
fi
if [[ $( grep $1 /home/ladsgroup/disabled_wikis) ]]; then
  echo "Disabled"
  exit 0
fi
echo "This mailing list is right now being upgraded to mailman3 (T280322)" | mail -s "Mailing list being upgraded" $1-owner@lists.wikimedia.org
sleep 5
sudo mailman-wrapper create "$1@lists.wikimedia.org" &&
sudo mailman-wrapper import21 $1@lists.wikimedia.org /var/lib/mailman/lists/$1/config.pck &&
sudo mailman-web mailman_sync &&
sudo mailman-web hyperkitty_import -l $1@lists.wikimedia.org /var/lib/mailman/archives/private/$1.mbox/$1.mbox &&
sudo mailman-web update_index_one_list $1@lists.wikimedia.org &&
sudo disable_list "$1" &&
echo "This mailing list is now fully on mailman3, you can access it in https://lists.wikimedia.org/postorius/lists/$1.lists.wikimedia.org/ Please create an account in https://lists.wikimedia.org/accounts/signup/" | mail -s "Mailing list is now upgraded" $1-owner@lists.wikimedia.org
