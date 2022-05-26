#!/usr/bin/env bash
###
export SDEBUG="${SDEBUG-}"
export BM_URL="${1:-${BM_URL-{{bluemind_ext_mailname}}}}"
export BM_OLD_URL="${2:-${BM_OLD_URL-{{bluemind_old_ext_mailname|default('')}}}}"
export BM_ORIG="${BM_ORIG-{{bluemind_orig}}}"
export ORIG_IP="${ORIG_IP-{{bluemind_orig_ip}}}"
export DEST_IP="${DEST_IP-{{bluemind_ip}}}"
export NO_DATA="${NO_DATA-{{bluemind_no_data|default('')}}}"
export NO_CONF="${NO_CONF-{{NO_CONF|default('')}}}"
export NO_NGINX="${NO_NGINX-{{NO_NGINX|default('')}}}"
export NO_REPAIR="${NO_REPAIR-{{NO_REEPAIR|default('')}}}"
export NO_DB="${NO_DB-{{NO_DB|default('')}}}"
export NO_DB_FIX="${NO_DB_FIX-{{bluemind_no_db_fix|default('')}}}"
export NO_POST_SYNC="${NO_POST_SYNC-}"
###
[[ -n $SDEBUG ]] && set -x

log() { echo "$@">&2; }
vv() { log "$@";"$@"; }
die_in_error_() { if [ "x${1-$?}" != "x0" ];then echo "FAILED: $@">&2; exit 1; fi }
die_in_error() { die_in_error_ $? $@; }
retry() {
    local n=1
  local max=${max:-5}
  local delay=${delay:-1}
    while true;do
        "$@" && break || {
            if [[ $n -lt $max ]]; then
                ((n++))
                log "Command failed. Attempt $n/$max"
                sleep $delay
            else
                die_in_error "The command has failed after $n attempts."
            fi
    }
  done
}

bmctl stop          || die_in_error stop bmctl
service postfix stop|| die_in_error stop postfix
service postgresql restart
[[ -n $BM_ORIG ]]   || die_in_error define BM_ORIG
if [[ -z $NO_DATA ]];then
    if [[ -z $NGINX ]];then
        if [[ -z $BM_OLD_URL ]];then
            BM_OLD_URL=$(ssh $BM_ORIG "PGPASSWORD={{bluemind_pg_password}} \
                psql -d {{bluemind_pg_db}} -h localhost -U {{bluemind_pg_user}} -Aqt \
                -c \"select configuration->'external-url' from t_systemconf;\"")
        fi
        if [[ -z $BM_OLD_URL ]];then
            BM_OLD_URL=$(ssh $BM_ORIG "PGPASSWORD={{bluemind_pg_password}} \
                psql -d {{bluemind_pg_db}} -h localhost -U {{bluemind_pg_user}} -Aqt \
                -c \"select configuration->'external_url' from t_systemconf;\"")
        fi
        [[ -n $BM_OLD_URL ]] || die_in_error "NO BM_OLD_URL"
        while read f;do sed -i -re "s/$BM_OLD_URL/$BM_URL/g" "$f"; done < <(find /etc/nginx -type f)
    fi
    if [[ -z $NO_DB ]];then
        if [[ -z $NO_DB_FIX ]];then
            ( export PGPASSWORD={{bluemind_pg_password}}; \
                if [[ -n $ORIG_IP ]] && [[ -n $DEST_IP ]];then \
                    psql -h {{bluemind_pg_host}} -U {{bluemind_pg_user}} -d {{bluemind_pg_db}} \
                    -c "update t_server set ip='$DEST_IP' where ip='$ORIG_IP';";\
                    psql -h {{bluemind_pg_host}} -U {{bluemind_pg_user}} -d {{bluemind_pg_db}} \
                    -c "update rc_users set mail_host = '$DEST_IP' where mail_host='$ORIG_IP';"; \
                    psql -h {{bluemind_pg_host}} -U {{bluemind_pg_user}} -d {{bluemind_pg_db}} \
                    -c "update t_systemconf set configuration = configuration \
                            || hstore('external-url', '$BM_URL') \
                            || hstore('host', '$DEST_IP') \
                            || hstore('hz-member-address', '$DEST_IP');"; \
                fi; \
            )
            die_in_error pgsql fix
        fi
    fi
fi
if [[ -z $NO_CONF ]];then
    if [[ -n $BM_URL ]];then
        sed -i -r \
            -e "s/external-url =.*/external-url = $BM_URL/g" \
            /etc/bm/bm.ini
    fi
    if [[ -n $DEST_IP ]];then
        sed -i -r \
            -e "s/host ?= ?.*/host = $DEST_IP/g" \
            -e "s/hz-member-address ?= ?.*/hz-member-address = $DEST_IP/g" \
            -e "s/(core_sync_host:) .*/\1 $DEST_IP/g" \
            -e "s/hostname = \".*\"/hostname = \"$DEST_IP\"/g" \
            -e "s/urls = \[\".*:8086\"\]/urls = [\"http:\/\/$DEST_IP:8086\"]/g" \
            -e "s/server [^:]+:8888;/server $DEST_IP:8888;/g" \
            -e "s/(bmHosts=\".*)\"/\1 $DEST_IP\"/g" \
            /etc/init.d/bm-iptables \
            /etc/bm/bm.ini \
            /etc/cyrus-replication \
            /etc/telegraf/telegraf.d/*.conf \
            /etc/bm-tick/*.conf
    fi
fi
if [[ -z $NO_POST_SYNC ]];then
    /sbin/bm-post-sync.sh || die_in_error "post sync"
fi
# vim:set et sts=4 ts=4 tw=80:
