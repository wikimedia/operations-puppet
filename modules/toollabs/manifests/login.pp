# tools-login

class toollabs::login {
	require toollabs::run_environ
	require toollabs::dev_environ
	require gridengine::submit_host
	require ssh::bastion
}

