#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

from StringIO import StringIO
import six
import os
import re
import requests
from requests.packages.urllib3.exceptions import InsecureRequestWarning

from collections import OrderedDict
from netbluemind.domain.api.IDomains import IDomains
from netbluemind.domain.api.Domain import Domain
from netbluemind.user.api.User import User
from netbluemind.user.api.IUser import IUser
from netbluemind.core.api.Email import Email
from netbluemind.server.api.IServer import IServer
from netbluemind.python.client import BMClient

from netbluemind.mailbox.api.IMailboxes import IMailboxes
from netbluemind.domain.api.IDomains import IDomains
from netbluemind.domain.api.Domain import Domain
from netbluemind.user.api.User import User
from netbluemind.user.api.IUser import IUser

from netbluemind.core.api.Email import Email

from netbluemind.server.api.IServer import IServer

from netbluemind.python.client import BMClient
from netbluemind.calendar.api.ICalendar import ICalendar

from netbluemind.core.task.api.TaskRef import TaskRef
from netbluemind.core.task.api.TaskStatusState import TaskStatusState


from netbluemind.mailshare.api.IMailshare import IMailshare

requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

CSV_HEADERS = ['domain', 'id', 'mails']

USER_LOGIN = os.environ['MAIL_USER']
password = os.environ['MAIL_PW']
MAILS = os.environ['MAIL_UIDS'].split(',')
re_flags = re.U | re.M
URL = 'https://localhost/api'
client = BMClient(URL, password)
EXCLUDED = re.compile('global.virt', re_flags)
EXCLUDED_USERS = re.compile('bmhiddensysadmin', re_flags)
domains = OrderedDict()
for domain in client.domains().all():
    if not EXCLUDED.search(domain.value.name):
        dom = OrderedDict()
        users = OrderedDict()
        dom['domain'] = domain
        dom['iusers'] = iusers = \
            client.users(domain.uid)
        dom['imailboxes'] = imailboxes = \
            client.instance(IMailboxes, domain.uid)
        dom['users'] = users
        for uid in iusers.allUids() :
            user = iusers.getComplete(uid)
            users[user.value.login] = user
        domains[domain.value.name] = dom
to_repair = {}
# Call either via
# user;
#   MAILS_UIDS=LOGIN@foo.com
# Full domain
#   MAILS_UIDS=foo.com

grepaired = {}
gfailed = {}
for m in MAILS:
    repaired = grepaired.setdefault(m, {})
    failed = gfailed.setdefault(m, {})
    logins = []
    if '@' in m:
        logins = [m.split('@')[0]]
        d = dom = m.split('@')[1]
    else:
        d = dom = m
        logins = [a for a in domains[dom]['users']]
    ddata = domains[d]
    for login in logins:
        lm = '{0}@{1}'.format(login, d)
        domain = ddata['domain']
        users = ddata['iusers']
        mbs = ddata['imailboxes']
        shared = mbs.byType('mailshare')
        groups = mbs.byType('group')
        users = mbs.byType('user')
        for typ in (users,):
        # for typ in (shared, groups, users):
            for entity in typ:
                obj = mbs.getComplete(entity)
                repair = False
                if obj.value.name == login:
                    repair = True
                else:
                    for mail in obj.value.emails:
                        if mail.address == lm:
                            repair = True
                            break
                if repair:
                    to_repair[(m, obj.uid)] = {'uid': uid,
                                               'obj': obj,
                                               'mbs': mbs,
                                               'mail': lm}
                    break

error = False
for (m, uid), data in six.iteritems(to_repair):
    print('Repairing {mail}/{uid}'.format(**data))
    try:
        repaired[(m, uid)] = data['mbs'].checkAndRepair(uid)
        print('Launched repair: {mail}/{uid}'.format(**data))
    except (Exception,) as exc:
        print(exc)
        print('ERROR: Repair failed {mail}/{uid}'.format(**data))
        error = True
for (m, uid), task in six.iteritems(repaired):
    status = client.waitTask(task.id)
    if status.state == TaskStatusState.Success:
        print("Done: {0}/{1}".format(m, uid))
    else:
        print("There has been an error : {} ".format(itask.getCurrentLogs()))
        error = True
if error:
    raise Exception('repair failed for {0}'.format(failed.keys()))
# vim:set et sts=4 ts=4 tw=80:

