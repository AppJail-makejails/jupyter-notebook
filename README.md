# Jupyter

**Project Jupyter** is a project to develop open-source software, open standards, and services for interactive computing across multiple programming languages.

wikipedia.org/wiki/Project_Jupyter

<img src="https://upload.wikimedia.org/wikipedia/commons/thumb/3/38/Jupyter_logo.svg/1200px-Jupyter_logo.svg.png" alt="jupyter logo" width="30%" height="auto">

## How to use this Makejail

### Standalone

```sh
appjail makejail \
    -j jupyter \
    -f gh+AppJail-makejails/jupyter-notebook \
    -o virtualnet=":<random> default" \
    -o nat
appjail start jupyter
```

### Deploy using appjail-director

**appjail-director.yml**:

```yaml
options:
  - virtualnet: ':<random> default'
  - nat:

services:
  jupyter:
    name: jupyter
    makejail: gh+AppJail-makejails/jupyter-notebook
    options:
      - expose: 8888
    volumes:
      - home: jupyter-home
    start-environment:
      - JUPYTER_CMD: 'notebook'

default_volume_type: '<volumefs>'

volumes:
  home:
    device: .volumes/jupyter-home
```

**.env**:

```
DIRECTOR_PROJECT=jupyter
```

### Arguments (stage: build)

* `jupyter_tag` (default: `13.3`): see [#tags](#tags).

### Environment (stage: start)

* `JUPYTER_CMD` (default: `lab`): Jupyter subcommand (e.g.: `notebook`).
* `JUPYTER_ARGS` (default: `--ip=0.0.0.0 --port=8888`): Jupyter subcommand's arguments.

### Check current status

The custom stage `jupyter_status` can be used to run `top(1)` to check the status of Jupyter.

```sh
appjail run -s jupyter_status jupyter
```

### Log

To view the log generated by the application, run the custom stage `jupyter_log`.

```sh
appjail run -s jupyter_log jupyter
```

### Volumes

| Name         | Owner | Group | Perm | Type | Mountpoint     |
| ------------ | ----- | ----- | ---- | ---- | -------------- |
| jupyter-home | 1001  | 1001  |  -   |  -   | /jupyter/home  |

## Tags

| Tag    | Arch    | Version        | Type   |
| ------ | ------- | -------------- | ------ |
| `13.3` | `amd64` | `13.3-RELEASE` | `thin` |
| `14.1` | `amd64` | `14.1-RELEASE` | `thin` |

## Notes

1. If you want to install extensions through the web interface, install `devel/py-pip`.
