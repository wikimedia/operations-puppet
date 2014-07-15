all: pubring.gpg

pubring.gpg: reprepro-keys/*.key
	GNUPGHOME=. gpg --import reprepro-keys/*.key
	-rm secring.gpg* trustdb.gpg* pubring.gpg~
