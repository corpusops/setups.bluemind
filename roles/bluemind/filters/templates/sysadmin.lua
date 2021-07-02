---------------
--  Options  --
---------------

options.info = true
options.timeout = 120
options.subscribe = true
IRE_FLAGS = {"CASELESS", "EXTENDED", "MULTILINE"}
RE_FLAGS = {"EXTENDED", "MULTILINE"}
DEFAULT_FOLDER="INBOX"
DEFAULT_FOLDERS={DEFAULT_FOLDER}

----------------
--  Accounts  --
----------------

-- Connects to "imap1.mail.server", as user "user1" with "secret1" as
-- password.
account = IMAP {
    server = '{{bluemind_imapfilter_host}}',
    username = 'foo',
    password = 'bar',
}

function Set.contain_addr(self, string)
    local set = Set()
    for mbox in pairs(_extract_mailboxes(self)) do
        set = set +
              mbox:contain_from(string) +
              mbox:contain_to(string) +
              mbox:contain_cc(string) +
              mbox:contain_field("Reply-To", string) +
              mbox:contain_bcc(string)
    end
    return self * set
end

function Set.fmatch_field(messages, field, pattern, cflags)
    local results = {}
    _check_required(messages, 'table')
    _check_required(pattern, 'string')
    _check_required(field, 'string')
    _check_optional(cflags, 'table')
    if ( cflags == nil  or #cflags == 0 ) then cflags = RE_FLAGS end
    for _, v in ipairs(messages) do
        local self, message = table.unpack(v)
        local mesgs = {message}
        local fields = self._fetch_fields(self, { field }, mesgs)
        if #mesgs == 0 or fields == nil then return Set({}) end
        for m, f in pairs(fields) do
            local lval = string.gsub(f, '^[^:]*: ?(.*)$', '%1')
            if regex_search(pattern, lval, cflags) then
                table.insert(results, {self, m})
            end
        end
    end
    return Set(results)
end

function Set.fmatch_header(messages, pattern, cflags)
    local results = {}
    _check_required(messages, 'table')
    _check_required(pattern, 'string')
    _check_optional(cflags, 'table')
    if ( cflags == nil  or #cflags == 0 ) then cflags = RE_FLAGS end
    for _, v in ipairs(messages) do
        local self, message = table.unpack(v)
        local mesgs = {message}
        local header = self._fetch_header(self, mesgs)
        if #mesgs == 0 or header == nil then return Set({}) end
        for m, h in pairs(header) do
            if regex_search(pattern, h, cflags) then
                table.insert(results, {self, m})
            end
        end
    end
    return Set(results)
end

function fmatch_body(messages, pattern, cflags)
    local results = {}
    _check_required(messages, 'table')
    _check_required(pattern, 'string')
    _check_optional(cflags, 'table')
    if ( cflags == nil  or #cflags == 0 ) then cflags = RE_FLAGS end
    for _, v in ipairs(messages) do
         local self, message = table.unpack(v)
         local mesgs = {message}
         local body = self._fetch_body(self, mesgs)
         if #mesgs == 0 or body == nil then return Set({}) end
         local results = {}
         for m, b in pairs(body) do
             if regex_search(pattern, b, cflags) then table.insert(results, {self, m}) end
         end
    end
    return Set(results)
end

function fmatch_message(messages, pattern, cflags)
    local results = {}
    _check_required(messages, 'table')
    _check_required(pattern, 'string')
    _check_optional(cflags, 'table')
    _check_required(pattern, 'string')
    if not messages then messages = self._send_query(self) end
    for _, v in ipairs(messages) do
        local self, message = table.unpack(v)
        local mesgs = {message}
        local full = self._fetch_message(self, mesgs)
        if #mesgs == 0 or full == nil then return Set({}) end
        local results = {}
        for m, f in pairs(full) do
            if regex_search(pattern, f, cflags) then table.insert(results, {self, m}) end
        end
    end
    return Set(results)
end


function get_messages(acc, kwargs)
    local results = Set()
    local kwargs = kwargs or {}
    local folders = {kwargs["folder"]}
    if kwargs["folder"] == nil then
        folders = DEFAULT_FOLDERS
    end
    if not (kwargs["folders"] == nil) then
        folders = kwargs['folders']
    end
    -- for _, msg in ipairs(folders) do print(msg) end
    -- for _, msg in ipairs(DEFAULT_FOLDERS) do print(msg) end
    for _, folder in ipairs(folders) do
        for _, msg in ipairs(acc[folder]:select_all()) do
                table.insert(results, msg)
        end
    end
    -- for _, msg in ipairs(results) do print(msg) end
    return results
end

-- -- Get a list of the available mailboxes and folders
-- mailboxes, folders = account:list_all()
-- inbox = get_messages(account, {folders={'Junk'}})
-- results = inbox:fmatch_header('X-Outgoing-Spam:\\s*1', IRE_FLAGS)
-- results:mark_seen()
-- results:move_messages(account.Junk)
--
-- inbox = get_messages(account)
-- results = inbox:fmatch_header('X-Outgoing-Spam:\\s*1', IRE_FLAGS)
-- results:mark_seen()
-- results:move_messages(account.Junk)

-- for _, msg in ipairs(get_messages(account, {folders={'archives/2017'}})) do print(msg) end
--
-- inbox = get_messages(account)
-- results = inbox:contain_addr('sysadmin+foo@bar.com')
-- results:move_messages(account['foo'])
--
-- inbox = get_messages(account)
-- results = inbox:contain_addr('sysadmin+monitoring@foo.com') +
--     inbox:fmatch_header('^(to|from|cc|bcc):.*bounce.*@fii.net', IRE_FLAGS) +
--     inbox:contain_addr('sysadmin+catchall@foo.com')
-- results:mark_seen()
-- results:move_messages(account.bounces)
--
-- inbox = get_messages(account)
-- results = inbox:contain_addr('sysadmin+dmarkforensic@foo.com') +
--           inbox:contain_addr('sysadmin+dmarkfeedback@foo.com')
-- results:mark_seen()
-- results:move_messages(account['Junk/dmark'])
--
-- inbox = account.inbox:select_all()
-- results = inbox:contain_addr('thisisaspam')
-- results:mark_seen()
-- results:move_messages(account.trash)

-- -----------------
-- --  Mailboxes  --
-- -----------------
--

-- Create a mailbox
-- account:create_mailbox('Friends')

-- Subscribe a mailbox
-- account:subscribe_mailbox('Friends')

-- -- Get the status of a mailbox
-- account.INBOX:check_status()
--
-- -- Get all the messages in the mailbox.
-- results = account.INBOX:select_all()
--
-- -- Get newly arrived, unread messages
-- results = account.INBOX:is_new()
--
-- -- Get unseen messages with the specified "From" header.
-- results = account.INBOX:is_unseen() *
--           account.INBOX:contain_from('weekly-news@news.letter')
--
-- -- Copy messages between mailboxes at the same account.
-- results:copy_messages(account.news)
--
-- -- Get messages with the specified "From" header but without the
-- -- specified "Subject" header.
-- results = account.INBOX:contain_from('announce@my.unix.os') -
--           account.INBOX:contain_subject('security advisory')
--
-- -- Copy messages between mailboxes at a different account.
-- results:copy_messages(account2.security)
--
-- -- Get messages with any of the specified headers.
-- results = account.INBOX:contain_from('marketing@company.junk') +
--           account.INBOX:contain_from('advertising@annoying.promotion') +
--           account.INBOX:contain_subject('new great products')
--
-- -- Delete messages.
-- results:delete_messages()
--
-- -- Get messages with the specified "Sender" header, which are older than
-- -- 30 days.
-- results = account.INBOX:contain_field('sender', 'owner@announce-list') *
--           account.INBOX:is_older(30)
--
-- -- Move messages to the "announce" mailbox inside the "lists" folder.
-- results:move_messages(account['lists/announce'])
--
-- -- Get messages, in the "devel" mailbox inside the "lists" folder, with the
-- -- specified "Subject" header and a size less than 50000 octets (bytes).
-- results = account['lists/devel']:contain_subject('[patch]') *
--           account['lists/devel']:is_smaller(50000)
--
-- -- Move messages to the "patch" mailbox.
-- results:move_messages(account2.patch)
--
-- -- Get recent, unseen messages, that have either one of the specified
-- -- "From" headers, but do not have the specified pattern in the body of
-- -- the message.
-- results = ( account.INBOX:is_recent() *
--             account.INBOX:is_unseen() *
--             ( account.INBOX:contain_from('tux@penguin.land') +
--               account.INBOX:contain_from('beastie@daemon.land') ) ) -
--           account.INBOX:match_body('.*all.work.and.no.play.*')
--
-- -- Mark messages as important.
-- results:mark_flagged()
--
-- -- Get all messages in two mailboxes residing in the same server.
-- results = account.news:select_all() +
--           account.security:select_all()
--
-- -- Mark messages as seen.
-- results:mark_seen()
--
-- -- Get recent messages in two mailboxes residing in different servers.
-- results = account.INBOX:is_recent() +
--           account2.INBOX:is_recent()
--
-- -- Flag messages as seen and important.
-- results:add_flags({ '\\Seen', '\\Flagged' })
--
-- -- Get unseen messages.
-- results = account.INBOX:is_unseen()
--
-- -- From the messages that were unseen, match only those with the specified
-- -- regular expression in the header.
-- newresults = results:match_header('^.+MailScanner.*Check: [Ss]pam$')
--
-- -- Delete those messages.
-- newresults:delete_messages()
