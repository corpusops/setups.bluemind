#!/usr/bin/env bash
lock="$(dirname $0)/spamcollect.lock"
log="$(dirname $0)/spamcollect.log"
find "${lock}" -type f -mmin +30 -delete 1>/dev/null 2>&1
if [ "x${NO_LOCK-}" = "x" ];then
    if  [ -e "${lock}" ];then
        echo "Locked ${0} ($lock)";exit 0
    fi
    touch "${lock}"
fi
shared="{{bluemind_mailshare_path}}"

{{ bluemind_imapsync_syncscript }}

if [ ! -e /data/spamcollect ];then
    mkdir /data/spamcollect/
fi
for i in verified_spam verified_ham;do
    rsync -a --delete \
        {{bluemind_spamcollect_spam_dir}}/$i/ \
        /data/spamcollect/$i/
done
for i in ham;do
    rsync -a --delete \
        {{bluemind_spamcollect_ham_dir}}/$i/ \
        /data/spamcollect/$i/
done
chown -Rf spamcollect /data/spamcollect/
if [ "x${NO_LOCK-}" = "x" ];then
    rm -f "${lock}"
fi
# vim:set et sts=4 ts=4 tw=0:
