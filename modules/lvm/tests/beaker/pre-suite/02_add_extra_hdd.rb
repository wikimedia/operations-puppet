test_name 'FM-4614 - C97274 - add extra hard drives for LVM testing'

# Get the auth_token from ENV
auth_tok = ENV['AUTH_TOKEN']
fail_test "AUTH_TOKEN must be set" unless auth_tok

# On the PE agent where LVM running
confine_block(:except, :roles => %w{master dashboard database}) do

    agents.each do |agent|
      unless (agent['platform'] =~ /windows/ && agent['platform'] =~ /aix/)
        step 'adding an extra disk: /dev/sdc:'
        on(agent, "curl -X POST -H X-AUTH-TOKEN:#{auth_tok} --url vcloud/api/v1/vm/#{agent[:vmhostname]}/disk/1")
        sleep(30)
        step 'rescan the SCSI bus on the host to make the newly added hdd recognized'
        on(agent, "echo \"- - -\" >/sys/class/scsi_host/host0/scan")

        #keep trying until the hdd is found
        retry_on(agent, "fdisk -l | grep \"/dev/sdc\"", :max_retries => 420, :retry_interval => 5)

        step 'adding a second extra disk: /dev/sdd:'
        on(agent, "curl -X POST -H X-AUTH-TOKEN:#{auth_tok} --url vcloud/api/v1/vm/#{agent[:vmhostname]}/disk/1")
        sleep(30)
        step 'rescan the SCSI bus on the host to make the newly added hdd recognized'
        on(agent, "echo \"- - -\" >/sys/class/scsi_host/host0/scan")

        #keep trying until the hdd is found
        retry_on(agent, "fdisk -l | grep \"/dev/sdd\"", :max_retries => 420, :retry_interval => 5)

        step 'Verify the newly add HDDs recognized:'
        on(agent, "fdisk -l") do |result|
          assert_match(/\/dev\/sdc/, result.stdout, "Unexpected errors is detected")
          assert_match(/\/dev\/sdd/, result.stdout, "Unexpected errors is detected")
        end
      end
  end
end
