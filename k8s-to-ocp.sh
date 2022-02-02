#!/usr/bin/env bash


echo "=================================================================="
echo "This will convert the rundemo.sh file from kubectl to oc commands." 
echo "=================================================================="
echo " "
read -p "Hit CTRL-C to escape, press ENTER to continue... " -n1

# change all kubectl to oc
sed -i 's/kubectl/oc/g' rundemo.sh
# fix cordon commands to "oc adm"
sed -i 's/oc cordon/oc adm cordon/g' rundemo.sh
sed -i 's/oc uncordon/oc adm uncordon/g' rundemo.sh

echo ""
echo "==============================="
echo "Patching rundemo.sh is complete" 
echo "==============================="
