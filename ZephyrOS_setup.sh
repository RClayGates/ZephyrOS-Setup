#!/usr/bin/bash

# const/globals
target_dir=$@
if [ -d $target_dir ];then
    echo $target_dir is valid
else
    echo $target_dir is not valid
    exit 1
fi


# main
main() {
    echo =============
    echo Program Start
    echo =============
    standard_update
    install_dependancies
    verify_versions
    venv_setup $target_dir
    zephyr_setup $target_dir
    zephyr_sdk_udev
}

# code blocks
standard_update() {
    echo ===============
    echo Standard Update
    echo ===============
    apt update && apt -y upgrade
}

install_dependancies() {
    echo ====================
    echo Install Dependancies
    echo ====================
    apt -y install \
    git \
    cmake \
    ninja-build \
    gperf \
    ccache \
    dfu-util \
    device-tree-compiler \
    wget \
    python3-dev \
    python3.10-venv \
    python3-pip \
    python3-setuptools \
    python3-tk \
    python3-wheel \
    xz-utils \
    file \
    make \
    gcc \
    gcc-multilib \
    g++-multilib \
    libsdl2-dev \
    libmagic1
}

verify_versions() {
    echo ===============
    echo Verify Versions
    echo ===============
    cmake --version
    dtc --version
    python3 --version
}

venv_setup() {
    echo ==========
    echo Venv Setup
    echo ==========
    echo Param = $1
    python3 -m venv $1/.venv
    if [ -f $1/.venv/bin/activate ];then
        # Unsure why Source doesn't play well but "." does
        . $1/.venv/bin/activate
    else 
        echo $1/.venv/bin/activate not found
        exit 1
    fi
    pip install west
}

zephyr_setup() {
    echo ============
    echo Zephyr Setup
    echo ============  
    echo Param = $1
    if [ -d $1/zephyr ];then
        echo west init already performed
    else
        west init $1
    fi
    cd $1
    west update
    west zephyr-export
    if [ -f ./zephyr/scripts/requirements.txt ];then
        pip install -r ./zephyr/scripts/requirements.txt
    else
        echo requirements.txt not found
        exit 1
    fi
}

zephyr_sdk_udev() {
    cd /opt
    wget https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.4/zephyr-sdk-0.16.4_linux-x86_64.tar.xz
    wget -O - https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.4/sha256.sum | shasum --check --ignore-missing
    tar xvf zephyr-sdk-0.16.4_linux-x86_64.tar.xz
    cd zephyr-sdk-0.16.4
    ./setup.sh
    cp ./sysroots/x86_64-pokysdk-linux/usr/share/openocd/contrib/60-openocd.rules /etc/udev/rules.d
    udevadm control --reload
}


main