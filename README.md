[![Docker Image CI](https://github.com/joedwards32/CS2/actions/workflows/docker-image.yml/badge.svg?branch=main)](https://github.com/joedwards32/CS2/actions/workflows/docker-image.yml) [![Docker Build and Publish](https://github.com/joedwards32/CS2/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/joedwards32/CS2/actions/workflows/docker-publish.yml)

# What is Counter-Strike 2?
For over two decades, Counter-Strike has offered an elite competitive experience, one shaped by millions of players from across the globe. And now the next chapter in the CS story is about to begin. This is Counter-Strike 2. 
This Docker image contains the dedicated server of the game.

>  [CS2](https://store.steampowered.com/app/730/CounterStrike_2/)

<img src="https://cdn.cloudflare.steamstatic.com/steam/apps/730/header.jpg?t=1696011820" alt="logo" width="300"/></img>

# How to use this image
## Hosting a simple game server

Running using Docker:
```console
$ SRCDS_TOKEN="..." # check https://steamcommunity.com/dev/managegameservers
$ docker run -d --name=cs2 -e SRCDS_TOKEN="$SRCDS_TOKEN" -p 27015:27015/tcp -p 27015:27015/udp -p 27020:27020/udp joedwards32/cs2
```

Running using a bind mount for data persistence on container recreation:
```console
$ mkdir -p $(pwd)/cs2-data
$ chown 1000:1000 $(pwd)/cs2-data # Makes sure the directory is writeable by the unprivileged container user with uid 1000, known as steam
$ SRCDS_TOKEN="..." # check https://steamcommunity.com/dev/managegameservers
$ docker run -d --name=cs2 -e SRCDS_TOKEN="$SRCDS_TOKEN" -v $(pwd)/cs2-data:/home/steam/cs2-dedicated/ -p 27015:27015/tcp -p 27015:27015/udp -p 27020:27020/udp joedwards32/cs2
```

or using docker-compose, see [examples](https://github.com/joedwards32/CS2/blob/main/examples/docker-compose.yml):
```console
# Remember to update passwords and SRCDS_TOKEN in your compose file
$ docker compose --file examples/docker-compose.yml up -d cs2-server
```

You must have at least **40GB** of free disk space! See [System Requirements](./#system-requirements).

**The container will automatically update the game on startup, so if there is a game update just restart the container.**

# Configuration

## System Requirements

Minimum system requirements are:

* 2 CPUs
* 2GiB RAM
* 40GB of disk space for the container or mounted as a persistent volume on `/home/steam/cs2-dedicated/`

## Environment Variables
Feel free to overwrite these environment variables, using -e (--env): 

### Server Configuration

```dockerfile
SRCDS_TOKEN=""              (Game Server Token from https://steamcommunity.com/dev/managegameservers)
CS2_SERVERNAME="changeme"   (Set the visible name for your private server)
CS2_CHEATS=0                (0 - disable cheats, 1 - enable cheats)
CS2_SERVER_HIBERNATE=0      (Put server in a low CPU state when there are no players. 
                             0 - hibernation disabled, 1 - hibernation enabled
                             n.b. hibernation has been observed to trigger server crashes)
CS2_IP=""                   (CS2 server listening IP address, 0.0.0.0 - all IP addresses on the local machine, empty - IP identified automatically)
CS2_PORT=27015              (CS2 server listen port tcp_udp)
CS2_RCON_PORT=""            (Optional, use a simple TCP proxy to have RCON listen on an alternative port.
                             Useful for services like AWS Fargate which do not support mixed protocol ports.)
CS2_LAN="0"                 (0 - LAN mode disabled, 1 - LAN Mode enabled)
CS2_RCONPW="changeme"       (RCON password)
CS2_PW="changeme"           (CS2 server password)
CS2_MAXPLAYERS=10           (Max players)
CS2_ADDITIONAL_ARGS=""      (Optional additional arguments to pass into cs2)
```

**Note:** When using `CS2_RCON_PORT` don't forget to map the port chosen with TCP protocol (e.g., add `-p 27050:27050/tcp` on the `docker run` command or add the port to the `docker-compose.yml` file).

### Game Modes

```dockerfile
CS2_GAMEALIAS=""            (Game type, e.g. casual, competitive, deathmatch.
                             See https://developer.valvesoftware.com/wiki/Counter-Strike_2/Dedicated_Servers)
CS2_GAMETYPE=0              (Used if CS2_GAMEALIAS not defined. See https://developer.valvesoftware.com/wiki/Counter-Strike_2/Dedicated_Servers)
CS2_GAMEMODE=1              (Used if CS2_GAMEALIAS not defined. See https://developer.valvesoftware.com/wiki/Counter-Strike_2/Dedicated_Servers)
CS2_MAPGROUP="mg_active"    (Map pool)
CS2_STARTMAP="de_inferno"   (Start map)
```

### Bots

```dockerfile
CS2_BOT_DIFFICULTY=""       (0 - easy, 1 - normal, 2 - hard, 3 - expert)
CS2_BOT_QUOTA=""            (Number of bots)
CS2_BOT_QUOTA_MODE=""       (fill, competitive)
```

### CSTV/SourceTV

```dockerfile
TV_ENABLE=0                 (0 - disable, 1 - enable)
TV_PORT=27020               (SourceTV/CSTV port to bind to)
TV_AUTORECORD=0             (Automatically record all games as CSTV demos: 0=off, 1=on)
TV_PW="changeme"            (CSTV password for clients)
TV_RELAY_PW="changeme"      (CSTV password for relay proxies)
TV_MAXRATE=0                (Max CSTV spectator bandwidth rate allowed, 0 == unlimited)
TV_DELAY=0                  (CSTV broadcast delay in seconds)
```

### Logs

```dockerfile
CS2_LOG="on"                ('on'/'off')
CS2_LOG_MONEY=0             (Turns money logging on/off: 0=off, 1=on)
CS2_LOG_DETAIL=0            (Combat damage logging: 0=disabled, 1=enemy, 2=friendly, 3=all)
CS2_LOG_ITEMS=0             (Turns item logging on/off: 0=off, 1=on)
```

# Customizing this Container

## Validating Game Files

If you break the game through your customisations and want steamcmd to validate and redownload then set the `STEAMAPPVALIDATE` environment variable to `1`:

```dockerfile
STEAMAPPVALIDATE=0          (0=skip validation, 1=validate game files)
```

## Pre and Post Hooks

The container includes two scripts for executing custom actions:

* `/home/steam/cs2-dedicated/pre.sh` is executed before the CS2 server starts
* `/home/steam/cs2-dedicated/post.sh` is executed after the CS2 server stops

When using a persient volume mounted at `/home/steam/cs2-dedicated/` you may edit these scripts to perform custom actions, such as enabling metamod.

## Overriding Game Mode Defaults

The default configurations for each game mode are stored in `/home/steam/cs2-dedicated/game/csgo/cfg/`. For example, the Competitive mode defaults are set by `gamemode_competitive.cfg`.

When using a persistent volume mounted at `/home/steam/cs2-dedicated/`, these defaults can be overridden by adding your own settings to `gamemode_competitive_server.cfg`.

```
// Game Mode Competitive Server Overrides 

mp_maxrounds	16	// Shorter games
```

## Customisation Bundle

The container can be instructed to download a extract a Tar Gzip of configuration files and other customisations from a given URL.

```dockerfile
CS2_CFG_URL=""          (HTTP/HTTPS URL to fetch a Tar Gzip bundle of configuration files/mods)
```

See [examples](https://github.com/joedwards32/CS2/blob/main/examples/cs2.cfg.tgz) for a correctly formatted Tar Gzip customisation bundle.


# Credits

This container leans heavily on the work of [CM2Walki](https://github.com/CM2Walki/), especially his [SteamCMD](https://github.com/CM2Walki/steamcmd) container image. GG!
