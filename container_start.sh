#!/bin/bash

docker-compose up -d

docker cp ~/.ssh/id_ed25519 my-app-dev:/usr/src/app/.ssh/

docker-compose exec app bash -c '
    eval "$(ssh-agent)"
    ssh-add .ssh/id_ed25519
    expect -c "
        spawn ssh -T git@github.com
        expect \"Are you sure you want to continue\" { send yes }
    "
    bash
'
