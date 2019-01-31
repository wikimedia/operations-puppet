# 'source novaenv.sh' will set these shell environment values
# from /etc/novaadmin.yaml
#
# OS_PROJECT_DOMAIN_ID
# OS_REGION_NAME
# OS_USER_DOMAIN_ID
# OS_IDENTITY_API_VERSION
# OS_PASSWORD
# OS_AUTH_URL
# OS_USERNAME
# OS_PROJECT_ID
# OS_INTERFACE
# OS_NO_CACHE

# Largely cribbed from https://gist.github.com/pkuczynski/8665367
parse_yaml() {
    file='/etc/novaadmin.yaml'
    s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
    sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
         -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $file |
    awk -F$fs '{
       indent = length($file)/2;
       vname[indent] = $2;
       for (i in vname) {if (i > indent) {delete vname[i]}}
       if (length($3) > 0) {
          vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
          printf("%s=%s ",$2,$3)
       }
    }'
}

values=`parse_yaml`
for entry in $values; do
    export $entry
done
