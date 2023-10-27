###########################################################
# Dockerfile that builds a CS2 Gameserver
###########################################################

# BUILD STAGE

FROM cm2network/steamcmd:root as build_stage

LABEL maintainer="joedwards32@gmail.com"

ENV STEAMUSER "changeme"
ENV STEAMPASS "changeme"
ENV STEAMGUARD ""
ENV STEAMAPPID 730
ENV STEAMAPP cs2
ENV STEAMAPPDIR "${HOMEDIR}/${STEAMAPP}-dedicated"
ENV CFG_URL https://raw.githubusercontent.com/joedwards32/CS2/settings.tgz

COPY etc/entry.sh "${HOMEDIR}/entry.sh"
COPY etc/server.cfg "/etc/server.cfg"

RUN set -x \
	# Install, update & upgrade packages
	&& apt-get update \
	&& apt-get install -y --no-install-recommends --no-install-suggests \
		wget \
		ca-certificates \
		lib32z1 \
                simpleproxy \
	&& mkdir -p "${STEAMAPPDIR}" \
	# Add entry script
	&& chmod +x "${HOMEDIR}/entry.sh" \
	&& chown -R "${USER}:${USER}" "${HOMEDIR}/entry.sh" "${STEAMAPPDIR}" \
	# Clean up
        && apt-get clean \
        && find /var/lib/apt/lists/ -type f -delete

# BASE

FROM build_stage AS bullseye-base

ENV CS2_SERVERNAME="cs2 private server" \
    CS2_IP=0.0.0.0 \
    CS2_PORT=27015 \
    CS2_RCON_PORT="" \
    CS2_MAXPLAYERS=10 \
    CS2_RCONPW="changeme" \
    CS2_PW="changeme" \
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
    CS2_ADDITIONAL_ARGS=""

# Set permissions on STEAMAPPDIR
#   Permissions may need to be reset if persistent volume mounted
RUN set -x \
        && chown -R "${USER}:${USER}" "${STEAMAPPDIR}" \
        && chmod 0777 "${STEAMAPPDIR}"

# Switch to user
USER ${USER}

WORKDIR ${HOMEDIR}

CMD ["bash", "entry.sh"]

# Expose ports
EXPOSE 27015/tcp \
	27015/udp \
	27020/udp
