-- SPDX-License-Identifier: Apache-2.0
-- Copyright 2026 Giuseppe Lavagetto, Wikimedia Foundation Inc.
-- Extract contact information from the User-Agent string according to our UA policy
-- usage:
--   register: lua-load /etc/haproxy/lua/contact_info.lua (in global)
--   run: http-request lua.set_contact_info
--   log: http-request capture var(req.contact_info) len 64
--   acl: var(txn.contact_info) -m found

-- Extract email address from User-Agent string
-- returns the email address if found, otherwise nil
local function extract_email_address(ua_string)
    if ua_string == nil then
        return nil
    end
    -- Quite liberal email pattern matching.
    -- The reason to do this is we don't really care about the email being valid,
    -- but rather to capture what the user provided in the UA string.
    local email_pattern = "[%w%.%+%-_]+@[%w%-_]*%a[%w%-_]*%.[%a][%a]+"
    local email = string.match(ua_string, email_pattern)
    -- Check for suspiciously long email addresses that are likely not real.
    local parts = {}
    for part in string.gmatch(email or "", "[^@]+") do
        table.insert(parts, part)
    end
    if #parts == 2 and #parts[1] <= 64 and #parts[2] <= 255 then
        return email
    end
    return nil
end


-- Extract url domain from User-Agent string
-- returns the url schema+domain if found, otherwise nil
local function extract_url_domain(ua_string)
    if ua_string == nil then
        return nil
    end
    -- Very liberal URL domain pattern matching.
    -- The reason to do this is we don't really care about the URL being valid,
    -- but rather to capture what the user provided in the UA string.
    local url_pattern = "https?://[%w%-_/%.%%]+"
    return string.match(ua_string, url_pattern)
end

local function extract_wiki_username(ua_string)
    if ua_string == nil then
        return nil
    end
    -- Pattern to match Wikimedia wiki usernames in the UA string as provided by pywikibot.
    -- See https://phabricator.wikimedia.org/T414173#11507767
    -- Also match [[User:Username]] as provided by various community bots. See https://phabricator.wikimedia.org/T423992
    local wiki_user_patterns = {
        "%(%w+:[%w%-]+; [Uu]ser:([%w%s_%-%.%(%)]+)%)",
        "%[%[[Uu]ser:([%w%s_%-%.%(%)]+)%]%]",
    }
    for _, pattern in ipairs(wiki_user_patterns) do
        local username = string.match(ua_string, pattern)
        if username then
            return username
        end
    end
    return nil
end

-- Main function to be registered in HAProxy
-- We look for contact info in the User-Agent string in this order:
-- 1. email address
-- 2. URL domain
-- 3. wiki username
-- We do prefer the email address over the URL domain because it's more specific,
-- and often the URL can be for a generic site (like: the github repo of the software);
-- similarly, we prefer the URL domain over the wiki username, which is an exception we're
-- making to the letter of the UA policy.
function set_contact_info(txn)
    local MAX_UA_LENGTH = 512
    local ua_string = txn.f:req_fhdr("User-Agent")
    if ua_string == nil then
        return
    end
    if #ua_string > MAX_UA_LENGTH then
        return
    end


    local email = extract_email_address(ua_string)
    if email then
        txn:set_var("req.contact_info", email)
        return
    end

    local url_domain = extract_url_domain(ua_string)
    if url_domain then
        txn:set_var("req.contact_info", url_domain)
        return
    end

    local wiki_username = extract_wiki_username(ua_string)
    if wiki_username then
        txn:set_var("req.contact_info", wiki_username)
    end
end

core.register_action("set_contact_info", { "http-req" }, set_contact_info)
