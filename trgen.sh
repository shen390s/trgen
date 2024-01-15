#!/bin/sh

binary="$1"
dir="$2"

if [ -z "$binary" ]; then
    echo "Usage: $0 binary_file_with_debug_info [generate_dir]"
    exit 1
fi

extract_btf() {
    local _binary _btf

    _binary="$1"
    _btf="$2"
    
    pahole --btf_encode_detached "$_btf.btf" \
           --btf_enocde_force "$_binary"
    sudo btftool btf dump file "$_btf.btf" \
         format c >"$_btf.h"
}

gen_dir() {
    local _d

    _d="$1"
    
    if [ ! -d "$_d" ]; then
        mkdir -p "$_d"
    else
        rm -Rf "$_d"/*
    fi

    (cd $_d; git clone --recursive https://github.com/libbpf/bpftool)
    mkdir -p "$_d"/src
}

trace_gen() {
    local _e _d

    _e="$1"
    _d="$2"

    gen_dir "$_d"
    
    (cd "$_d"/src; extract_btf "$_e" "$_e")
}

trace_gen "$binary" "$dir"
