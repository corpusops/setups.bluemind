#!/usr/bin/env bash
###
export SDEBUG="${SDEBUG-}"
export BM_URL="${BM_URL-{{bluemind_ext_mailname}}}"
export BM_OLD_URL="${BM_OLD_URL-{{bluemind_old_ext_mailname|default('')}}}"
export BM_ORIG="${BM_ORIG-{{bluemind_orig}}}"
export ORIG_IP="${ORIG_IP-{{bluemind_orig_ip}}}"
export DEST_IP="${DEST_IP-{{bluemind_ip}}}"
export SYNC_PREFIX=${SYNC_PREFIX-}
export HARDSYNC="${HARDSYNC-{{bluemind_hard_sync and 'y' or ''}}}"
export NO_DATA="${NO_DATA-{{bluemind_no_data|default('')}}}"
export NO_MAILS="${NO_MAILS-{{bluemind_no_mails|default('')}}}"
export NO_ES="${NO_ES-{{bluemind_no_es|default('')}}}"
export NO_CONF="${NO_CONF-{{NO_CONF|default('')}}}"
export NO_CHANGE_URL="${NO_CHANGE_URL-}"
export NO_NGINX="${NO_NGINX-{{NO_NGINX|default('')}}}"
export NO_REPAIR="${NO_REPAIR-{{NO_REEPAIR|default('')}}}"
export NO_DB="${NO_DB-{{NO_DB|default('')}}}"
export NO_DB_RESTORE="${NO_DB_RESTORE-{{bluemind_no_db_restore|default('')}}}"
export USE_DB_DUMP="${USE_DB_DUMP-{{bluemind_no_db_sync|default('')}}}"
export NO_DB_FIX="${NO_DB_FIX-{{bluemind_no_db_fix|default('')}}}"
export RSYNC="rsync -aAHzv --numeric-ids"
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
        $RSYNCD ${BM_ORIG}:/var/spool/bm-replication/   $SYNC_PREFIX/var/spool/bm-replication/
        if [[ -z $NO_ES ]];then
            $RSYNCD ${BM_ORIG}:/var/spool/bm-elasticsearch/ $SYNC_PREFIX/var/spool/bm-elasticsearch/
        fi
    fi
    if [[ -z $NO_DB ]];then
        if [[ -z $NO_DB_RESTORE ]];then
            if [[ -z $USE_DB_DUMP ]];then
                service postgresql stop || /bin/true
                $RSYNCD ${BM_ORIG}:/var/lib/postgresql/ $SYNC_PREFIX/var/lib/postgresql/
                service postgresql restart
            else
                ( ssh ${BM_ORIG} "PGPASSWORD={{bluemind_orig_pg_password}} pg_dump -U {{bluemind_orig_pg_user}} -h {{bluemind_orig_pg_host}} {{bluemind_orig_pg_db}}" > /tmp/db.sql ) &&\
                    su postgres - -c "dropdb {{bluemind_pg_db}} && createdb {{bluemind_pg_db}}" && \
                ( export PGPASSWORD={{bluemind_pg_password}}; \
                    cat /tmp/db.sql | psql -U {{bluemind_pg_user}} -h {{bluemind_pg_host}} {{bluemind_pg_db}}; \
                )
            fi
            die_in_error pgsql restore
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
fi
if [[ -z $NO_CHANGE_URL ]];then
    /sbin/bm-change-url.sh "$BM_URL" || die_in_error post change url
fi

# vim:set et sts=4 ts=4 tw=120:
