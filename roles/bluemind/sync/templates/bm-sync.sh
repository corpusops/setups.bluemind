#!/usr/bin/env bash
###
export SDEBUG="${SDEBUG-}"
export BM_URL="${BM_RL-{{bluemind_ext_mailname}}}"
export BM_ORIG="${BM_ORIG-{{bluemind_orig}}}"
export ORIG_IP="${ORIG_IP-{{bluemind_orig_ip}}}"
export DEST_IP="${DEST_IP-{{bluemind_ip}}}"
export SYNC_PREFIX=${SYNC_PREFIX-}
export HARDSYNC="${HARDSYNC-{{bluemind_hard_sync and 'y' or ''}}}"
export NO_DATA="${NO_DATA-{{bluemind_no_data|default('')}}}"
export NO_MAILS="${NO_MAILS-{{bluemind_no_mails|default('')}}}"
export NO_ES="${NO_ES-{{bluemind_no_es|default('')}}}"
export NO_CONF="${NO_CONF-{{NO_CONF|default('')}}}"
export NO_NGINX="${NO_NGINX-{{NO_NGINX|default('')}}}"
export NO_REPAIR="${NO_REPAIR-{{NO_REEPAIR|default('')}}}"
export NO_DB="${NO_DB-{{NO_DB|default('')}}}"
export NO_DB_RESTORE="${NO_DB_RESTORE-{{bluemind_no_db_restore|default('')}}}"
export NO_DB_FIX="${NO_DB_FIX-{{bluemind_no_db_fix|default('')}}}"
export RSYNC="rsync -aAHv --numeric-ids"
export RSYNCD="$RSYNC --delete"
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
[[ -n $BM_ORIG ]]   || die_in_error define BM_ORIG
if [[ -z $NO_DATA ]];then
    if [[ -z $NO_MAILS ]];then
        $RSYNCD ${BM_ORIG}:/var/spool/cyrus/            $SYNC_PREFIX/var/spool/cyrus/
        $RSYNCD ${BM_ORIG}:/var/lib/cyrus/              $SYNC_PREFIX/var/lib/cyrus/
        $RSYNCD ${BM_ORIG}:/var/spool/bm-hsm/           $SYNC_PREFIX/var/spool/bm-hsm/
        $RSYNCD ${BM_ORIG}:/var/spool/sieve/            $SYNC_PREFIX/var/spool/sieve/
        $RSYNCD ${BM_ORIG}:/var/spool/bm-docs/          $SYNC_PREFIX/var/spool/bm-docs/
        if [[ -z $NO_ES ]];then
            $RSYNCD ${BM_ORIG}:/var/spool/bm-elasticsearch/ $SYNC_PREFIX/var/spool/bm-elasticsearch/
        fi
    fi
    if [[ -z $NGINX ]];then
        sed -i -r \
            -e 's/(set [$]bmexternalurl )(.*)/\1'"$BM_URL"';/g' \
            -e "s/server_name .*/server_name $BM_URL;/g" \
        -i  /etc/nginx/bm-externalurl.conf /etc/nginx/bm-servername.conf
    fi
    if [[ -z $NO_DB ]];then
        if [[ -z $NO_DB_RESTORE ]];then
             ( ssh ${BM_ORIG} "PGPASSWORD={{bluemind_orig_pg_password}} pg_dump -U {{bluemind_orig_pg_user}} -h {{bluemind_orig_pg_host}} {{bluemind_orig_pg_db}}" > /tmp/db.sql ) &&\
                su postgres - -c "dropdb {{bluemind_pg_db}} && createdb {{bluemind_pg_db}}" && \
                ( export PGPASSWORD={{bluemind_pg_password}}; \
                cat /tmp/db.sql | psql -U {{bluemind_pg_user}} -h {{bluemind_pg_host}} {{bluemind_pg_db}}; \
                )
            die_in_error pgsql restore
        fi
        if [[ -z $NO_DB_FIX ]];then
            ( export PGPASSWORD={{bluemind_pg_password}}; \
                if [[ -n $ORIG_IP ]] && [[ -n $DEST_IP ]];then \
                    psql -h {{bluemind_pg_host}} -U {{bluemind_pg_user}} -d {{bluemind_pg_db}} \
                    -c "update t_server set ip='$DEST_IP' where ip='$ORIG_IP';";\
                    psql -h {{bluemind_pg_host}} -U {{bluemind_pg_user}} -d {{bluemind_pg_db}} \
                    -c "update rc_users set mail_host = '$DEST_IP' where mail_host='$ORIG_IP';"; \
                    psql -h {{bluemind_pg_host}} -U {{bluemind_pg_user}} -d {{bluemind_pg_db}} \
                    -c "update t_systemconf set configuration = configuration  || hstore('external_url', '$BM_URL') || hstore('host', '$DEST_IP') || hstore('hz-member-address', '$DEST_IP');"; \
                fi; \
            )
            die_in_error pgsql fix
        fi
    fi
fi
if [[ -z $NO_CONF ]];then
    $RSYNCD  --exclude=bm.ini ${BM_ORIG}:/etc/bm/ $SYNC_PREFIX/etc/bm/
    $RSYNCD ${BM_ORIG}:/etc/bm-hps/    $SYNC_PREFIX/etc/bm-hps/
    $RSYNCD ${BM_ORIG}:/var/lib/bm-ca/ $SYNC_PREFIX/var/lib/bm-ca/
    scp    ${BM_ORIG}:/etc/ssl/certs/bm_cert.pem $SYNC_PREFIX/etc/ssl/certs/bm_cert.pem
    scp    ${BM_ORIG}:/etc/imapd* $SYNC_PREFIX/etc/
    scp    ${BM_ORIG}:/etc/cyrus* $SYNC_PREFIX/etc/
    scp "${BM_ORIG}:/etc/postfix/{{'{{'}}main,master}.cf,*.db,virtual*,local*,*map,*flat}" $SYNC_PREFIX/etc/postfix/
    scp    ${BM_ORIG}:/usr/share/bm-elasticsearch/config/elasticsearch.yml \
          $SYNC_PREFIX/usr/share/bm-elasticsearch/config/elasticsearch.yml
    if [[ -n $EXTERNAL_URL ]];then
        sed -i -r \
            -e "s/external-url =.*/external-url = $EXTERNAL_URL/g" \
            /etc/bm/bm.ini
    fi
    if [[ -n $DEST_IP ]];then
        sed -i -r \
            -e "s/host =.*/host = $DEST_IP/g" \
            -e "s/hz-member-address =.*/hz-member-address = $DEST_IP/g" \
            /etc/bm/bm.ini
    fi
fi

if [[ -z $NO_RESTART ]];then
    service postfix restart || die_in_error restart postfix
    bmctl           restart || die_in_error restart bmctl
fi

max=120 retry \
    curl -fsSk -X GET -H "X-BM-ApiKey: $(cat /etc/bm/bm-core.tok)" https://localhost/api/auth || die_in_error "bluemind ko"
if [[ -z $NO_REPAIR  ]];then
    if ! ( curl -fsSk -X POST -H "X-BM-ApiKey: $(cat /etc/bm/bm-core.tok)" https://localhost/api/system/maildelivery/mgmt/_repair >/dev/null; );then
        die_in_error "failed bluemind repair"
    fi
    log "postfix reconstructed"
fi
# vim:set et sts=4 ts=4 tw=80:
