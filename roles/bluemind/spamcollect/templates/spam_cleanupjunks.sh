#!/usr/bin/env bash
if [[ -n $DEBUG ]];then
    set -x
fi
export PATH=/root/.vim/bin:/root/.vim/venv/bin:/root/.vim/bin:/root/.vim/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:$PATH
W=${W:-$(pwd)}
RED="\\e[0;31m"
CYAN="\\e[0;36m"
YELLOW="\\e[0;33m"
NORMAL="\\e[0;0m"
NO_COLOR=${NO_COLORS-${NO_COLORS-${NOCOLOR-${NOCOLORS-}}}}
LOGGER_NAME=${LOGGER_NAME:-cleanup}
ERROR_MSG="There were errors"

reset_colors() {
    if [[ -n ${NO_COLOR} ]]; then
        BLUE=""
        YELLOW=""
        RED=""
        CYAN=""
    fi
}

log_() {
    reset_colors
    logger_color=${1:-${RED}}
    msg_color=${2:-${YELLOW}}
    shift;shift;
    logger_slug="${logger_color}[${LOGGER_NAME}]${NORMAL} "
    if [[ -n ${NO_LOGGER_SLUG} ]];then
        logger_slug=""
    fi
    printf "${logger_slug}${msg_color}$(echo "${@}")${NORMAL}\n" >&2;
    printf "" >&2;  # flush
}

log(){
    log_ "${RED}" "${CYAN}" "${@}"
}

may_die() {
    reset_colors
    thetest=${2:-1}
    rc=${2:-1}
    shift
    shift
    if [ "x${thetest}" != "x0" ]; then
        if [[ -z "${NO_HEADER-}" ]]; then
            NO_LOGGER_SLUG=y log_ "" "${CYAN}" "Problem detected:"
        fi
        NO_LOGGER_SLUG=y log_ "${RED}" "${RED}" "$@"
        exit $rc
    fi
}

die() {
    may_die 1 1 "${@}"
}

die_in_error_() {
    ret=${1}
    shift
    msg="${@:-"$ERROR_MSG"}"
    may_die "${ret}" "${ret}" "${msg}"
}

die_in_error() {
    die_in_error_ "${?}" "${@}"
}

debug() {
    if [[ -n "${DEBUG// }" ]];then
        log_ "${YELLOW}" "${YELLOW}" "${@}"
    fi
}

vvv() {
    debug "${@}"
    "${@}"
}

vv() {
    log "${@}"
    "${@}"
}

CYRUS_SPOOL=${CYRUS_SPOOL:-/var/spool/cyrus/data}
SYSADMEXPIRY="${EXPIRY:-5}"
EXPIRY="${EXPIRY:-30}"
test -e "${CYRUS_SPOOL}"
die_in_error "no cyrus spool"
while read junkf;do
    log "Cleaning $junkf"
    if test -d "${junkf}" && ! test -h "${junkf}";then
        vv find "${junkf}" -type f -mtime +${EXPIRY} -delete
    fi
    # /var/spool/cyrus/data/foo_com/domain/f/foo.com/b/user/bar/Junk
    domain=$(echo $junkf |sed -re "s/.*\/domain\/([^\/]+)\/([^/]+)\/.*$/\2/")
    mbox=$(echo $junkf |sed -re "s/.*\/(user\/.*)$/\1/")
    log "Reconstructing $mbox@$domain"
    /usr/lib/cyrus/bin/reconstruct  -U -f $mbox@$domain
done < <(find "${CYRUS_SPOOL}" -name Junk -type d)
# vim:set et sts=4 ts=4 tw=0:
