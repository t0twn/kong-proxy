
#!/bin/bash
CURRENT_DIR=`dirname $0`
SCRIPT_NAME=`basename $0`
KONG_INITED="$CURRENT_DIR/kong_inited"
POSTGRES_PASSWORD="$CURRENT_DIR/POSTGRES_PASSWORD"
SUB_APP_DIR="app"

DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
CLI_PLUGINS_DIR="$DOCKER_CONFIG/cli-plugins"
DOCKER_COMPOSE="$CLI_PLUGINS_DIR/docker-compose"
COMPOSE_URL="https://github.com/docker/compose/releases/latest/download/docker-compose-linux-`uname -m`"


up(){
    app=$1
    cd $app && { test -f env.sh && source env.sh; }; docker compose -p kong up -d
}

down(){
    app=$1
    cd $app && { test -f docker-compose.yaml && docker compose -p kong -f docker-compose.yaml down || docker compose -p kong -f docker-compose.yml down;}
}

init(){

    test -f $KONG_INITED && return

    test -f $POSTGRES_PASSWORD || uuidgen >$POSTGRES_PASSWORD

    test -f env.sh && source env.sh || { echo env.sh not found. Please copy env.sh.sample to env.sh and customize it as needed.; exit 1;}

    test -f $DOCKER_COMPOSE || { mkdir -p $CLI_PLUGINS_DIR && curl -SL $COMPOSE_URL -o $DOCKER_COMPOSE && chmod +x $DOCKER_COMPOSE;}

    mkdir -p /etc/haproxy/map/ && \
    touch /etc/haproxy/map/{301,backend} && \
    cp haproxy.cfg /etc/haproxy/haproxy.cfg && \
    docker compose --profile database up -d && touch $KONG_INITED
}


main(){

    init; fun=$1; app=$2;

    test -n $app && { test -d $app || { test -d $SUB_APP_DIR/$app && app=$SUB_APP_DIR/$app; } || { echo "App $app NOT found." >&2; exit 1;} }

    case $fun in
        "up")
            up $app
            ;;
        "down")
            down $app
            ;;
        *)
            echo "Usage: $SCRIPT_NAME {up|down} app"
            ;;
    esac

}

main $@
