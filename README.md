[![Docker Image CI](https://github.com/joedwards32/CS2/actions/workflows/docker-image.yml/badge.svg?branch=main)](https://github.com/joedwards32/CS2/actions/workflows/docker-image.yml)

# What is Counter-Strike 2?
For over two decades, Counter-Strike has offered an elite competitive experience, one shaped by millions of players from across the globe. And now the next chapter in the CS story is about to begin. This is Counter-Strike 2. 
This Docker image contains the dedicated server of the game.

>  [CS2](https://store.steampowered.com/app/730/CounterStrike_2/)

<img src="https://cdn.cloudflare.steamstatic.com/steam/apps/730/header.jpg?t=1696011820" alt="logo" width="300"/></img>

# How to use this image
## Hosting a simple game server

Running on the *host* interface (recommended):<br/>
```console
$ docker run -d --net=host --name=cs2 -e STEAMUSER={YOUR_STEAM_USER} -e STEAMPASS={YOUR_STEAM_PASSWD} joedwards32/cs2
```

Running using a bind mount for data persistence on container recreation:
```console
$ mkdir -p $(pwd)/cs2-data
$ chmod 777 $(pwd)/cs2-data # Makes sure the directory is writeable by the unprivileged container user
$ docker run -d --net=host -v $(pwd)/cs2-data:/home/steam/cs2-dedicated/ --name=cs2-dedicated -e STEAMUSER={YOUR_STEAM_USER} -e STEAMPASS={YOUR_STEAM_PASSWD} joedwards32/cs2
```

`STEAMUSER` and `STEAMPASS` **are required as unlike CS:GO, CS2 can not be downloaded anonymously (at time of writing).**

`STEAMGUARD` **must be used to provide your more recent Steam Guard key if Steam Guard is enabled on your account.**

**The container will automatically update the game on startup, so if there is a game update just restart the container.**

# Configuration
## Environment Variables
Feel free to overwrite these environment variables, using -e (--env): 
```dockerfile
STEAMUSER="changeme"        (Steam User for SteamCMD.)
STEAMPASS="changeme"        (Password for Steam User.)
STEAMGUARD=""               (Optional, Steam Guard key if enabled. Use your most recent Steam Guard key.)
CS2_SERVERNAME="changeme"   (Set the visible name for your private server)
CS2_PORT=27015              (CS2 server listen port tcp_udp)
CS2_LAN="0"                 (0 - LAN mode disabled, 1 - LAN Mode enabled)
CS2_RCONPW="changeme"       (RCON password)
CS2_PW="changeme"           (CS2 server password)
CS2_MAXPLAYERS=10           (Max players)
CS2_GAMETYPE=0              (Game type, see https://developer.valvesoftware.com/wiki/Counter-Strike_2/Dedicated_Servers)
CS2_GAMEMODE=0              (Game mode, see https://developer.valvesoftware.com/wiki/Counter-Strike_2/Dedicated_Servers)
CS2_MAPGROUP="mg_active"    (Map pool)
CS2_STARTMAP="de_inferno"   (Start map)
CS2_ADDITIONAL_ARGS=""      (Optional additional arguments to pass into cs2)
CS2_BOT_DIFFICULTY=""       (0 - easy, 1 - normal, 2 - hard, 3 - expert)
CS2_BOT_QUOTA=""            (Number of bots)
CS2_BOT_QUOTA_MODE=""       (fill, competitive)
```

# Credits

This container leans heavily on the work of [CM2Walki](https://github.com/CM2Walki/), especially his [SteamCMD](https://github.com/CM2Walki/steamcmd) container image. GG!
