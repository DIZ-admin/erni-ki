# Open WebUI Starter
=====================

The Open WebUI Starter project is meant to provide a quick template for 
setting up [Open WebUI](https://openwebui.com/). More information can be found 
about configurations on the [Open WebUI Docs](https://docs.openwebui.com/) or the [Gitub repository](https://github.com/open-webui/open-webui).


## Project Overview

The Open WebUI Starter project is a entry into using the open-source project 
Open WebUI. Open WebUI integrates with various Large Language Models (LLMs) and provides a private, user-friendly, and local interface for interacting with computer intelligence.

## Table of Contents
1. [Dependencies](#dependencies)
1. [Tooling and Applications](#tooling-and-applications)
2. [Installation](#installation)
3. [Contribution](#contribution)

## Dependencies

- **[Git](https://git-scm.com/)**: Version control system for managing code changes
- **[Docker](https://docs.docker.com/)**: Containerization platform for running and deploying applications


## Tooling and Applications

This starter project includes the following tooling and applications.

- **[Cloudflare](https://www.cloudflare.com/)**: Platform providing anonymous proxying and SSL certificates
- **[ComfyUI](https://www.comfy.org/)**: Platform for generating node based images
- **[Docling](https://github.com/docling-project/docling-serve)**: Simplifies document processing, parsing diverse formats — including advanced PDF understanding — and providing seamless integrations with the gen AI ecosystem. (created by IBM)
- **[Edge TTS](https://github.com/rany2/edge-tts)**: Python module that using Microsoft Edge's online text-to-speech service
- **[Nginx](https://nginx.org/)**: Web server, reverse proxy, load balancer, mail proxy, and HTTP cache
- **[Ollama](https://ollama.com/)**: Local service API serving open source large language models
- **[Open WebUI](https://openwebui.com/)**: Open WebUI is an extensible, feature-rich, and user-friendly self-hosted AI platform designed to operate entirely offline
- **[Postgresql](https://www.postgresql.org/)/[PgVector](https://github.com/pgvector/pgvector)**: A free and open-source relational database management system (RDBMS) emphasizing extensibility and SQL compliance (has vector addon)
- **[Redis](https://redis.io/)**: An open source-available, in-memory storage, used as a distributed, in-memory key–value database, cache and message broker, with optional durability
- **[Searxng](https://docs.searxng.org/)**: Free internet metasearch engine for open webui tool integration
- **[Sqlite](https://www.sqlite.org/index.html)**: A C-language library that implements a small, fast, self-contained, high-reliability, full-featured, SQL database engine
- **[Watchtower](https://github.com/containrrr/watchtower)**: Automated Docker container for updating container images automatically


## Installation

To install the Open WebUI Starter project, follow these steps:

### Clone this repository

```sh
git clone https://github.com/iamobservable/open-webui-starter.git
```

### Create the docker compose and environment files

```sh
cp compose.yml.example compose.yml

cp conf/cloudflared/config.example conf/cloudflared/config.yml
cp conf/comfyui/runner-scripts/download-models.txt.example conf/comfyui/runner-scripts/download-models.txt
cp conf/nginx/nginx.example conf/nginx/nginx.conf
cp conf/nginx/conf.d/default.example conf/nginx/conf.d/default.conf
cp cong/searxng/settings.yml.example conf/searxng/settings.yml
cp conf/searxng/uwsgi.ini.example conf/searxng/uwsgi.ini

cp env/auth.example env/auth.env
cp env/cloudflared.example env/cloudflared.env
cp env/comfyui.example env/comfyui.env
cp env/db.example env/db.env
cp env/docling.example env/docling.env
cp env/edgetts.example env/edgetts.env
cp env/ollama.example env/ollama.env
cp env/openwebui.example env/openwebui.env
cp env/redis.example env/redis.env
cp env/searxng.example env/searxng.env
```

*The environment files can contain sensitive information such as API keys 
and passwords. Do not check them into source control.*

### Add a unique SEARXNG_SECRET

Make this change to your searxng environment file [env/searxng.env](http://github.com/iamobservable/open-webui-starter/blob/main/env/searxng.example#L3). The link provided will lead you to the github repository to read about it.

### Update and uncomment SEARXNG_BASE_URL

Update the [env/searxng.env](http://github.com/iamobservable/open-webui-starter/blob/main/env/searxng.example#L4) with the domain name you will be using and uncomment the line by removing the # from the beginning. The link provided will lead you to the github repository to read about it.

### Add a unique WEBUI_SECRET_KEY to your environment files

Make this change to your auth environment file [env/auth.env](http://github.com/iamobservable/open-webui-starter/blob/main/env/auth.example#L2). The link provided will lead you to the github repository to read about it.

Make this change to your openwebui environment file [env/openwebui.env](http://github.com/iamobservable/open-webui-starter/blob/main/env/openwebui.example#L37).

**Make sure the environment files match**:. This allows jwt token authentication to work with the main Open WebUI (/), swagger (/docs), redis (/redis), and searxng (/searxng)

### Add your domain name as WEBUI_URL to your environment files

Make this change to your openwebui environment file [env/openwebui.env](http://github.com/iamobservable/open-webui-starter/blob/main/env/openwebui.example#L38).

### Setup Cloudflare

Cloudflare provides a way to point web browsers to a domain name that connects to your local Open WebUI environment. The platform will also setup and provide a free certificate so you can secure your domain name with SSL.

<img src="./images/alert-original.png" alt="Beware Image" width="15" height="15"> **Beware**

One additional point about moving forward without using a proxying platform like Cloudflare. With the right tools, IP addresses can be mapped to a physical location in the real world. If you connect a domain name to your home IP without the use of a proxying platform, it is possible to [DOX](https://en.wikipedia.org/wiki/Doxing) the location. *It is in your best interest to use a proxy, thus anonymizing the location.*

#### Sign up with a [free account](https://www.cloudflare.com/plans/)

Get started using Cloudflare.

<img src="./images/cloudflare-signup.png" alt="Cloudflare Signup" align="center" width="1000">

#### Add a domain for Cloudflare to manage

This allows Cloudflare to receive visitors when they look up your domain in a browser.

<img src="./images/cloudflare-account.png" alt="Cloudflare Account" align="center" width="1000">

#### Configure a Zero Trust Network tunnel

This allows Cloudflare to send visitors to your connected environment (home or otherwise)

<img src="./images/cloudflare-tunnel.png" alt="Cloudflare Tunnel" align="center" width="1000">


### Assign your tunnel id

Update your [conf/cloudflared/config.yml line #1](https://github.com/iamobservable/open-webui-starter/blob/main/conf/cloudflare/config.example#L1) and [conf/cloudflared/config.yml line #2](https://github.com/iamobservable/open-webui-starter/blob/main/conf/cloudflare/config.example#L2) with your tunnel id. It can be found located in one of the two red rectangles on the image above.

### Assign your tunnel token

Update the [env/cloudflared.env](http://github.com/iamobservable/open-webui-starter/blob/main/env/cloudflared.example#L1) file with your token. It can be found in the red rectangle on the image below.

<img src="./images/cloudflare-connector.png" alt="Cloudflare Connector" align="center" width="1000">

### Add your domain name

Update the [conf/nginx/default.conf](https://github.com/iamobservable/open-webui-starter/blob/main/conf/nginx/default.example#L34) file with your domain name. The link provided will show you the specific line in the file to change.

### Start your docker container environment from a terminal

You are ready to start up the containers. Let's do it!

```sh
docker compose up -d
```

### Download your first Ollama model from a terminal

You are ready to download an LLM for Ollama. Llama3.2:3b is listed below, but feel free to change this to any model you feel is right. [More on Ollama models](https://ollama.com/search)

```sh
docker compose exec ollama bash

ollama pull llama3.2:3b
```

Once the containers are started, and your model downloaded, you are ready to access the Open WebUI platform. Visit 
`http://<domain-name>/` in your web browser.



## Additional Setup

### Adding models to ComfyUI

The starter makes use of the docker image [yanwk/comfyui-boot:cu124-slim](https://github.com/YanWenKun/ComfyUI-Docker/tree/main/cu124-slim) for building the ComfyUI container.  This image has a special file [download-models.txt](https://github.com/iamobservable/open-webui-starter/blob/main/conf/comfyui/runner-scripts/model-downloads.txt.example). The file is responsible for configuring model downloads during the initial startup. It has a structure that allows you to provide a download image, directory path (dir), and a file name (out) in a list based row format. The models are listed with their name, link and file size.

**Format definition**

```
<model-download-url>
  dir=<directory-path>
  out=<output-file-name>
```

The base docker image includes the following models:

- [taesd_decoder](https://raw.githubusercontent.com/madebyollin/taesd/main/taesd_decoder.pth) (4.8MB)
- [taesdxl_decoder](https://raw.githubusercontent.com/madebyollin/taesd/main/taesdxl_decoder.pth) (4.8MB)
- [taesd3_decoder](https://raw.githubusercontent.com/madebyollin/taesd/main/taesd3_decoder.pth) (4.8MB)
- [taef1_decoder](https://raw.githubusercontent.com/madebyollin/taesd/main/taef1_decoder.pth) (4.8MB)

The starter follows the [Open WebUI docs](https://docs.openwebui.com/tutorials/images/#setting-up-flux1-models) on model setup and adds the models provided.

*As a reminder, you will not need to download any of the models listed above on your own. By starting the containers, the ComfyUI container will download these models automatically!*

- [ae.safetensors](https://huggingface.co/black-forest-labs/FLUX.1-schnell/resolve/main/ae.safetensors) (327.4MB)
- [clip_l.safetensors](https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/clip_l.safetensors) (240.3MB)
- [t5xxl_fp8_e4m3fn.safetensors](https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp8_e4m3fn.safetensors) (4.8GB)
- [flux1-schnell-fp8.safetensors](https://huggingface.co/Comfy-Org/flux1-schnell/resolve/main/flux1-schnell-fp8.safetensors) (17.2GB)
- [flux1-dev-fp8.safetensors](https://huggingface.co/Comfy-Org/flux1-schnell/resolve/main/flux1-dev-fp8.safetensors) (17.2GB)

***The models will take a considerable amount of time to download, depending on your internet connection, and will not be immediately ready to use when you first start your containers.***

If you want to add additional models to your container, update the [conf/comfyui/runner-scripts/download-models.txt](https://github.com/iamobservable/open-webui-starter/blob/main/conf/comfyui/runner-scripts/model-downloads.txt.example) file located in your project directory.


### Watchtower and Notifications

A Watchtower container provides a convenient way to check in on your container 
versions to see if updates have been released. Once updates are found, Watchtower 
will pull the latest container image(s), stop the currently running container and 
start a new container based on the new image. After completing its process, 
Watchtower can send notifications to you. More can be found on notifications via 
the [Watchtower website](https://containrrr.dev/watchtower/notifications/).

For the sake of simplicity, this document will cover the instructions for setting 
up notifications via Discord. If you desire to be more detailed in your configuration, 
the [arguments section](https://containrrr.dev/watchtower/arguments/) describes 
additional settings available for the watchtower setup.

1. Edit your [env/watchtower.env](https://github.com/iamobservable/open-webui-starter/blob/main/env/watchtower.example#L2) with your discord link. [More information](https://containrrr.dev/shoutrrr/v0.8/services/discord/) is provided on how to create your discord link (token@webhookid).
2. Restart your watchtower container

```bash
docker compose down watchtower && docker compose up watchtower -d
```

### Legacy migration for Sqlite to Postgresql

For installations where the environment was already setup to use Sqlite. If you want to move to Postgresql, you can follow along below. There is also another solution, created by [Taylor Wilsdon](https://github.com/taylorwilsdon), that can be found on his github repository [open-webui-postgres-migration](https://github.com/taylorwilsdon/open-webui-postgres-migration) that looks pretty nice.

*** Tested using node v22.12.0 ***

Depending on your setup, you may need to expose your postgresql (db) container 
port before proceeding. By default, this project's db container is not exposing 
a port. 

***example***

```yaml
services:
  db:
image: pgvector/pgvector:pg15
    ports:
      - 5432:5432
```

1. Change to the migrator folder and install node packages

```bash
cd migrator
npm install
```

2. Execute migrate.js file with node. Adjust the following command with your 
specific configuration locations, user, password, and database names.

```bash
node migrate.js ../data/openwebui/webui.db "postgresql://postgres:postgres@localhost/openwebui"
```

3. Update your [env/openwebui.env](https://github.com/iamobservable/open-webui-starter/blob/main/env/openwebui.example#L11) file to add the following line. This configuration expects that you are using the default DATABASE_URL.

```env
DATABASE_URL="postgresql://postgres:postgres@localhost/openwebui"
```

4. Remove and restart your postgresql container
```bash
docker compose down db && docker compose up db -d
```


## Contribution

Contributions to the Open WebUI Starter project are welcome. If you'd like to 
contribute, please fork this repository and submit a pull request with any 
changes or additions.

