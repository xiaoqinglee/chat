#!/usr/bin/env bash


# Copyright © 2023 OpenIM open source community. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#Include shell font styles and some basic information
SCRIPTS_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
OPENIM_ROOT=$(dirname "${SCRIPTS_ROOT}")/..

source $OPENIM_ROOT/scripts/style_info.sh
source $OPENIM_ROOT/scripts/path_info.sh
source $OPENIM_ROOT/scripts/function.sh

list1=$(cat $config_path | grep openImPushPort | awk -F '[:]' '{print $NF}')
list2=$(cat $config_path | grep pushPrometheusPort | awk -F '[:]' '{print $NF}')
list_to_string $list1
rpc_ports=($ports_array)
list_to_string $list2
prome_ports=($ports_array)

#Check if the service exists
#If it is exists,kill this process
check=$(ps | grep -w ./${push_name} | grep -v grep | wc -l)
if [ $check -ge 1 ]; then
  oldPid=$(ps | grep -w ./${push_name} | grep -v grep | awk '{print $2}')
  kill -9 $oldPid
fi
#Waiting port recycling
sleep 1
cd ${push_binary_root}

for ((i = 0; i < ${#rpc_ports[@]}; i++)); do
  nohup ./${push_name} -port ${rpc_ports[$i]} -prometheus_port ${prome_ports[$i]} >>../logs/openim_$(date '+%Y%m%d').log 2>&1 &
done

sleep 3
#Check launched service process
check=$(ps | grep -w ./${push_name} | grep -v grep | wc -l)
if [ $check -ge 1 ]; then
  newPid=$(ps | grep -w ./${push_name} | grep -v grep | awk '{print $2}')
  ports=$(netstat -netulp | grep -w ${newPid} | awk '{print $4}' | awk -F '[:]' '{print $NF}')
  allPorts=""

  for i in $ports; do
    allPorts=${allPorts}"$i "
  done
  echo -e ${SKY_BLUE_PREFIX}"SERVICE START SUCCESS "${COLOR_SUFFIX}
  echo -e ${SKY_BLUE_PREFIX}"SERVICE_NAME: "${COLOR_SUFFIX}${YELLOW_PREFIX}${push_name}${COLOR_SUFFIX}
  echo -e ${SKY_BLUE_PREFIX}"PID: "${COLOR_SUFFIX}${YELLOW_PREFIX}${newPid}${COLOR_SUFFIX}
  echo -e ${SKY_BLUE_PREFIX}"LISTENING_PORT: "${COLOR_SUFFIX}${YELLOW_PREFIX}${allPorts}${COLOR_SUFFIX}
else
  echo -e ${YELLOW_PREFIX}${push_name}${COLOR_SUFFIX}${RED_PREFIX}"SERVICE START ERROR, PLEASE CHECK openim_$(date '+%Y%m%d').log"${COLOR_SUFFIX}
fi
