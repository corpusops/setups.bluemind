#!/usr/bin/env bash
export NO_RESTART="${NO_RESTART-}"
export NO_REPAIR="${NO_REPAIR-{{NO_REEPAIR|default('')}}}"

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

if [[ -z $NO_RESTART ]];then
    service postfix restart || die_in_error restart postfix
    bmctl           restart || die_in_error restart bmctl
fi
max=120 retry \
    curl -fsSk -X GET -H "X-BM-ApiKey: $(cat /etc/bm/bm-core.tok)" https://localhost/api/auth || die_in_error "bluemind ko"
if [[ -z $NO_REPAIR  ]];then 
    if ! ( curl -fsSk -X POST -H "X-BM-ApiKey: $(cat /etc/bm/bm-core.tok)" https://localhost/api/system/security/_updatefirewallrules >/dev/null; );then
        die_in_error "failed bluemind gfw repair"
    fi
    log "postfix reconstructed"
    if ! ( curl -fsSk -X POST -H "X-BM-ApiKey: $(cat /etc/bm/bm-core.tok)" https://localhost/api/system/maildelivery/mgmt/_repair >/dev/null; );then
        die_in_error "failed bluemind repair"
    fi
    log "postfix reconstructed"
fi
# vim:set et sts=4 ts=4 tw=80:
