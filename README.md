# Project Jupyter

Project Jupyter is a project to develop open-source software, open standards, and services for interactive computing across multiple programming languages.

wikipedia.org/wiki/Project_Jupyter

<img src="https://upload.wikimedia.org/wikipedia/commons/thumb/3/38/Jupyter_logo.svg/500px-Jupyter_logo.svg.png" width="30%" height="auto" alt="Project Jupyter logo">

## How to use this Makejail

### Jupyter

A container launched from this OCI image runs a Jupyter Server with the JupyterLab frontend. The container does so by executing a `start-notebook.py` script. This script configures the internal container environment and then runs `jupyter lab`, passing any command-line arguments received.

#### Jupyter Server Options

You can pass [Jupyter Server options](https://jupyter-server.readthedocs.io/en/latest/operators/public-server.html) to the `start-notebook.py` script when launching the container.

1. For example, to secure the Jupyter Server with a [custom password](https://jupyter-server.readthedocs.io/en/latest/operators/public-server.html#preparing-a-hashed-password) hashed using `jupyter_server.auth.passwd()` instead of the default token, you can run the following (this hash was generated for the `my-password` password):

   ```console
   $ appjail oci run -Pd \
       -o overwrite=force \
       -o virtualnet=":<random> default" \
       -o nat \
       ghcr.io/appjail-makejails/jupyter-notebook jupyter \
       --PasswordIdentityProvider.hashed_password='argon2:$argon2id$v=19$m=10240,t=10,p=8$JdAN3fe9J45NvK/EPuGCvA$O/tbxglbwRpOFuBNTYrymAEH6370Q2z+eS1eF4GM6Do'
   ```
2. To set the [base URL](https://jupyter-server.readthedocs.io/en/latest/operators/public-server.html#running-the-notebook-with-a-customized-url-prefix) of the Jupyter Server, you can run the following:

   ```console
   $ appjail oci run -Pd \
       -o overwrite=force \
       -o virtualnet=":<random> default" \
       -o nat \
       ghcr.io/appjail-makejails/jupyter-notebook jupyter \
       --ServerApp.base_url=/customized/url/prefix/
   ```

#### Additional runtime configurations

* `-e GEN_CERT=yes` - Instructs the startup script to generate a self-signed SSL certificate. Configures Jupyter Server to use it to accept encrypted HTTPS connections.
* `-e JUPYTER_CMD=<jupyter command>` - Instructs the startup script to run `jupyter ${JUPYTER_CMD}` instead of the default `jupyter lab` command. See [Switching back to the classic notebook or using a different startup command](#switching-back-to-the-classic-notebook-or-using-a-different-startup-command) for available options. This setting is helpful in container orchestration environments where setting environment variables is more straightforward than changing command line parameters.
* `-o fstab="/some/host/folder/for/work /noroot"` - Mounts a host machine directory as a folder in the container. This configuration is useful for preserving notebooks and other work even after the container has been destroyed. 
* `-e NOTEBOOK_ARGS="--log-level='DEBUG' --dev-mode"` - Adds custom options to the jupyter command. This way, the user could use any option supported by the `jupyter` subcommand.
* `-e JUPYTER_PORT=8117` - Changes the port in the container that Jupyter is using to the value of the `${JUPYTER_PORT}` environment variable. This may be useful if you run multiple instances of Jupyter in swarm mode and want to use a different port for each instance.

#### Switching back to the classic notebook or using a different startup command

JupyterLab, built on top of Jupyter Server, is the default in this image. However, switching back to the classic notebook or using a different startup command is possible. You can achieve this by setting the environment variable `JUPYTER_CMD` at container startup.

| `JUPYTER_CMD` | Frontend |
| --- | --- |
| `lab` (default) | JupyterLab |
| `notebook` | Jupyter Notebook |
| `nbclassic` | NbClassic |
| `server` | None |

**Example**:

```console
$ # Run Jupyter Server with the Jupyter Notebook frontend
$ appjail oci run -Pd \
    -o overwrite=force \
    -o virtualnet=":<random> default" \
    -o nat \
    -o expose=8888 \
    -e JUPYTER_CMD="notebook" \
    ghcr.io/appjail-makejails/jupyter-notebook jupyter
$ # Use Jupyter NBClassic frontend
$ appjail oci run -Pd \
    -o overwrite=force \
    -o virtualnet=":<random> default" \
    -o nat \
    -o expose=8888 \
    -e JUPYTER_CMD="nbclassic" \
    ghcr.io/appjail-makejails/jupyter-notebook jupyter
```

#### Entrypoint

The entrypoint script runs the `start-notebook.py` script by default, but there's nothing stopping you from calling, for example, `ipython`.

```console
$ appjail oci run \
    -o ephemeral \
    -o overwrite=force \
    -o virtualnet=":<random> default" \
    -o nat \
    ghcr.io/appjail-makejails/jupyter-notebook ipython \
    ipython && 
  appjail stop ipython
```

You can further customize the container environment by adding shell scripts (`*.sh`) to be sourced or executables (`chmod +x`) by placing them in `/entrypoint.d`.

### JupyterHub

The default OCI image spawns a Jupyter instance, which may be enough for many users. However, this image also includes JupyterHub, although additional configuration is required. The easiest way to set up JupyterHub is to use PAM as the authentication method (which is the default) and [LocalProcessSpawner](https://jupyterhub.readthedocs.io/en/latest/explanation/concepts.html#spawner) as the process spawner, but this requires creating users within the jail.

First, we need to obtain a configuration file for JupyterHub.

```console
$ appjail oci run \
    -o ephemeral \
    -o overwrite=force \
    ghcr.io/appjail-makejails/jupyter-notebook jupyterhub-config \
    sh -c "jupyterhub --generate-config -y=true -f /tmp/jupyterhub_config.py > /dev/null && cat /tmp/jupyterhub_config.py" > jupyterhub_config.py && 
  appjail stop jupyterhub-config
$ $EDITOR jupyterhub_config.py
$ grep -Ee '^c\.Authenticator\.allowed_users =' jupyterhub_config.py
c.Authenticator.allowed_users = {"jupyter"}
```

Second, let's create our `Containerfile(5)` with our custom configuration and a custom user with an encrypted password. Remember to edit your `jupyterhub_config.py` file to allow access for our custom user/s and to have JupyterHub listen on `0.0.0.0` instead of `127.0.0.1`.

```dockerfile
FROM ghcr.io/appjail-makejails/jupyter-notebook

# Users
#
# Equivalent to 'jupyter' but encrypted using 'openssl passwd -6 "your_password"':
#
ARG JUPYTER_PASSWORD='$6$hR8F1kt5x47WjPzE$zbNYZjEgWAeyhECwNbZt0s.Utt9JhGuSoBAk4QZxakHFSK3bIyKvjgT6M/kAGKGqTy93y.Blh9B05uDVz8Pif0'

RUN umask 0022; \
    \
    echo "${JUPYTER_PASSWORD}" | \
        pw useradd -m -H 0 -n jupyter

# Required by JupyterHub
RUN { \
        echo -e "#!/bin/sh"; \
        echo -e "if ! grep -Ee '^127.0.0.1\s+\$(hostname)' /etc/hosts; then printf \"127.0.0.1\\\t%s\\\n\" \"\$(hostname)\" >> /etc/hosts; fi"; \
    } > /entrypoint.d/10-add-hostname; \
    \
    chmod +x /entrypoint.d/10-add-hostname

# Configuration
RUN mkdir -p /usr/local/etc/jupyterhub
COPY jupyterhub_config.py /usr/local/etc/jupyterhub

# Data directory
RUN mkdir -p /var/db/jupyterhub
WORKDIR /var/db/jupyterhub

# Our custom command. Don't use ENTRYPOINT since the base image already defines one.
CMD ["jupyterhub", "-f", "/usr/local/etc/jupyterhub/jupyterhub_config.py"]
```

Then build the image with `buildah build --network=host -t my-jupyterhub .` and run it as follows:

```console
$ appjail oci run -Pd \
    -o overwrite=force \
    -o virtualnet=":<random> default" \
    -o nat \
    -o expose=8000 \
    localhost/my-jupyterhub jupyterhub
```

### Arguments (stage: build)

* `jupyter_from` (default: `ghcr.io/appjail-makejails/jupyter-notebook`): Location of OCI image. See also [OCI Configuration](#oci-configuration).
* `jupyter_tag` (default: `latest`): OCI image tag. See also [OCI Configuration](#oci-configuration).

### Environment (OCI image)

* `PGID` (default: `1000`): Equivalent to `PUID` but for the Process Group ID.
* `PUID` (default: `1000`): Process User ID for the container's main process, allowing you to match the owner of files written to mounted host volumes to your host system's user. Writable volumes are changed based on this environment variable.

## OCI Configuration

```yaml
build:
  variants:
    - tag: 15.1
      containerfile: Containerfile
      aliases: ["latest"]
      default: true
      args:
        FREEBSD_RELEASE: "15.1"
        PYVER: "312"
        NO_PKGCLEAN: "1"
      cache_dirs:
        - "pkgcache0:/var/cache/pkg"
        - "pip:/.cache/pip"
        - "npm:/.npm"
        - "cargo:/.cargo"
```
