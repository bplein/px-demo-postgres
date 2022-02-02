#!/usr/bin/env bash


echo "=================================================================="
echo "This will convert the rundemo.sh file from oc commands to kubectl." 
echo "=================================================================="
echo " "
read -p "Hit CTRL-C to escape, press ENTER to continue... " -n1

# change all kubectl to oc
sed -i 's/oc/kubectl/g' rundemo.sh
# fix cordon commands to "oc adm"
sed -i 's/kubectl adm cordon/kubectl cordon/g' rundemo.sh
sed -i 's/kubectl adm uncordon/kubectl uncordon/g' rundemo.sh

echo ""
echo "==============================="
echo "Patching rundemo.sh is complete" 
echo "==============================="
