#!/bin/bash
rm build.log

clear
# Pilih kernel yang ingin dikompilasi
echo -e "$cyan Pilih kernel yang ingin dikompilasi: $normal"
echo -e "1) Trinket"
echo -e "2) A7K"
echo -e "3) MSM8937"
read -p "Masukkan pilihan (1/2/3): " choice

case $choice in
    1)
        cd trinket_xf
        ;;
    2)
        cd a7k_xf
        ;;
    3)
        cd msm8937_xf
        ;;
esac

# Konfigurasi
DEFCONFIG="vendor/xf_defconfig"
ZIPNAME="trinket.xf.zip"
TC_DIR="$(pwd)/../sdclang"
KERNEL_OUT="out"
ANYKERNEL_DIR="$(pwd)/../anykernel"


# Setup lingkungan

export USE_CCACHE=1
export CCACHE_DIR=~/.ccache
ccache -M 25G #ccache size
export PATH="$TC_DIR/bin:$PATH"
export KBUILD_BUILD_USER="huza"
export KBUILD_BUILD_HOST="archlinux"
mkdir -p "$KERNEL_OUT"

# Kompilasi Kernel
make O="$KERNEL_OUT" ARCH=arm64 "$DEFCONFIG"
make -j$(nproc --all) O="$KERNEL_OUT" ARCH=arm64 CC="ccache clang" LD=ld.lld \
    CROSS_COMPILE=aarch64-linux-gnu- \
    CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
    2>&1 | tee ../build.log

# Cek hasil build dan zip
if [[ -f out/arch/arm64/boot/Image.gz-dtb ]] && [[ -f out/arch/arm64/boot/dtbo.img ]]; then
    COMPILE_END=$(date +"%s")
    COMPILE_TIME=$((COMPILE_END - COMPILE_START))
    echo -e "$green Build selesai dalam $((COMPILE_TIME / 60)) menit $((COMPILE_TIME % 60)) detik.$normal"
    echo -e "$yellow Mengemas kernel ke dalam ZIP...$normal"
    cp out/arch/arm64/boot/Image.gz-dtb ../anykernel/
    cp out/arch/arm64/boot/dtbo.img ../anykernel/
    cd ../anykernel/ && zip -r9 $zipname * && mv $zipname "$OLDPWD" && cd -
    echo -e "$green Kernel berhasil dikemas: $zipname$normal"
else
    echo -e "$red Build gagal!$normal"
fi