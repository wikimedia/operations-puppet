#!/bin/bash
#
# This script is a quick fix that begs to be rewritten in a more solid language (perl, python..)
# However, for the time being, it does just fine.
#
# The goal for this script is to check the nodefile files against real-life condition.
# We want to make sure that everything running live on the LVS is getting properly synchronized to
# and we want to make sure that these list are as accurate and close to reality as possible.
# 
# Eventually, this script will evolve, but for now, there are no better alternative! 
#
# Contact Fred Vassard <fred@wikimedia.org> with any question.
#

### LVS2 ###
echo ""
echo "===> Checking LVS2 active hosts against their node-groups counterpart... <==="

echo "- Running  pybal/text-squids against node_groups/squids..."
for h in `ssh lvs2 cat /etc/pybal/text-squids | grep -v ^# |grep -v "'weight': 0" | grep -v "'enabled': [fF]alse"| grep -o "srv[0-9]\{2,\}"`; 
	do grep $h /usr/local/dsh/node_groups/squids >/dev/null  || echo "SERVER $h from lvs2 not in 'squids' nodelist"; 
done

echo "- Running  pybal/upload-squids against node_groups/squids_upload..."
for h in `ssh lvs2 cat /etc/pybal/upload-squids | grep -v ^# |grep -v "'weight': 0" | grep -v "'enabled': [fF]alse"| grep -o "srv[0-9]\{2,\}"`; 
	do grep $h /usr/local/dsh/node_groups/squids_upload >/dev/null  || echo "SERVER $h from lvs2 not in 'squids_upload' nodelist"; 
done

### LVS3 ### 
echo ""
echo "===> Checking LVS3 active hosts against their node-groups counterpart... <==="

echo "- Running  pybal/text-squids against node_groups/squids..."
for h in `ssh lvs3 cat /etc/pybal/text-squids | grep -v ^# |grep -v "'weight': 0" | grep -v "'enabled': [fF]alse"| grep -o "srv[0-9]\{2,\}"`; 
	do grep $h /usr/local/dsh/node_groups/squids >/dev/null  || echo "SERVER $h from lvs3 not in 'squids' nodelist"; 
done

echo "- Running  pybal/apaches against node_groups/mediawiki-installation..."
for h in `ssh lvs3 cat /etc/pybal/apaches | grep -v ^# |grep -v "'weight': 0" | grep -v "'enabled': [fF]alse"| grep -o "srv[0-9]\{2,\}"`; 
	do grep $h /usr/local/dsh/node_groups/mediawiki-installation >/dev/null  || echo "SERVER $h from lvs3 not in 'mediawiki-installation' nodelist"; 
done

echo "- Running  pybal/apaches against node_groups/apaches..."
for h in `ssh lvs3 cat /etc/pybal/apaches | grep -v ^# |grep -v "'weight': 0" | grep -v "'enabled': [fF]alse"| grep -o "srv[0-9]\{2,\}"`; 
	do grep $h /usr/local/dsh/node_groups/apaches >/dev/null  || echo "SERVER $h from lvs3 not in 'apaches' nodelist"; 
done

echo "- Running  pybal/search_pool_* against node_groups/search..."
for h in `ssh lvs3 cat /etc/pybal/search_pool_* | grep -v ^# |grep -v "'weight': 0" | grep -v "'enabled': [fF]alse"| grep -o "srv[0-9]\{2,\}"`; 
	do grep $h /usr/local/dsh/node_groups/search >/dev/null  || echo "SERVER $h from lvs3 not in 'search' nodelist"; 
done

echo "- Running  pybal/renderers against node_groups/image_scalers..."
for h in `ssh lvs3 cat /etc/pybal/renderers | grep -v ^# |grep -v "'weight': 0" | grep -v "'enabled': [fF]alse"| grep -o "srv[0-9]\{2,\}"`; 
	do grep $h /usr/local/dsh/node_groups/image_scalers >/dev/null  || echo "SERVER $h from lvs3 not in 'search' image_scalers"; 
done

### LVS4 ###
echo ""
echo "===>  Checking LVS4 active hosts against their node-groups counterpart... <==="

echo "- Running  pybal/upload-squids against node_groups/squids_upload..."
for h in `ssh lvs4 cat /etc/pybal/upload-squids | grep -v ^# |grep -v "'weight': 0" | grep -v "'enabled': [fF]alse"| grep -o "srv[0-9]\{2,\}"`; 
	do grep $h /usr/local/dsh/node_groups/squids_upload >/dev/null  || echo "SERVER $h from lvs4 not in 'squids_upload' nodelist"; 
done

echo "- Running  pybal/text-squids against node_groups/squids..."
for h in `ssh lvs4 cat /etc/pybal/text-squids | grep -v ^# |grep -v "'weight': 0" | grep -v "'enabled': [fF]alse"| grep -o "srv[0-9]\{2,\}"`; 
	do grep $h /usr/local/dsh/node_groups/squids >/dev/null  || echo "SERVER $h from lvs4 not in 'squids' nodelist"; 
done


### LOCAL Checks ###
echo ""
echo "===> Checking local files against 'ALL' file... <==="
for files in {apaches,ext-stores,image_scalers,image_stores,lvs,mediawiki-installation,misc,mysql,search,squids,squids_upload}; do
	echo "- Comparing content of '$files' to 'ALL'..."
	for h in `cat $files | grep -v ^#`; do grep $h ALL >/dev/null 2>&1 || echo "SERVER $h is present in '$files' but not in ALL"; done;
done

echo ""
echo "===> Checking 'ALL' file against local files... <==="
for h in `cat ALL`; 
	do grep --exclude=ALL $h * >/dev/null 2>&1 || echo "SERVER $h is present in 'ALL' but not anywhere else."; 
done

