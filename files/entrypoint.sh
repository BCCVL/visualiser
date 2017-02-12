#!/bin/bash
set -e

if [ "$1" = 'visualiser' ]; then
    # make sure we own the data folder (in case it is a mounted volume)
    chown -R visualiser:visualiser "${VISUALISER_DATA_DIR}"

    exec /usr/bin/gunicorn --workers ${NWORKERS} \
                           --threads ${NTHREADS} \
                           --paste ${CONFIG} \
                           --user visualiser \
                           --group visualiser \
                           $@


fi

# start any other command requested
exec "$@"
