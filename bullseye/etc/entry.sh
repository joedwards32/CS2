#!/bin/bash

# Create App Dir
mkdir -p "${STEAMAPPDIR}" || true

# Download Updates

bash "${STEAMCMDDIR}/steamcmd.sh" +force_install_dir "${STEAMAPPDIR}" \
				+login anonymous \
				+app_update "${STEAMAPPID}" \
				+quit

# steamclient.so fix
mkdir -p ~/.steam/sdk64
ln -sfT ${STEAMCMDDIR}/linux64/steamclient.so ~/.steam/sdk64/steamclient.so

# Install server.cfg
cp /etc/server.cfg "${STEAMAPPDIR}"/game/csgo/cfg/server.cfg

# Install hooks if they don't already exist
if [[ ! -f "${STEAMAPPDIR}/pre.sh" ]] ; then
    cp /etc/pre.sh "${STEAMAPPDIR}/pre.sh"
fi
if [[ ! -f "${STEAMAPPDIR}/post.sh" ]] ; then
    cp /etc/post.sh "${STEAMAPPDIR}/post.sh"
fi

# Download and extract custom config bundle
if [[ ! -z $CS2_CFG_URL ]]; then
    echo "Downloading config pack from ${CS2_CFG_URL}"
    wget -qO- "${CS2_CFG_URL}" | tar xvzf - -C "${STEAMAPPDIR}"
fi

# Rewrite Config Files

sed -r -i -e "s/^(hostname) .*/\1 ${CS2_SERVERNAME}/g" \
       -e "s/^(sv_cheats) .*/\1 ${CS2_CHEATS}/g" \
       -e "s/^(sv_hibernate_when_empty) .*/\1 ${CS2_SERVER_HIBERNATE}/g" \
       -e "s/^(sv_password) .*/\1 ${CS2_PW}/g" \
       -e "s/^(rcon_password) .*/\1 ${CS2_RCONPW}/g" \
       -e "s/^(tv_enable) .*/\1 ${TV_ENABLE}/g" \
       -e "s/^(tv_port) .*/\1 ${TV_PORT}/g" \
       -e "s/^(tv_autorecord) .*/\1 ${TV_AUTORECORD}/g" \
       -e "s/^(tv_password) .*/\1 ${TV_PW}/g" \
       -e "s/^(tv_relaypassword) .*/\1 ${TV_RELAY_PW}/g" \
       -e "s/^(tv_maxrate) .*/\1 ${TV_MAXRATE}/g" \
       -e "s/^(tv_delay) .*/\1 ${TV_DELAY}/g" \
       -e "s/^(tv_name) .*/\1 ${CS2_SERVERNAME} CSTV/g" \
       -e "s/^(tv_title) .*/\1${CS2_SERVERNAME} CSTV/g" \
       "${STEAMAPPDIR}"/game/csgo/cfg/server.cfg

if [[ ! -z $CS2_BOT_DIFFICULTY ]] ; then
    sed -i "s/bot_difficulty.*/bot_difficulty ${CS2_BOT_DIFFICULTY}/" "${STEAMAPPDIR}"/game/csgo/cfg/*
fi
if [[ ! -z $CS2_BOT_QUOTA ]] ; then
    sed -i "s/bot_quota.*/bot_quota ${CS2_BOT_QUOTA}/" "${STEAMAPPDIR}"/game/csgo/cfg/*
fi
if [[ ! -z $CS2_BOT_QUOTA_MODE ]] ; then
    sed -i "s/bot_quota_mode.*/bot_quota_mode ${CS2_BOT_QUOTA_MODE}/" "${STEAMAPPDIR}"/game/csgo/cfg/*
fi

# Switch to server directory
cd "${STEAMAPPDIR}/game/bin/linuxsteamrt64"

# Pre Hook
bash "${STEAMAPPDIR}/pre.sh"

# Construct server arguments

if [[ -z $CS2_GAMEALIAS ]]; then
    # If CS2_GAMEALIAS is undefined then default to CS2_GAMETYPE and CS2_GAMEMODE
    CS2_GAME_MODE_ARGS="+game_type ${CS2_GAMETYPE} +game_mode ${CS2_GAMEMODE}"
else
    # Else, use alias to determine game mode
    CS2_GAME_MODE_ARGS="+game_alias ${CS2_GAMEALIAS}"
fi

if [[ -z $CS2_IP ]]; then
    CS2_IP_ARGS=""
else
    CS2_IP_ARGS="-ip ${CS2_IP}"
fi

if [[ ! -z $SRCDS_TOKEN ]]; then
    SV_SETSTEAMACCOUNT_ARGS="+sv_setsteamaccount ${SRCDS_TOKEN}"
fi

# Start Server

if [[ ! -z $CS2_RCON_PORT ]]; then
    echo "Establishing Simpleproxy for ${CS2_RCON_PORT} to 127.0.0.1:${CS2_PORT}"
    simpleproxy -L "${CS2_RCON_PORT}" -R 127.0.0.1:"${CS2_PORT}" &
fi

echo "Starting CS2 Dedicated Server"
eval "./cs2" -dedicated \
        "${CS2_IP_ARGS}" -port "${CS2_PORT}" \
        -console \
        -usercon \
        -maxplayers "${CS2_MAXPLAYERS}" \
        "${CS2_GAME_MODE_ARGS}" \
        +mapgroup "${CS2_MAPGROUP}" \
        +map "${CS2_STARTMAP}" \
        +rcon_password "${CS2_RCONPW}" \
        "${SV_SETSTEAMACCOUNT_ARGS}" \
        +sv_password "${CS2_PW}" \
        +sv_lan "${CS2_LAN}" \
        "${CS2_ADDITIONAL_ARGS}"

# Post Hook
bash "${STEAMAPPDIR}/post.sh"
