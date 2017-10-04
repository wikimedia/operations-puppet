-- Additional index T177096
ALTER TABLE archive ADD KEY `user_timestamp` (`ar_user`,`ar_timestamp`);
