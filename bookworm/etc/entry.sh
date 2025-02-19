#!/bin/bash

# Debug

## Steamcmd debugging
if [[ $DEBUG -eq 1 ]] || [[ $DEBUG -eq 3 ]]; then
    STEAMCMD_SPEW="+set_spew_level 4 4"
fi
## CS2 server debugging
if [[ $DEBUG -eq 2 ]] || [[ $DEBUG -eq 3 ]]; then
    CS2_LOG="on"
    CS2_LOG_MONEY=1
    CS2_LOG_DETAIL=3
    CS2_LOG_ITEMS=1
fi

# Create App Dir
mkdir -p "${STEAMAPPDIR}" || true

# Download Updates
if [[ "$STEAMAPPVALIDATE" -eq 1 ]]; then
    VALIDATE="validate"
else
    VALIDATE=""
fi

## SteamCMD can fail to download
## Retry logic
MAX_ATTEMPTS=3
attempt=0
while [[ $steamcmd_rc != 0 ]] && [[ $attempt -lt $MAX_ATTEMPTS ]]; do
    ((attempt+=1))
    if [[ $attempt -gt 1 ]]; then
        echo "Retrying SteamCMD, attempt ${attempt}"
        # Stale appmanifest data can lead for HTTP 401 errors when requesting old
        # files from SteamPipe CDN
        echo "Removing steamapps (appmanifest data)..."
        rm -rf "${STEAMAPPDIR}/steamapps"
    fi
    eval bash "${STEAMCMDDIR}/steamcmd.sh" "${STEAMCMD_SPEW}"\
                                +force_install_dir "${STEAMAPPDIR}" \
                                +@bClientTryRequestManifestWithoutCode 1 \
				+login anonymous \
				+app_update "${STEAMAPPID}" "${VALIDATE}"\
				+quit
    steamcmd_rc=$?
done

## Exit if steamcmd fails
if [[ $steamcmd_rc != 0 ]]; then
    exit $steamcmd_rc
fi

# steamclient.so fix
mkdir -p ~/.steam/sdk64
ln -sfT ${STEAMCMDDIR}/linux64/steamclient.so ~/.steam/sdk64/steamclient.so

# Install server.cfg
mkdir -p $STEAMAPPDIR/game/csgo/cfg
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

    TEMP_DIR=$(mktemp -d)
    TEMP_FILE="${TEMP_DIR}/$(basename ${CS2_CFG_URL})"
    wget -qO "${TEMP_FILE}" "${CS2_CFG_URL}"

    case "${TEMP_FILE}" in
        *.zip)
            echo "Extracting ZIP file..."
            unzip -q "${TEMP_FILE}" -d "${STEAMAPPDIR}"
            ;;
        *.tar.gz | *.tgz)
            echo "Extracting TAR.GZ or TGZ file..."
            tar xvzf "${TEMP_FILE}" -C "${STEAMAPPDIR}"
            ;;
        *.tar)
            echo "Extracting TAR file..."
            tar xvf "${TEMP_FILE}" -C "${STEAMAPPDIR}"
            ;;
        *)
            echo "Unsupported file type"
            rm -rf "${TEMP_DIR}"
            exit 1
            ;;
    esac

    rm -rf "${TEMP_DIR}"
fi

# Rewrite Config Files

