# coredb required users
class coredb::users {

	require coredb::packages

	systemuser { 
		"mysql": shell => "/bin/bash"
	}
}