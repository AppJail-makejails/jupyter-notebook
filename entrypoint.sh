#!/bin/sh

. /lib.subr

set -e

create_user

set +e

if /usr/bin/find "/entrypoint.d/" -mindepth 1 -maxdepth 1 -type f -print -quit 2>/dev/null | read v; then
    info "/entrypoint.d/ is not empty, will attempt to perform configuration"

    info "Looking for shell scripts in /entrypoint.d/"
    find "/entrypoint.d/" -follow -type f -print | sort -V | while read -r hook_file; do
        case "${hook_file}" in
            *.sh)
                info "Sourcing shell script: ${hook_file}"
                . "${hook_file}"
                hook_rc=$?
                # A sourced hook might have enabled errexit and left it on,
                # so disable it again before running the next hook
                set +e
                if [ "${hook_rc}" -ne 0 ]; then
                    warn "${hook_file} has failed, continuing execution"
                fi
                ;;
            *)
                if [ -x "${hook_file}" ]; then
                    info "Running executable: ${hook_file}"
                    "${hook_file}"
                    hook_rc=$?
                    if [ "${hook_rc}" -ne 0 ]; then
                        warn "${hook_file} has failed, continuing execution"
                    fi
                else
                    # warn on shell scripts without exec bit
                    info "Ignoring non-executable: ${hook_file}";
                fi
                ;;
        esac
    done

    info "Configuration complete; ready for start up"
else
    info "No files found in /entrypoint.d/, skipping configuration"
fi

set -e

cmd="$1"

if [ "${cmd#-}" != "${cmd}" ]; then
    set -- start-notebook.py "$@"
    cmd="$1"
fi

case "$1" in
    start-notebook.py|start-singleuser.py)
        shift
        set -- su-exec noroot "/${cmd}" "$@"
        ;;
esac

exec "$@"
