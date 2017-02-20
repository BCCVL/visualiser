FROM hub.bccvl.org.au/bccvl/visualiserbase:2017-02-20

# configure pypi index to use
ARG PIP_INDEX_URL
ARG PIP_TRUSTED_HOST
# If set, pip will look for pre releases
ARG PIP_PRE

RUN groupadd -g 427 visualiser && \
    useradd -m -g visualiser -u 427 visualiser

COPY files/visualiser.ini /etc/opt/visualiser/visualiser.ini
COPY [ "files/entrypoint.sh", \
       "requirements.txt", \
       "/" ]

RUN export PIP_INDEX_URL=${PIP_INDEX_URL} && \
    export PIP_TRUSTED_HOST=${PIP_TRUSTED_HOST} && \
    export PIP_NO_CACHE_DIR=False && \
    export PIP_PRE=${PIP_PRE} && \
    pip install -r requirements.txt && \
    pip install repoze.vhm && \
    pip install gunicorn

ENV VISUALISER_DATA_DIR="/var/opt/visualiser/" \
    AUTHTKT_SECRET="secret" \
    NWORKERS=4 \
    NTHREADS=2 \
    CONFIG="/etc/opt/visualiser/visualiser.ini"

RUN mkdir -p /var/opt/visualiser && \
    chown -R visualiser:visualiser /var/opt/visualiser

EXPOSE 10600

ENTRYPOINT ["/entrypoint.sh"]

# default param to entrypoint
CMD ["visualiser"]
