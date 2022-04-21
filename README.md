# Git Server Docker
[![GitHub Workflow Status][4]][6]
[![Docker Image Size][5]][6]

This is a simple Docker image containing a Git server accessible via
SSH. (It can also contain Docker CLI, see [Variants](#variants))

- [Usage](#usage)
  * [Basic Use Case](#basic-use-case)
    + [Create a New Repository](#create-a-new-repository)
  * [Use a Custom Password](#use-a-custom-password)
- [Advanced configuration](#advanced-configuration)
  * [Use SSH public keys](#use-ssh-public-keys)
    + [Create Authorised Keys File](#create-authorised-keys-file)
    + [Allow Both SSH Public Key and Password](#allow-both-ssh-public-key-and-password)
  * [Custom SSH Host Keys](#custom-ssh-host-keys)
  * [Enable Git URLs Without Absolute Path](#enable-git-urls-without-absolute-path)
- [Variants](#variants)
- [License](#license)
- [Credit](#credit)


## Usage

### Basic Use Case

```shell
docker run --detach \
  --name rockstorm/git-server \
  --volume /path/to/your/repos:/srv/git \
  --publish 2222:22 \
  rockstorm/git-server
```

One volume is mounted which sets the path to where you git
repositories are stored. Your server should be accessible on port 2222
via:

```
git clone ssh://git@localhost:2222/srv/git/your-repo.git
```

The default password for the git user is `12345`. By default, the git
user is only allowed to clone, push and pull repositories.


#### Create a New Repository

On the host, run the following commands and restart the git server:

```
cd /path/to/your/repos
mkdir your-repo.git
cd your-repo.git
git init --bare
```


### Use a Custom Password

Every container generated by this image has the same default password
set for the git user. You can set your own password using the
`GIT_PASSWORD` variable.

```shell
docker run --detach \
  --name git-server \
  --volume /path/to/your/repos:/srv/git \
  --env GIT_PASSWORD=your-password \
  --publish 2222:22 \
  rockstorm/git-server
```

To avoid specifying your password on the command line or on your
compose file, you can load it from a file using the
`GIT_PASSWORD_FILE`. This variable must be set to the file within the
container to load the password from.

```shell
docker run --detach \
  --name git-server \
  --volume /path/to/your/repos:/srv/git \
  --volume /path/to/password/file:/run/secrets/git_password:ro \
  --env GIT_PASSWORD_FILE=/run/secrets/git_password \
  --publish 2222:22 \
  rockstorm/git-server
```

Or making use of Docker secrets on your docker-compose.yml file:

```yaml
services:
  git-server:
    ...
    environment:
      GIT_PASSWORD_FILE: /run/secrets/git_password
    secrets:
      - git_password
secrets:
  git_password:
    file: /path/to/password/file
```


## Advanced configuration

A [sample `docker-compose.yml`][1] is provided with all available
options to use with docker-compose.

[1]: https://github.com/rockstorm101/git-server-docker/blob/master/docker-compose.yml.sample

### Use SSH public keys

The most secure option is to disable clear text passwords completely
and only allow connections via SSH public keys.

First, Set to 'no' the following option on the [sample `sshd_config`][7]:

```
PasswordAuthentication no
```

Second, mount your custom `sshd_config`. Via docker-compose.yml is
done like:

```yaml
services:
  git-server:
    ...
    volumes:
      - ./sshd_config.sample:/etc/ssh/sshd_config:ro
```

Third, you need to mount the file with SSH authentication keys for
the users that will be allowed to interact with the server. These are
set in the docker-compose.yml file as:

```yaml
services:
  git-server:
    ...
    volumes:
      - /path/to/authorized_keys:/home/git/.ssh/authorized_keys:ro
```

[7]: https://github.com/rockstorm101/git-server-docker/blob/master/sshd_config.sample

#### Create Authorised Keys File

SSH key generation for your client machine to connect to the
server is detailed in depth on [Git's book Chapter 4.3][8].

Then simply copy the contents of all allowed clients' `id_*.pub` into
a file and mount it as detailed above.

[8]: https://git-scm.com/book/en/v2/Git-on-the-Server-Generating-Your-SSH-Public-Key

#### Allow Both SSH Public Key and Password

Add the following line to your `sshd_config` to allow either a public
key login _or_ a password login:

```
AuthenticationMethods publickey password
```


### Custom SSH Host Keys

The default host keys are generated during image build and are the
same for every container which uses this image. This is a security
risk and therefore the use of a custom set of keys is highly
recommended. This will also ensure keys are persistent if the image is
upgraded.

To enable custom SSH host keys set the `SSH_HOST_KEYS_PATH` variable
to a location such as `/tmp/host-keys` and mount a folder with your
custom keys on the server. The setup process will replace the default
keys with these ones. This would look like the following on your
docker-compose.yml file:

```yaml
services:
  git-server:
    ...
    environment:
      SSH_HOST_KEYS_PATH: /tmp/host-keys
    volumes:
      - /path/to/host-keys:/tmp/host-keys:ro
```


### Enable Git URLs Without Absolute Path

By default, git URLs to you repositories will be in the form of:

```
git clone ssh://git@example.com:2222/srv/git/project/repository.git
```

By setting the environment variable `REPOSITORIES_HOME_LINK` to
e.g. `/srv/git/project` a link will be created into the git user home
directory so that your git URLs don't require the repository absolute
path[^1]:

```
git clone ssh://git@example.com:2222/project/repository.git
```

To configure this on your docker-compose.yml file:

```yaml
services:
  git-server:
    ...
    environment:
      REPOSITORIES_HOME_LINK: /srv/git
```

To avoid specifying ports on git URLs you can configure your client
machine by adding the following to your `~/.ssh/config` file:

```
Host my-server
    HostName example.com
    User git
    Port 2222
```

This way your git URLs would look like:

```
git clone my-server:project/repository.git
```

## Variants

All images are based on the latest stable image of [Alpine Linux][9].

### `git-server:<version>`

Default image. It contains just git and SSH.

### `git-server:<version>-docker`

This image includes the Docker CLI. With this addition the git server
will be able to start other containers for things such as running
CI/CD actions. In this case you would need to expose the host's Docker
socket to your git server container[^2]. This would look like the
following on your docker-compose.yml file:

```yaml
services:
  git-server:
    ...
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
```

[9]: https://hub.docker.com/_/alpine

## License

View [license information][2] for the software contained in this
image.

As with all Docker images, these likely also contain other software
which may be under other licenses (such as Bash, etc from the base
distribution, along with any direct or indirect dependencies of the
primary software being contained).

As for any pre-built image usage, it is the image user's
responsibility to ensure that any use of this image complies with any
relevant licenses for all software contained within.

[2]: https://github.com/rockstorm101/git-server-docker/blob/master/LICENSE

## Credit

Re-implementation heavily based on [jkarlosb's][3] but coded from
scratch.

[^1]: More information and different options are discussed at
    https://stackoverflow.com/a/39841058.
[^2]: https://jpetazzo.github.io/2015/09/03/do-not-use-docker-in-docker-for-ci/#the-socket-solution

[3]: https://github.com/jkarlosb/git-server-docker
[4]: https://img.shields.io/github/workflow/status/rockstorm101/git-server-docker/Build%20Docker%20Images
[5]: https://img.shields.io/docker/image-size/rockstorm/git-server/latest
[6]: https://hub.docker.com/r/rockstorm/git-server
