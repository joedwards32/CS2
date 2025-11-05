###########################################################
# Dockerfile that builds a CS2 Gameserver
###########################################################

# Global ARGs

ARG PUID=1000
ARG PGID=1000
ARG USER=steam
ARG HOMEDIR="/home/steam"
ARG STEAMCMDDIR="${HOMEDIR}/steamcmd"

# SteamCMD Stage

FROM registry.gitlab.steamos.cloud/steamrt/sniper/platform as steamcmd

LABEL maintainer="joedwards32@gmail.com"

ARG PUID
ARG PGID
ARG USER
ARG HOMEDIR
ARG STEAMCMDDIR

RUN set -x \
	# Install, update & upgrade packages
	&& apt-get update \
	&& apt-get install -y --no-install-recommends --no-install-suggests \
		wget \
		ca-certificates \
		lib32z1 \
                simpleproxy \
                libicu-dev \
                unzip \
		jq \
        && useradd -u "${PUID}" -m "${USER}" \
	&& mkdir -p "${STEAMCMDDIR}" \
	# Add entry script
	&& chown -R "${PUID}:${PGID}" "${HOMEDIR}" \
	# Clean up
        && apt-get clean \
        && find /var/lib/apt/lists/ -type f -delete \
        && su "${USER}" -c \
                "curl -fsSL 'https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz' | tar xvzf - -C \"${STEAMCMDDIR}\" \
                && \"./${STEAMCMDDIR}/steamcmd.sh\" +quit "

# CS2

FROM steamcmd AS cs2

ARG PUID
ARG PGID
ARG USER
ARG HOMEDIR
ARG STEAMCMDDIR

ENV STEAMAPPID=730
ENV STEAMAPP=cs2
ENV STEAMCMDDIR="${STEAMCMDDIR}"
ENV STEAMAPPDIR="${HOMEDIR}/${STEAMAPP}-dedicated"
ENV STEAMAPPVALIDATE=0

COPY etc/entry.sh "${HOMEDIR}/entry.sh"
COPY etc/server.cfg "/etc/server.cfg"
COPY etc/pre.sh "/etc/pre.sh"
COPY etc/post.sh "/etc/post.sh"

ENV CS2_SERVERNAME="cs2 private server" \
    CS2_CHEATS=0 \
    CS2_IP=0.0.0.0 \
    CS2_SERVER_HIBERNATE=0 \
    CS2_PORT=27015 \
    CS2_RCON_PORT="" \
    CS2_MAXPLAYERS=10 \
    CS2_RCONPW="changeme" \
    CS2_MAPGROUP="mg_active" \    
    CS2_STARTMAP="de_inferno" \
    CS2_GAMEALIAS="" \
    CS2_GAMETYPE=0 \
    CS2_GAMEMODE=1 \
    CS2_LAN=0 \
    TV_AUTORECORD=0 \
    TV_ENABLE=0 \
    TV_PORT=27020 \
    TV_PW="changeme" \
    TV_RELAY_PW="changeme" \
    TV_MAXRATE=0 \
    TV_DELAY=0 \
    SRCDS_TOKEN="" \
    CS2_CFG_URL="" \
    CS2_LOG="on" \
    CS2_LOG_MONEY=0 \
    CS2_LOG_DETAIL=0 \
    CS2_LOG_ITEMS=0 \
    CS2_ADDITIONAL_ARGS=""

# Set permissions on STEAMAPPDIR
#   Permissions may need to be reset if persistent volume mounted
RUN set -x \
	&& mkdir -p "${STEAMAPPDIR}" \
	&& chmod +x "${HOMEDIR}/entry.sh" \
        && chown -R "${PUID}:${PGID}" "${STEAMAPPDIR}" \
        && chmod 0777 "${STEAMAPPDIR}"

# Switch to user
USER ${PUID}:${PGID}

WORKDIR ${HOMEDIR}

CMD ["bash", "entry.sh"]

# Expose ports
EXPOSE 27015/tcp \
	27015/udp \
	27020/udp
