class labs::betalabs::admins {

	require labs::betalabs::groups::devops

	user {
		name 'hashar',
		gid => 'devops';
	}

}
