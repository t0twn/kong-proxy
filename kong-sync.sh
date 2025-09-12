#!/bin/bash
CURRENT_DIR=`dirname $0`

TMP_DIR=$CURRENT_DIR/.tmp
ENV_CFG=$CURRENT_DIR/env

SSL_CFG=$CURRENT_DIR/kong-sync.yml
KONG_CFG=$CURRENT_DIR/kong-sync-cfg.yml
KONG_ADDR=https://localhost:8444

DECK_VERSION=1.44.0


deck_inst(){
    which deck >/dev/null 2>&1 && return

    deck_tar_gz=${TMP_DIR}/deck.tar.gz
    curl -sL https://github.com/kong/deck/releases/download/v${DECK_VERSION}/deck_${DECK_VERSION}_linux_amd64.tar.gz -o $deck_tar_gz
    tar xf $deck_tar_gz -C ${TMP_DIR}
    mv ${TMP_DIR}/deck /usr/local/bin
}

deck_sync(){
    deck gateway sync --tls-skip-verify --kong-addr $KONG_ADDR $KONG_CFG
}

read_env(){
    test -f $ENV_CFG && { source $ENV_CFG && return 0; } || return 1
}

copy_cfg(){
    cp $SSL_CFG $KONG_CFG
}

parser(){
    if [ -n $KONG_ADMIN_GUI_URL ];then
        WEB_DOMAIN=`echo ${KONG_ADMIN_GUI_URL%.} | cut -d/ -f3-` && API_DOMAIN=api.$WEB_DOMAIN
        ROOT_DOMAIN=`echo $WEB_DOMAIN | awk -F. '{print $(NF-1)"."$NF}'`
        return 0
    fi
    return 1
}

render(){
    copy_cfg && read_env && { parser || return; }
    # acme account
    sed -i "s|account_email: x@.*|account_email: x@$ROOT_DOMAIN|" $KONG_CFG
    # acme allow
    sed -i "s|*.kong-manager.|*.$ROOT_DOMAIN|" $KONG_CFG
    # api sni
    sed -i "s|api.kong-manager.|$API_DOMAIN|" $KONG_CFG
    # api cor
    sed -i "s|https://kong-manager.|$KONG_ADMIN_GUI_URL|" $KONG_CFG
    # web sni
    sed -i "s|- kong-manager.|- $WEB_DOMAIN|" $KONG_CFG 
}

main(){
    render
    deck_inst
    deck_sync
}

main
