
#!/bin/bash
CURRENT_DIR=`dirname $0`
SCRIPT_NAME=`basename $0`

PROJECT_NAME="kong"
KONG_INITED="$CURRENT_DIR/kong_inited"
POSTGRES_PASSWORD="$CURRENT_DIR/POSTGRES_PASSWORD"

COMPOSE_BASE="compose"
COMPOSE_HAPROXY="$COMPOSE_BASE/haproxy"
COMPOSE_KONG="$COMPOSE_BASE/kong"

REPO_BASE="https://github.com/t0twn"
APP_REPO="$REPO_BASE/kong-app"
HAP_REPO="$REPO_BASE/haproxy"
APP_ROOT="app"
HAP_ROOT="/etc/haproxy"

NETWORK_INTERFACE="kong"
NETWORK_GATEWAY="172.28.0.1"
NETWORK_SUBNET="172.28.0.0/16"

up(){
    app=$1
    cd $app && { test -f env.sh && source env.sh; }; docker compose -p $PROJECT_NAME up -d
}

down(){
    app=$1
    cd $app && { [ -f docker-compose.yaml -o -f docker-compose.yml ] && docker compose -p $PROJECT_NAME down;}
}

init(){

    init_network(){
        docker network inspect $NETWORK_INTERFACE >/dev/null 2>&1 || docker network create $NETWORK_INTERFACE --subnet=$NETWORK_SUBNET --gateway=$NETWORK_GATEWAY

    }

    init_app_haproxy(){
        test -d $HAP_ROOT || git clone $HAP_REPO $HAP_ROOT
        mkdir -p /etc/haproxy/map/ && touch /etc/haproxy/map/{301,backend}
        docker compose -p $PROJECT_NAME --project-directory $COMPOSE_HAPROXY up -d
    }

    init_network
    init_app_haproxy

    # when exactly kong
    test -f $KONG_INITED && return

    test -f $POSTGRES_PASSWORD || uuidgen >$POSTGRES_PASSWORD

    test -f env.sh && source env.sh || { echo env.sh not found. Please copy env.sh.sample to env.sh and customize it as needed.; exit 1;}

    docker compose --profile database -p $PROJECT_NAME --project-directory $COMPOSE_KONG up -d && touch $KONG_INITED
}

sync_app(){
    test -d $APP_ROOT && git -C $APP_ROOT pull || git clone $APP_REPO $APP_ROOT
}

echo_usage(){
    echo "Usage: $SCRIPT_NAME {up|down} <app>"
}

main(){

    init; sync_app; fun=$1; app=$2;

    test -n "$app" || { echo_usage; exit 0;}
    app="$APP_ROOT/$app" && test -d "$app" || { echo "App $app NOT found." >&2; exit 1;}

    case $fun in
        "up")
            up $app
            ;;
        "down")
            down $app
            ;;
        *)
            echo_usage
            ;;
    esac

}

main $@
