#!/bin/bash
# Test if http Planet feed URLs work with https and patch
# templates to use https if they do.
for template in $(ls *.erb); do
echo -e "searching ${template} for http URLs"
    for http_url in $(grep -E 'feed.*http://' $template | cut -d " " -f3); do
        echo "found http URL: ${http_url}"
        https_url=$(echo ${http_url} | sed 's/http/https/g')
        echo "trying https URL: $https_url"
        if curl -s --head --request GET $https_url | grep "200 OK" > /dev/null; then
            echo "YES - https seems to WORK."
            echo -e "patching template ${template}\n"
            echo "sed -i 's,${http_url},${https_url},g' $template"
            sed -i "s,${http_url},${https_url},g" $template
        else
            echo -e "NO - https does not seem to work.\n"
        fi
    done
done
git status
