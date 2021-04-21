#!/bin/bash  
AMQ_USER_NAMES="howard,gao"
AMQ_USER_PASSWORDS="bXlwYXNzd29yZA==,Z2FvcGFzc3dvcmQ="
AMQ_ROLES="role1,role2;role3,role4"

IFS=';' #setting comma as delimiter  
read -a rolearr <<< "${AMQ_ROLES}"
IFS=','
read -a usrarr <<< "${AMQ_USER_NAMES}"
read -a pwdarr <<< "${AMQ_USER_PASSWORDS}"

for i in "${!usrarr[@]}"
do
  echo "user $i : ${usrarr[$i]}"
  echo "password $i : ${pwdarr[$i]}"
  decodedPwd=$(base64 --decode <<< "${pwdarr[$i]}")
  echo "decoded pwd: ${decodedPwd}"
  echo "roles for ${usrarr[$i]}: ${rolearr[$i]}"
done

