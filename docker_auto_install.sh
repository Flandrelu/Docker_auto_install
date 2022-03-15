#!/bin/bash

check_network(){
  echo "[info]  checking network..."
  newwork_result=`ping -c 3 www.baidu.com >/dev/null 2>&1;echo $?`
  if (( $newwork_result == 0 ))
  then
      echo "        network is ok!"
  else
      echo "        can not connect to internet!"
      exit
  fi
}

check_os_version(){
  echo "[info]  checking os and os version..."
  os_result=`cat /etc/redhat-release|grep -i centos >/dev/null 2>&1;echo $?`
  if (( $os_result == 0 ))
  then
      os_version_result=`cat /etc/redhat-release |grep -iE "release 7|release 8" >/dev/null 2>&1;echo $?`
      if (( $os_version_result != 0 ))
      then
          echo "        operating system version is too low!"
          exit
      else
          echo "        operating system is ok!"
      fi
  else
      echo "        operating system is not CentOS!"
      exit
  fi
}

remove_old_docker(){
  echo "[info]  removeing old version docker..."
  sudo yum remove docker \
                 docker-client \
                 docker-client-latest \
                 docker-common \
                 docker-latest \
                 docker-latest-logrotate \
                 docker-logrotate \
                 docker-engine >/dev/null 2>&1
}

install_plugin(){
  echo "[info]  installing the must plugin..."
  sudo yum install -y yum-utils -y >/dev/null 2>&1
}

init_docker_software_repo(){
  echo "[info]  initing the docker software repo... "
  docker_software_repo=`cat docker_software_repo`
  sudo yum-config-manager --add-repo $docker_software_repo >/dev/null 2>&1
}

init_docker_image_repo(){
  echo "[info]  initing the docker image repo..."
  docker_image_repo=`cat docker_images_repo`
  cat << EOF >>/etc/docker/daemon.json
{
"registry-mirror": ["$docker_image_repo"]
}
EOF
}

version_list(){
  yum list --showduplicates|grep docker-ce|sort -r|awk '{print$2}'|awk -F "-" '{print$1}'|grep -v ":"|awk -F ".ce" '{print$1}' >>version.list
  yum list --showduplicates|grep docker-ce|sort -r|awk '{print$2}'|awk -F "-" '{print$1}'|grep ":"|awk -F ":" '{print$2}'|awk -F ".ce" '{print$1}' >>version.list
  echo "[info]  all versions list..."
  cat version.list
}


docker_version_check(){
  echo "[info]  checking the docker version..."
  docker_version_check_result=`yum list --showduplicates |grep $docker_version|sort -r |head -n1 >/dev/null 2>&1;echo $?`
  if (( $docker_version_check_result != 0 ))
  then
      echo "        this version is not in the software source warehouse!"
      exit
  else
      echo "        docker is ready to install!"
  fi
}

install_docker(){
  echo "[info]  installing docker $docker_version..."
  sudo yum install docker-ce-$docker_version docker-ce-cli-$docker_version containerd.io -y >/dev/null 2>&1
}

start_docker(){
  if (( $1 == 1 ))
  then
      echo "[info]  starting docker..."
      systemctl start docker && systemctl enable docker >/dev/null 2>&1
  elif (( $1 == 2 ))
  then
      echo "[info]  restarting docker..."
      systemctl restart docker
  else 
      exit
  fi
}

main(){
  echo "[info]  environment check is in progress, please wait..."
  check_network
  check_os_version
  init_docker_software_repo
  version_list
  read -p "[input] please input the docker version you want to install:  " docker_version
  remove_old_docker
  install_plugin
  docker_version_check
  install_docker
  start_docker 1
  init_docker_image_repo
  start_docker 2
  >version.list
}

main
