#!/bin/bash

rm anykernel/*.dtb && rm anykernel/Image*
rm build.log
clear

# Kernels
echo -e "$cyan Pilih kernel yang ingin dikompilasi: $normal"
echo -e "1) Trinket"
echo -e "2) A7K"
echo -e "3) MSM8937"
read -p "Masukkan pilihan (1/2/3): " choice

case $choice in
    1)
        cd trinket
        ;;
    2)
        cd a7k
        ;;
    3)
        cd msm8937
        ;;
esac

# Configuration
DEFCONFIG="vendor/xf_defconfig"
zipname="trinket.xf.zip"
TC_DIR="$(pwd)/../sdclang"
KERNEL_OUT="out"
ANYKERNEL_DIR="$(pwd)/../anykernel"


# SetEnv

export USE_CCACHE=1
export CCACHE_DIR=~/.ccache
export PATH="$TC_DIR/bin:$PATH"
export KBUILD_BUILD_USER="huza"
export KBUILD_BUILD_HOST="archlinux"
mkdir -p "$KERNEL_OUT"

# Compile
make O="$KERNEL_OUT" ARCH=arm64 "$DEFCONFIG"
make -j$(nproc --all) O="$KERNEL_OUT" ARCH=arm64 CC="ccache clang" LD=ld.lld \
    CROSS_COMPILE=aarch64-linux-gnu- \
    CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
    2>&1 | tee ../build.log

# Check and zipping
if [[ -f out/arch/arm64/boot/Image.gz-dtb ]] && [[ -f out/arch/arm64/boot/dtbo.img ]]; then
    COMPILE_END=$(date +"%s")
    COMPILE_TIME=$((COMPILE_END - COMPILE_START))
    echo -e "$green Build selesai dalam $((COMPILE_TIME / 60)) menit $((COMPILE_TIME % 60)) detik.$normal"
    echo -e "$yellow Mengemas kernel ke dalam ZIP...$normal"
    cp out/arch/arm64/boot/Image.gz-dtb ../anykernel/
    cp out/arch/arm64/boot/dtbo.img ../anykernel/
    cd ../anykernel/ && zip -r9 $zipname * && cd -
    echo -e "$green Kernel berhasil dikemas: $zipname$normal"
else
    echo -e "$red Build gagal!$normal"
fi
