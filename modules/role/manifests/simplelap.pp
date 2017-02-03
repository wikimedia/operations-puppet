# = class: role::simplelap
#
# For times when you do not want mysql, 
# and just apache and PHP
#
# This was originally created because there
# were a lot of labs instances using the old
# webserver::apache and webserver::php5 roles
# that needed to go away. This probably will
# not end up being publicly used
#
# filtertags: labs-project-signwriting labs-project-editor-engagement
class role::simplelap{
    include ::apache
    include ::apache::mod::php5
    include ::apache::mod::rewrite

    require_package('php5-cli')
}
