# This type encapsulates the description of
# wiki-configuring apache virtualhosts
type Mediawiki::SiteCollection::Wikis = Struct[{
    'name' => String,
    'vhosts' => Array[Struct[{'name' => String, 'k8s_only_params' => Optional[Hash], 'params' => Hash}]],
    'defaults' => Hash,
    'priority' => Integer[0,99]
}]
