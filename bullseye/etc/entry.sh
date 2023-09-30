#!/bin/bash
mkdir -p "${STEAMAPPDIR}" || true

bash "${STEAMCMDDIR}/steamcmd.sh" +force_install_dir "${STEAMAPPDIR}" \
				+login "${STEAMUSER}" "${STEAMPASS}" \
				+app_update "${STEAMAPPID}" \
				+quit


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
