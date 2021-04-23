#!/bin/bash

function processUsers() {
  echo "processing user ${_user} and password ${_password}"
  userExists="false"
  for idx in ${!actualUserLines[@]}; do
    OLDIFS=$IFS
    IFS='='; read -a thisuserarr <<< "${actualUserLines[$idx]}"
    IFS=$OLDIFS
    thisuser=${thisuserarr[0]//[[:blank:]]}
    if [[ ${_user} == "${thisuser}" ]]; then
      echo "the user exists, update its password"
      actualUserLines[$idx]="${_user} = ${_password}"
      userExists="true"
      break;
    fi
  done
  if [[ $userExists == "false" ]]; then
    echo "new user, appending"
    newuserline="${_user} = ${_password}"
    actualUserLines+=($newuserline)
  fi
}

function processRoles() {
  echo "processing roles ${_roles} for user ${_user}"
  for nr in ${_roles[@]}; do
    role_exist="false"
    for idx in ${!actualRoleLines[@]}; do
      OLDIFS=$IFS
      IFS='='; read -a thisrolearr <<< "${actualRoleLines[$idx]}"
      IFS=$OLDIFS
      thisrole=${thisrolearr[0]//[[:blank:]]}
      if [[ $nr == "${thisrole}" ]]; then
        echo "The role exists, appending"
        OLDIFS=$IFS
        IFS=','; read -a thisroleuserarr <<< "${thisrolearr[1]}"
        IFS=$OLDIFS
        userExistInRole="false"
        for thisuser in ${thisroleuserarr[@]}; do
          if [[ $_user == "${thisuser//[[:blank:]]/}" ]]; then
            userExistInRole="true"
            break
          fi
        done
        if [[ $userExistInRole == "true" ]]; then
          echo "This user $_user already in this role, ignore"
        else
          actualRoleLines[$idx]+=",$_user"
        fi
        role_exist="true"
      fi
    done
    if [[ $role_exist == "false" ]]; then
      newRoleLine="${nr} = ${_user}"
      actualRoleLines+=(${newRoleLine})
    fi
  done
}

AMQ_ROLES="amq,role2,admin;viewer,role4;amq,role5"
AMQ_USER_NAMES="howard1,gao,howard"
AMQ_USER_PASSWORDS="bXlwYXNzd29yZA==,Z2FvcGFzc3dvcmQ=,Z2FvcGFzc3dvcmQ="

userFileName="./users.properties"
roleFileName="./roles.properties"

tempRoleFileName="${roleFileName}.tmp"
tempUserFileName="${userFileName}.tmp"

actualUserLines=()
actualRoleLines=()

rm -rf ${tempUserFileName}
rm -rf ${tempRoleFileName}

echo "=======IFS is |${IFS}|"
ORIGINALIFS=${IFS}
while IFS= read -r line; do
  echo "Read a line: |${line}|"
  if [[ $line != \#* && $line != "" ]] ; then
    actualUserLines+=("$line")
  else
    echo $line >> $tempUserFileName
  fi
done < $userFileName

while IFS= read -r line; do
  if [[ $line != \#* && $line != "" ]] ; then
    actualRoleLines+=("$line")
  else
    echo $line >> $tempRoleFileName
  fi
done < $roleFileName

IFS=';'
read -a rolearr <<< "${AMQ_ROLES}"
IFS=','
read -a usrarr <<< "${AMQ_USER_NAMES}"
read -a pwdarr <<< "${AMQ_USER_PASSWORDS}"

for i in "${!usrarr[@]}"
do
  _user=${usrarr[$i]}
  _password=$(base64 --decode <<< "${pwdarr[$i]}")
  _roles=${rolearr[$i]}
  processUsers
  #printf "\n%s=%s" $_user $_password >> ${userFileName}
  # roles entry format is role=user1,user2...
  processRoles
done

IFS=$(echo -en "\n\b")
echo "writing roles..."
for t in ${actualRoleLines[@]}; do
  echo "$t" >> "${tempRoleFileName}"
done
echo "writing users..."
for u in ${actualUserLines[@]}; do
  echo "$u" >> "${tempUserFileName}"
done
IFS=${ORIGINALIFS}
rm ${userFileName} ${roleFileName}
mv ${tempUserFileName} ${userFileName}
mv ${tempRoleFileName} ${roleFileName}
