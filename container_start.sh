#!/bin/bash

docker-compose up -d

docker cp ~/.ssh/id_ed25519 my-app-dev:/usr/src/app/.ssh/

docker-compose exec app bash -c '
    eval "$(ssh-agent)"
    ssh-add .ssh/id_ed25519
    ssh -T git@github.com
    expect -c "expect yes {send yes}"
    bash
'
