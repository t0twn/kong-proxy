
#!/bin/bash
CURRENT_DIR=`dirname $0`
SCRIPT_NAME=`basename $0`
KONG_INITED="$CURRENT_DIR/kong_inited"
POSTGRES_PASSWORD="$CURRENT_DIR/POSTGRES_PASSWORD"
SUB_APP_DIR="app"


up(){
    app=$1
    cd $app && { test -f env.sh; source env.sh; }; docker compose -p kong up -d
}

down(){
    app=$1
    cd $app && docker compose -p kong down -d
}

init(){
    test -f $KONG_INITED && return

    test -f $POSTGRES_PASSWORD || uuidgen >$POSTGRES_PASSWORD

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
