#!/bin/bash
mkdir -p "${STEAMAPPDIR}" || true

# Download Updates

bash "${STEAMCMDDIR}/steamcmd.sh" +force_install_dir "${STEAMAPPDIR}" \
				+login "${STEAMUSER}" "${STEAMPASS}" \
				+app_update "${STEAMAPPID}" \
				+quit

# Rewrite Config Files
if [[ ! -z $CS2_BOT_DIFFICULTY ]] ; then
    sed -i "s/bot_difficulty.*/bot_difficulty ${CS2_BOT_DIFFICULTY}/" /home/steam/cs2-dedicated/game/csgo/cfg/*
fi
if [[ ! -z $CS2_BOT_QUOTA ]] ; then
    sed -i "s/bot_quota.*/bot_quota ${CS2_BOT_QUOTA}/" /home/steam/cs2-dedicated/game/csgo/cfg/*
fi
if [[ ! -z $CS2_BOT_QUOTA_MODE ]] ; then
    sed -i "s/bot_quota_mode.*/bot_quota_mode ${CS2_BOT_QUOTA_MODE}/" /home/steam/cs2-dedicated/game/csgo/cfg/*
fi

# Start Server

"${STEAMAPPDIR}/game/bin/linuxsteamrt64/cs2" -dedicated \
                                -usercon \
                                +game_type "${CS2_GAMETYPE}" \
                                +game_mode "${CS2_GAMEMODE}" \
                                +mapgroup "${CS2_MAPGROUP}" \
                                +map "${CS2_STARTMAP}" \
                                +sv_setsteamaccount \
                                -maxplayers_override "${CS2_MAXPLAYERS}" \
                                +rcon_password "${CS2_RCONPW}" \
                                +sv_password "${CS2_PW}" \
                                "${CS2_ADDITIONAL_ARGS}"
