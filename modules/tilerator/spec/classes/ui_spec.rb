require 'spec_helper'

describe 'tilerator::ui', :type => :class do

  # there is an issue with secret() that is a transitive dependency of service::node
  # not sure how to fix it...
  it { is_expected.to contain_file('/usr/local/bin/notify-tilerator')
                          .with_content(%r{http://localhost:6535/add})
                          .with_content(%r{expdirpath=/srv/osm_expire/\\&})
                          .with_content(/expmask=expire\\\\.list\\\\.%2A\\&/)
                          .with_content(%r{statefile=/var/run/tileratorui/expire.state\\&})
                          .with_content(/fromZoom=10\\&/)
                          .with_content(/beforeZoom=16\\&/)
                          .with_content(/generatorId=gen\\&/)
                          .with_content(/storageId=v3\\&/)
                          .with_content(/deleteEmpty=1/)
  }

end
