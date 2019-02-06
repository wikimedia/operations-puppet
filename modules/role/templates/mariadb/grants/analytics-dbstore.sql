-- Role for the research user on the dbstore1003-1005 for analytics
-- Creating the role:
CREATE ROLE research_role;

-- Role GRANTS
GRANT USAGE ON *.* TO research_role;
GRANT SELECT ON `wikishared`.* TO research_role;
GRANT SELECT ON `flowdb`.* TO research_role;
GRANT SELECT ON `centralauth`.* TO research_role;
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, CREATE TEMPORARY TABLES ON `staging`.* TO research_role;
GRANT SELECT ON `%wik%`.* TO research_role;

-- Research user (to be deprecated - T214469)
GRANT USAGE ON *.* TO 'research'@'%' IDENTIFIED BY <%= @research_pass %> WITH MAX_USER_CONNECTIONS 200;

-- This role needs to be granted to each user before setting the default role:
GRANT research_role TO 'research'@'10.%';
-- Assigning this default role to research user by default is required:
SET DEFAULT ROLE research_role for 'research'@'10.%';
