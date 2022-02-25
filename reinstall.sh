#!/bin/bash
# https://github.com/keiko233
# https://t.me/keiko233

DATADIR="/etc/ProxmoxSH"
IMAGESDIR="/images"

DEBIAN10IMAGE="/debian-10.qcow2"
DEBIAN11IMAGE="/debian-11.qcow2"
UBUNTU18IMAGE="/ubuntu-18-04.qcow2"
UBUNTU20IMAGE="/ubuntu-20-04.qcow2"
CENTOS7IMAGE="/centos-7.qcow2c"

PVESTORANGE="local"

showMenu() {
  clear

  echo -e "

  ------------ \033[34mProxmox VE 管理小脚本\033[0m ------------
  
  * \033[31mkeiko's Github\033[0m:    \033[32mhttps://github.com/keiko233\033[0m
  * \033[31mTelegram Channel\033[0m:  \033[32mhttps://t.me/keiko_gugu\033[0m
  * \033[31mkeiko's Website\033[0m:   \033[32mhttps://majokeiko.com\033[0m

  ------------------ \033[34m操作选项\033[0m -------------------

  1. \033[32m新建 KVM VM\033[0m
  2. \033[32m重建 KVM VM 系统\033[0m

  3. \033[32m更改 KVM VM 硬件设置\033[0m \033[31m[施工中]\033[0m
  4. \033[32m更改 Cloud-Init 设置\033[0m \033[31m[施工中]\033[0m

  0. \033[32m一键获取系统镜像模板\033[0m

  -----------------------------------------------
  "

  echo -e -n "  # \033[32m请输入选项\033[0m [0-13]: "

  read num
  case ${num} in
  1)
    CreateVM
    ;;
  2)
    ReinstallVM
    ;;
  0)
    DownloadTemplateImages
    ;;
  *)
    echo
    echo -e "  # \033[31m输入有误，请按回车键回到主菜单\033[0m"
    read
    showMenu
    ;;
  esac
}

CreateVM() {
  clear

  echo
  echo -e "  ----------------- \033[34m新建 KVM VM\033[0m -----------------"

  echo -e "
  1. \033[32mCentOS 7\033[0m
  2. \033[32mCentOS 8\033[0m

  3. \033[32mDebian 10\033[0m
  4. \033[32mDebian 11\033[0m

  5. \033[32mUbuntu 18.04 LTS\033[0m
  6. \033[32mUbuntu 20.04 LTS\033[0m
  "

  echo -e -n "  # \033[32m请输入新建 VM 的操作系统\033[0m: "
  read installosid

  if [ "$installosid" = "1" ]; then
    INSTALLOSDIR=${DATADIR}${IMAGESDIR}${CENTOS7IMAGE}
  elif [ "$installosid" = "2" ]; then
    echo
    echo -e "  # \033[31m还有人敢在生产环境用 CentOS 8\033[0m ?"
    echo -e "  # \033[32m请按回车键回到创建 VM 菜单\033[0m"
    read
    CreateVM
  elif [ "$installosid" = "3" ]; then
    INSTALLOSDIR=${DATADIR}${IMAGESDIR}${DEBIAN10IMAGE}
  elif [ "$installosid" = "4" ]; then
    INSTALLOSDIR=${DATADIR}${IMAGESDIR}${DEBIAN11IMAGE}
  elif [ "$installosid" = "5" ]; then
    INSTALLOSDIR=${DATADIR}${IMAGESDIR}${UBUNTU18IMAGE}
  elif [ "$installosid" = "6" ]; then
    INSTALLOSDIR=${DATADIR}${IMAGESDIR}${UBUNTU20IMAGE}
  else
    echo
    echo -e "  # \033[31m输入不符合要求，请按回车键回到创建 VM 菜单\033[0m"
    read
    CreateVM
  fi

  echo -e -n "  # \033[32m请输入新建的 VMID (不可以重复)\033[0m: "
  read vmid

  echo -e -n "  # \033[32m请输入新建 VM 的名字 (不可以使用中文)\033[0m: "
  read vmname

  echo -e -n "  # \033[32m请输入新建 VM 的 CPU 核心数\033[0m: "
  read vmcpucore

  echo -e -n "  # \033[32m请输入新建 VM 的内存大小 (单位 MB)\033[0m: "
  read vmmem

  echo -e -n "  # \033[32m请输入新建 VM 的硬盘增加容量 (单位 GB)\033[0m: "
  read vmdisk

  echo -e -n "  # \033[32m请输入新建 VM 使用的网桥 (不知道请填写 vmbr0)\033[0m: "
  read vmnetworkbridge

  echo -e -n "  # \033[32m请输入新建 VM 网卡的限速设置 (单位 MB/s)\033[0m: "
  read vmnetworkrate

  clear
  echo -e "  -------------- \033[34m确认 KVM VM 的信息\033[0m -------------"
  echo -e "
  \033[32m  VMID\033[0m:               ${vmid}
  \033[32m  VM 名字\033[0m:            ${vmname}
  \033[32m  VM 操作系统\033[0m:        ${INSTALLOSDIR}
  \033[32m  VM CPU Core\033[0m:        ${vmcpucore}
  \033[32m  VM CPU 内存\033[0m:        ${vmmem}
  \033[32m  VM 硬盘增加容量\033[0m:    ${vmdisk}
  \033[32m  VM Network Bridge\033[0m:  ${vmnetworkbridge}
  \033[32m  VM Network Rate\033[0m:    ${vmnetworkrate}
  "

  echo -e -n "  # \033[31m确认无误后按回车键开始创建\033[0m"
  read

  ehco
  echo -e "  # \033[32m开始创建\033[0m"

  echo -e "  # \033[32m创建 VM\033[0m"
  qm create ${vmid} --name ${vmname} --cores ${vmcpucore} --memory ${vmmem} --net0 virtio,bridge=${vmnetworkbridge},rate=${vmnetworkrate}
  echo -e "  # \033[32m导入磁盘\033[0m"
  qm importdisk ${vmid} ${INSTALLOSDIR} ${PVESTORANGE} --format qcow2
  echo -e "  # \033[32m挂载磁盘\033[0m"
  qm set ${vmid} --virtio0 ${PVESTORANGE}:${vmid}/vm-${vmid}-disk-0.qcow2
  echo -e "  # \033[32m扩容启动磁盘\033[0m"
  qm resize ${vmid} virtio0 ${vmdisk}
  echo -e "  # \033[32m添加 Cloud-Init CDROM 驱动器\033[0m"
  qm set ${vmid} --ide2 ${PVESTORANGE}:cloudinit
  echo -e "  # \033[32m设置启动磁盘\033[0m"
  qm set ${vmid} --boot c --bootdisk virtio0
  echo -e "  # \033[32m启用 Xterm.js\033[0m"
  qm set ${vmid} -serial0 socket
  echo -e "  # \033[32m启动虚拟机\033[0m"
  qm start ${vmid}

  ehco
  echo -e "  # \033[32m完成创建，请按回车键回到主菜单\033[0m"
  read
  showMenu
}

ReinstallVM() {
  clear

  echo
  echo -e "  --------------- \033[34m重建 KVM VM 系统\033[0m --------------\n"

  qm list
  echo

  echo -e "  -----------------------------------------------\n"
  echo -e -n "  # \033[32m请输入需要重装小鸡的 VMID\033[0m: "
  read vmid

  echo -e "
  1. \033[32mCentOS 7\033[0m
  2. \033[32mCentOS 8\033[0m

  3. \033[32mDebian 10\033[0m
  4. \033[32mDebian 11\033[0m

  5. \033[32mUbuntu 18.04 LTS\033[0m
  6. \033[32mUbuntu 20.04 LTS\033[0m
  "

  echo -e -n "  # \033[32m请输入需要重装小鸡的系统\033[0m: "
  read installosid

  if [ "$installosid" = "1" ]; then
    INSTALLOSDIR=${DATADIR}${IMAGESDIR}${CENTOS7IMAGE}
  elif [ "$installosid" = "2" ]; then
    echo
    echo -e "  # \033[31m还有人敢在生产环境用 CentOS 8\033[0m ?"
    echo -e "  # \033[32m请按回车键回到主菜单\033[0m"
    read
    showMenu
  elif [ "$installosid" = "3" ]; then
    INSTALLOSDIR=${DATADIR}${IMAGESDIR}${DEBIAN10IMAGE}
  elif [ "$installosid" = "4" ]; then
    INSTALLOSDIR=${DATADIR}${IMAGESDIR}${DEBIAN11IMAGE}
  elif [ "$installosid" = "5" ]; then
    INSTALLOSDIR=${DATADIR}${IMAGESDIR}${UBUNTU18IMAGE}
  elif [ "$installosid" = "6" ]; then
    INSTALLOSDIR=${DATADIR}${IMAGESDIR}${UBUNTU20IMAGE}
  else
    echo
    echo -e "  # \033[31m输入不符合要求，请按回车键回到主菜单\033[0m"
    read
    showMenu
  fi

  echo
  echo -e "  # \033[32m开始重装\033[0m"

  echo -e "  # \033[32m关闭虚拟机\033[0m"
  qm stop ${vmid}
  echo -e "  # \033[32m移除磁盘\033[0m"
  qm unlink ${vmid} --force --idlist virtio0
  echo -e "  # \033[32m导入磁盘\033[0m"
  qm importdisk ${vmid} ${INSTALLOSDIR} ${PVESTORANGE} --format qcow2
  echo -e "  # \033[32m挂载磁盘\033[0m"
  qm set ${vmid} --virtio0 ${PVESTORANGE}:${vmid}/vm-${vmid}-disk-0.qcow2
  echo -e "  # \033[32m设置启动磁盘\033[0m"
  qm set ${vmid} --boot c --bootdisk virtio0

  # qm set ${vmid} -serial0 socket
  echo -e "  # \033[32m启动虚拟机\033[0m"
  qm start ${vmid}

  echo
  echo -e "  # \033[32m重装完成，请按回车键回到主菜单\033[0m"
  read
  showMenu
}

DownloadTemplateImages() {
  clear

  apt install -y wget
  mkdir ${DATADIR}
  mkdir ${DATADIR}${IMAGESDIR}
  echo -e "  # \033[32m开始下载 Debian 10 镜像\033[0m"
  wget -nv https://cloud.debian.org/images/cloud/buster/latest/debian-10-generic-amd64.qcow2 -O ${DATADIR}${IMAGESDIR}${DEBIAN10IMAGE}
  echo -e "  # \033[32m开始下载 Debian 11 镜像\033[0m"
  wget -nv https://cloud.debian.org/images/cloud/bullseye/latest/debian-11-generic-amd64.qcow2 -O ${DATADIR}${IMAGESDIR}${DEBIAN11IMAGE}
  echo -e "  # \033[32m开始下载 CentOS 7 镜像\033[0m"
  wget -nv https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud-2111.qcow2c -O ${DATADIR}${IMAGESDIR}${CENTOS7IMAGE}
  echo -e "  # \033[32m开始下载 Ubuntu 18.04 LTS 镜像\033[0m"
  wget -nv https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img -O ${DATADIR}${IMAGESDIR}${UBUNTU18IMAGE}
  echo -e "  # \033[32m开始下载 Ubuntu 20.04 LTS 镜像\033[0m"
  wget -nv https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img -O ${DATADIR}${IMAGESDIR}${UBUNTU20IMAGE}
  echo
  echo -e "  # \033[32m下载镜像完成，请按回车键回到主菜单\033[0m"
  read
  showMenu
}

showMenu
