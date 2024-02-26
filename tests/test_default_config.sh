#!/bin/sh

beforeAll() {
    REPO_ROOT_DIR="."
    DEFAULT_GIT_PASSWORD="12345"
	FIXTURES=$(mktemp -d -t 'git-server_testXXXXXX')

    sed 's|image: rockstorm/git-server|build: . |' "${REPO_ROOT_DIR}/examples/docker-compose.yml" >"${FIXTURES}/compose.default.yml"

    docker compose -f "${FIXTURES}/compose.default.yml" --project-directory "$REPO_ROOT_DIR" \
        up --build --wait git-server

    mkdir -p ~/.ssh/ && touch ~/.ssh/known_hosts
    ssh-keyscan '127.0.0.1' -p 2222

    echo "echo $DEFAULT_GIT_PASSWORD" >"${FIXTURES}/git-askpass"
    chmod +x "${FIXTURES}/git-askpass"
}

afterAll() {
    docker compose -f "${FIXTURES}/compose.default.yml" down
}


#
# TEST CASES
#

test_clone() {
    sshpass -p "$DEFAULT_GIT_PASSWORD" ssh -vvv git@127.0.0.1 -p 2222 'git-init --bare -b dev /srv/git/repo.git'


    GIT_ASKPASS="${FIXTURES}/git-askpass" git clone -v ssh://git@127.0.0.1:2222/srv/git/repo.git

    test -d repo.git
}
