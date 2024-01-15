TRAGET=trace_%BINARY%
BINARY=%FULL_PATH_BINARY%
ARCH=$(shell uname -m |sed 's/x86_64/x86/' | sed -e 's/aarch64/arm64/')

BPF_OBJ=$(TARGET:=.bpf.o)
USER_C=$(TARGET:=.c)
USER_SKEL=$(TARGET:=.skel.h)

all: $(TARGET)

$(TARGET): $(USER_C) $(USER_SKEL) libbpf bpftool
	$(CC) -Wall -static -o $(TARGET) \
		-I. $(USER_C) -L../../bpftool/src/libbpf \
		-I../../bpftool/src/libbpf/include \
		-lbpf -lelf -z

%.bpf.o: %.bpf.c vmlinux.h
	clang -target bpf \
		-D__TARGET__ARCH_$(ARCH) \
		-I../../bpftool/src/libbpf/include \
		-I. -Wall -O2 -g -o $@ -c $<

$(USER_SKEL): $(OBJ_OBJ)
	../../bpftool/src/bootstrap/bpftool gen skeleton $< >$@

vmlinux.h:
	../../bpftool/src/bootstrap/bpftool btf dump \
		file /sys/kernel/btf/vmlinux \
		format c >vmlinux.h

libbpf:
	make -C ../../bpftool/libbpf/src

bpftool:
	make -C ../../bpftool/src

clean:
	- $(RM) -Rf $(BPF_OBJ) $(TARGET) $(USER_SKEL) vmlinux
