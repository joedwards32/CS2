#!/bin/bash
mkdir -p "${STEAMAPPDIR}" || true

# Download Updates

bash "${STEAMCMDDIR}/steamcmd.sh" +force_install_dir "${STEAMAPPDIR}" \
				+login "${STEAMUSER}" "${STEAMPASS}" "${STEAMGUARD}" \
				+app_update "${STEAMAPPID}" \
				+quit

# Install server.cfg
cp /etc/server.cfg "${STEAMAPPDIR}"/game/csgo/cfg/server.cfg
sed -i "s/{{SERVER_HOSTNAME}}/${CS2_SERVERNAME}/g" "${STEAMAPPDIR}"/game/csgo/cfg/server.cfg
sed -i "s/{{SERVER_PW}}/${CS2_PW}/g" "${STEAMAPPDIR}"/game/csgo/cfg/server.cfg
sed -i "s/{{SERVER_RCON_PW}}/${CS2_RCONPW}/g" "${STEAMAPPDIR}"/game/csgo/cfg/server.cfg

# Rewrite Config Files

if [[ ! -z $CS2_BOT_DIFFICULTY ]] ; then
    sed -i "s/bot_difficulty.*/bot_difficulty ${CS2_BOT_DIFFICULTY}/" "${STEAMAPPDIR}"/game/csgo/cfg/*
fi
if [[ ! -z $CS2_BOT_QUOTA ]] ; then
    sed -i "s/bot_quota.*/bot_quota ${CS2_BOT_QUOTA}/" "${STEAMAPPDIR}"/game/csgo/cfg/*
fi
if [[ ! -z $CS2_BOT_QUOTA_MODE ]] ; then
    sed -i "s/bot_quota_mode.*/bot_quota_mode ${CS2_BOT_QUOTA_MODE}/" "${STEAMAPPDIR}"/game/csgo/cfg/*
fi

# Start Server

"${STEAMAPPDIR}/game/bin/linuxsteamrt64/cs2" -dedicated \
                                -port "${CS2_PORT}" \
                                -console \
                                -usercon \
                                -maxplayers_override "${CS2_MAXPLAYERS}" \
                                +game_type "${CS2_GAMETYPE}" \
                                +game_mode "${CS2_GAMEMODE}" \
                                +mapgroup "${CS2_MAPGROUP}" \
                                +map "${CS2_STARTMAP}" \
                                +sv_setsteamaccount \
                                +rcon_password "${CS2_RCONPW}" \
                                +sv_password "${CS2_PW}" \
                                "${CS2_ADDITIONAL_ARGS}"
