#!/bin/bash
# Test if http Planet feed URLs work with https and patch
# templates to use https if they do.
for template in *.erb; do
echo -e "searching ${template} for http URLs"
    grep -E 'feed.*http://' "$template" | cut -d " " -f3 | while read -r http_url; do
        echo "found http URL: ${http_url}"
        https_url=$(sed 's/http/https/g'<<<"${http_url}")
        echo "trying https URL: $https_url"
        if curl -s --head --request GET "$https_url" | grep "200 OK" > /dev/null; then
            echo "YES - https seems to WORK."
            echo -e "patching template ${template}\\n"
            echo "sed -i 's,${http_url},${https_url},g' $template"
            sed -i "s,${http_url},${https_url},g" "$template"
        else
            echo -e "NO - https does not seem to work.\\n"
        fi
    done
done
git status
