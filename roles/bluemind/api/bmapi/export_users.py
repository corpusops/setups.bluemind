#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

from StringIO import StringIO
import six
import os
import csv
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

requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

CSV_HEADERS = ['domain', 'id', 'mails']

USER_LOGIN = os.environ['MAIL_USER']
password = os.environ['MAIL_PW']
re_flags = re.U | re.M
URL = 'https://localhost/api'
client = BMClient(URL, password)
EXCLUDED = re.compile('global.virt', re_flags)
EXCLUDED_USERS = re.compile('bmhiddensysadmin', re_flags)
domains = OrderedDict()
for domain in client.domains().all():
    if not EXCLUDED.search(domain.value.name):
        dom = OrderedDict()
        dom['domain'] = domain
        iusers = client.users(domain.uid)
        uids = iusers.allUids()
        users = OrderedDict()
        for uid in uids:
            user = iusers.getComplete(uid)
            users[user.value.login] = user
        dom['users'] = users
        domains[domain.value.name] = dom
export = []

for d, data in six.iteritems(domains):
    domain = data['domain']
    for login, user in six.iteritems(data['users']):
        if EXCLUDED_USERS.search(login):
            continue
        row = {'domain': domain.displayName,
               'id': login,
               'mails': ",".join([a.address for a in user.value.emails])}
        export.append(row)

csve = StringIO()
writer = csv.DictWriter(csve,
                        CSV_HEADERS,
                        delimiter=";",
                        quotechar='"',
                        extrasaction='ignore',
                        quoting=csv.QUOTE_NONNUMERIC)
writer.writerow(dict([(f, f) for f in CSV_HEADERS]))
for i in export:
    writer.writerow(i)
with open('users.csv', 'w') as fic:
    fic.write(csve.getvalue())
# vim:set et sts=4 ts=4 tw=80:
