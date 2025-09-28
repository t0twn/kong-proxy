#!/bin/bash
#===============================================================
#  Script Name : cert-dump.sh
#  Description : Dump all kong certs with keys combined auto
#                issued by ACME plugin for external use.
#  Author      : t0twn
#  Version     : 1.0
#  Created     : 2025-09-29
#  Updated     : 2025-09-29
#  Usage       : ./cert-dump.sh 
#===============================================================
KONG_ADDR=https://localhost:8444
CERT_DIR=/etc/kong/acme/
CERT_DIR_MODE=700


mk_dirs(){
    test -d $CERT_DIR || mkdir -p -m $CERT_DIR_MODE $CERT_DIR 
}

get_snis(){
    snis=`curl -k ${KONG_ADDR}/snis | jq '.data[] | .name' -r`
    echo $snis
}

get_raw_certs(){
    raw_certs=`curl -k ${KONG_ADDR}/certificates`
    echo $raw_certs
}

cert_dump(){
    snis=`get_snis`
    raw_certs=`get_raw_certs`
    for sni in $snis;do
        full_crt_dir=${CERT_DIR}${sni}
        full_crt_file=${full_crt_dir}/full.crt
        full_crt_content=`echo "$raw_certs" | jq ".data[] | select(.snis[] == \"$sni\") | .[\"cert\"], .[\"key\"]" -r`
        if [ -n "$full_crt_content" ];then
            test -d $full_crt_dir || mkdir -m $CERT_DIR_MODE $full_crt_dir
            echo "$full_crt_content" > $full_crt_file
        fi
    done
}

main(){
    mk_dirs
    cert_dump
}

main
#<<<END