sed -i -e "s/{{SERVER_HOSTNAME}}/${CS2_SERVERNAME}/g" \
       -e "s/{{SERVER_CHEATS}}/${CS2_CHEATS}/g" \
       -e "s/{{SERVER_HIBERNATE}}/${CS2_SERVER_HIBERNATE}/g" \
       -e "s/{{SERVER_PW}}/${CS2_PW}/g" \
       -e "s/{{SERVER_RCON_PW}}/${CS2_RCONPW}/g" \
       -e "s/{{TV_ENABLE}}/${TV_ENABLE}/g" \
       -e "s/{{TV_PORT}}/${TV_PORT}/g" \
       -e "s/{{TV_AUTORECORD}}/${TV_AUTORECORD}/g" \
       -e "s/{{TV_PW}}/${TV_PW}/g" \
       -e "s/{{TV_RELAY_PW}}/${TV_RELAY_PW}/g" \
       -e "s/{{TV_MAXRATE}}/${TV_MAXRATE}/g" \
       -e "s/{{TV_DELAY}}/${TV_DELAY}/g" \
       -e "s/{{SERVER_LOG}}/${CS2_LOG}/g" \
       -e "s/{{SERVER_LOG_MONEY}}/${CS2_LOG_MONEY}/g" \
       -e "s/{{SERVER_LOG_DETAIL}}/${CS2_LOG_DETAIL}/g" \
       -e "s/{{SERVER_LOG_ITEMS}}/${CS2_LOG_ITEMS}/g" \
       "${STEAMAPPDIR}"/game/csgo/cfg/server.cfg

if [[ ! -z $CS2_BOT_DIFFICULTY ]] ; then
    sed -i "s/bot_difficulty.*/bot_difficulty ${CS2_BOT_DIFFICULTY}/" "${STEAMAPPDIR}"/game/csgo/cfg/*
fi
if [[ ! -z $CS2_BOT_QUOTA ]] ; then
    sed -ri "s/bot_quota[[:space:]]+.*/bot_quota ${CS2_BOT_QUOTA}/" "${STEAMAPPDIR}"/game/csgo/cfg/*
fi
if [[ ! -z $CS2_BOT_QUOTA_MODE ]] ; then
    sed -i "s/bot_quota_mode.*/bot_quota_mode ${CS2_BOT_QUOTA_MODE}/" "${STEAMAPPDIR}"/game/csgo/cfg/*
fi

# Switch to server directory
cd "${STEAMAPPDIR}/game/bin/linuxsteamrt64"

# Pre Hook
source "${STEAMAPPDIR}/pre.sh"

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

if [[ ! -z $CS2_HOST_WORKSHOP_COLLECTION ]] || [[ ! -z $CS2_HOST_WORKSHOP_MAP ]]; then
    CS2_MP_MATCH_END_CHANGELEVEL="+mp_match_end_changelevel true"   # https://github.com/joedwards32/CS2/issues/57#issuecomment-2245595368
    CS2_STARTMAP="\<empty\>"                                        # https://github.com/joedwards32/CS2/issues/57#issuecomment-2245595368
    CS2_MAPGROUP_ARGS=
else
    CS2_MAPGROUP_ARGS="+mapgroup ${CS2_MAPGROUP}"
fi

if [[ ! -z $CS2_HOST_WORKSHOP_COLLECTION ]]; then
    CS2_HOST_WORKSHOP_COLLECTION_ARGS="+host_workshop_collection ${CS2_HOST_WORKSHOP_COLLECTION}"
fi

if [[ ! -z $CS2_HOST_WORKSHOP_MAP ]]; then
    CS2_HOST_WORKSHOP_MAP_ARGS="+host_workshop_map ${CS2_HOST_WORKSHOP_MAP}"
fi

if [[ ! -z $CS2_PW ]]; then
    CS2_PW_ARGS="+sv_password ${CS2_PW}"
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
        "${CS2_MAPGROUP_ARGS}" \
        +map "${CS2_STARTMAP}" \
        "${CS2_HOST_WORKSHOP_COLLECTION_ARGS}" \
        "${CS2_HOST_WORKSHOP_MAP_ARGS}" \
        "${CS2_MP_MATCH_END_CHANGELEVEL}" \
        +rcon_password "${CS2_RCONPW}" \
        "${SV_SETSTEAMACCOUNT_ARGS}" \
        "${CS2_PW_ARGS}" \
        +sv_lan "${CS2_LAN}" \
        +tv_port "${TV_PORT}" \
        "${CS2_ADDITIONAL_ARGS}"

# Post Hook
source "${STEAMAPPDIR}/post.sh"
