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
           --btf_encode_force "$_binary"
    sudo bpftool btf dump file "$_btf.btf" \
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

gen_make() {
    local _b _fb

    _fb="$1"
    _b=$(basename "$_fb")
    cat <<EOF
TARGET="trace_${_b}"
BINARY="$_fb"
ARCH=\$(shell uname -m | sed 's/x86_64/x86/' | sed 's/aarch64/arm64/')

BPF_OBJ=${TARGET:=.bpf.o}
USER_C =${TARGET:=.c}
USER_SKEL=${TARGET:=.skel.h}

all: ${TARGET}

${TARGET}: ${USER_C} ${USER_SKEL} libbpf bpftool
           \$(CC) -Wall -static -o ${TARGET} \
                 -I. ${USER_C} -L../../bpftool/src/libbpf \
                 -I../../bpftool/src/libbpf/include \
                 -lbpf -lelf -lz

%.bpf.o: %.bpf.c vmlinux.h
         clang -target bpf \
               -D__TARGET__ARCH_${ARCH} \
               -I../../bpftool/src/libbpf/include \
               -I. -Wall -O2 -g -o $@ -c $<

${USER_SKEL}: ${BPF_OBJ}
         ../../bpftool/src/bootstrap/bpftool gen skeleton $< >$@

vmlinux.h:
        ../../bpftool/src/bootstrap/bpftool btf dump file /sys/kernel/btf/vmlinux \
                                           format c >vmlinux.h

libbpf:
        make -C ../../bpftool/libbpf/src

bpftool:
        make -C ../../bpftool/src

clean:
        - \$RM ${BPF_OBJ} ${TARGET} ${USER_SKEL} vmlinux
EOF
}
trace_gen() {
    local _e _d _btf

    _e="$1"
    _d="$2"

    gen_dir "$_d"
    
    _btf=$(basename "$_e")
    (cd "$_d"/src; gen_make "$_e" >Makefile)
}

trace_gen "$binary" "$dir"
