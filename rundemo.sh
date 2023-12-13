#!/usr/bin/env bash

clear
if ! command -v pv &> /dev/null
then
    echo ""
    echo "PV could not be found, attempting to install it"
    echo ""
    bash ./install-pv.sh
    echo ""
    echo "Please run the demo again"
    exit
fi
source ./util.sh
desc "Let's get a little bit of data to put into the system"
desc "What is your first name?"
read firstname
desc "What is your favorite color?"
read favoritecolor
desc "What is your favorite sport?"
read favoritesport
desc "Thank you! Not lets get started!\n\n"
namespace=postgres-demo
desc ""
desc "First lets create a namespace to run our application and switch context to it"
run "kubectl create ns ${namespace}"

desc ""
desc "Let's check out the pods running portworx"
run "kubectl -n portworx get pods -l name=portworx -o wide"

desc ""
desc "Now create a storage class for our application."
desc "Storage classes allow Kubernetes to tell the underlying volume driver how to set up the volumes for capabilites such as IO profiles, HA levels, etc."
run "cat px-repl3-sc-demotemp.yaml"
run "kubectl create -f px-repl3-sc-demotemp.yaml"

desc ""
desc "Now create a volume for the application."

run "cat px-postgres-pvc.yaml"
run "kubectl -n ${namespace} apply -f px-postgres-pvc.yaml"

echo -n postgres123 > password.txt
kubectl -n ${namespace} create secret generic postgres-pass --from-file=password.txt 2>&1 >/dev/null


desc ""
desc "And now we'll take a look at the application in YAML format and deploy it (hit CTRL-C to stop watching the application when it's up)"
run "cat postgres-app.yaml"
run "kubectl -n ${namespace} create -f postgres-app.yaml"
watch kubectl -n ${namespace} get pods -l app=postgres -o wide

#clear the screen
clear

desc ""
desc "Now we'll run a Portworx command to see what the Portworx cluster reveals about the volume"
desc "The syntax for this command is pxctl volume inspect VOL."
VOL=$(kubectl -n ${namespace} get pvc | grep px-postgres-pvc | awk '{print $3}')
#VOL
PX_POD=$(kubectl -n ${namespace} get pods -l name=portworx -n portworx -o jsonpath='{.items[0].metadata.name}')
#PX_POD
echo "$green pxctl volume inspect $VOL $reset"

kubectl -n ${namespace} exec -i "$PX_POD" -n portworx -c portworx -- /opt/pwx/bin/pxctl volume inspect "${VOL}"

run ""
desc ""
desc "We are going to exec into the Postgres pod and run a command to populate data, and then query the data"
run "kubectl -n ${namespace} get pods -l app=postgres"
POD=$(kubectl -n ${namespace} get pods -l app=postgres | grep Running | grep 1/1 | awk '{print $1}')
#POD
desc "Our pod is called $POD"
desc ""
desc "Create the database"
run "kubectl -n ${namespace} exec -i $POD -- psql << EOF
create database pxdemo;
\l
\q
EOF"

desc ""
desc "Populate the database with test data"
run "kubectl -n ${namespace} exec -i $POD -- psql pxdemo<< EOF
CREATE TABLE visitor_log (firstname text, favoritecolor text, favoritesport text, created_at timestamptz DEFAULT Now());
INSERT INTO visitor_log (firstname, favoritecolor, favoritesport) VALUES ('${firstname}', '${favoritecolor}', '${favoritesport}');
\q
EOF"

desc ""
desc "Query the table to see our new record"
run "kubectl -n ${namespace} exec -i $POD -- psql pxdemo<< EOF
SELECT * from visitor_log;
\q
EOF"

desc ""
desc "Now that we have your data in the database, lets simulate a node failucre"
desc "We will cordon the Kubernetes node, and kill the application, which will have to start on another node"
NODE=$(kubectl -n ${namespace} get pods -l app=postgres -o wide | grep -v NAME | awk '{print $7}')
run "kubectl -n ${namespace} get pods -l app=postgres -o wide"
run "kubectl cordon ${NODE}"

POD=$(kubectl -n ${namespace} get pods -l app=postgres -o wide | grep -v NAME | awk '{print $1}')
run "kubectl -n ${namespace} delete pod ${POD} --grace-period=0 --force"
watch kubectl -n ${namespace} get pods -l app=postgres -o wide

desc ""
desc "And let's uncordon that node so apps can run there again"
run "kubectl uncordon ${NODE}"

#clear the screen
clear

desc ""
desc "What just happened? We created a database, add your data to it, and simulated a node failure"
desc "Within seconds, it was running again on a second replica of the data on another node"
desc " "
desc "So lets validate the data"
desc " "
run "kubectl -n ${namespace} get pods -l app=postgres"

##########
# get data
##########
desc ""
desc "Let's query from the database table"

POD=$(kubectl -n ${namespace} get pods -l app=postgres | grep Running | grep 1/1 | awk '{print $1}')
#POD
run "kubectl -n ${namespace} exec -i $POD -- psql pxdemo<< EOF
SELECT * from visitor_log;
\q
EOF"
##########

#clear the screen
clear

desc ""
desc "Now let's simulate an app failure due to lack of disk space"
desc "We'll add a new table with 5 million records to the database."
desc ""
desc "After we will run further database record creation until we fill up the volume"

desc "Populate the database with 5M rows of data"
run "kubectl -n ${namespace} exec -i $POD -- pgbench -i -s 50 pxdemo;"

desc ""
desc "Get a count of the records"
run "kubectl -n ${namespace} exec -i $POD -- psql pxdemo<< EOF
select count(*) from pgbench_accounts;
\q
EOF"
desc "Attempt to populate the database with 10M rows of data"
run "kubectl -n ${namespace} exec -i $POD -- pgbench -c 10 -j 2 -t 10000 pxdemo"

desc ""
desc "The application crashed, citing lack of space. Let's fix that by patching the volume to a larger size, all from Kubernetes"
run "diff px-postgres-pvc.yaml px-postgres-pvc-larger.yaml"
run "kubectl -n ${namespace} apply -f px-postgres-pvc-larger.yaml"
sleep 3
run "watch kubectl -n ${namespace} get pvc px-postgres-pvc"
desc "And let's watch the pod come up"
run "watch kubectl -n ${namespace} get pods"

desc ""
desc "What just happened? We extended the size of the volume."
desc "Within seconds, the pod was running again with more space for data"
desc " "
desc "So now we can validate the data"
run "kubectl -n ${namespace} get pods -l app=postgres"

desc ""

##########
# get count
##########
desc ""
desc "Let's get the count from the database table"

POD=$(kubectl -n ${namespace} get pods -l app=postgres | grep Running | grep 1/1 | awk '{print $1}')
#POD
run "kubectl -n ${namespace} exec -i $POD -- psql pxdemo<< EOF
select count(*) from pgbench_accounts;
\q
EOF"
##########


##########
# get data
##########
desc ""
desc "Let's query from the database visitor_logs table"

POD=$(kubectl -n ${namespace} get pods -l app=postgres | grep Running | grep 1/1 | awk '{print $1}')
#POD
run "kubectl -n ${namespace} exec -i $POD -- psql pxdemo<< EOF
SELECT * from visitor_log;
\q
EOF"
##########


#clear the screen
clear

desc ""
desc "Now let's simulate data loss due to human error, with recovery from a snapshot"
desc ""
desc "First lets create a snapshot class as required by Kubernetes."
run "cat px-snapclass.yaml"
run "kubectl -n ${namespace} create -f px-snapclass.yaml"
desc ""
desc "Take an adhoc snapshot from kubectl:"

desc "First lets create a snapshot class as required by Kubernetes."
run "cat px-snap.yaml"
run "kubectl -n ${namespace} create -f px-snap.yaml"
run "kubectl -n ${namespace} get VolumeSnapshot,VolumeSnapshotContents"

desc ""
desc "Now we're going to go ahead and do something stupid because we're here to learn."
desc ""

run "kubectl -n ${namespace} get pods -l app=postgres"
POD=$(kubectl -n ${namespace} get pods -l app=postgres | grep Running | grep 1/1 | awk '{print $1}')
#POD
run "kubectl -n ${namespace} exec -i $POD -- psql << EOF
drop database pxdemo;
\l
\q
EOF"

desc ""
desc "Ok, so we deleted our database, what now? Restore your snapshot and carry on."
desc ""
desc "In this demo, we will clone the snapshot to a new PVC, and launch a new copy of the app with the restored data"
desc ""
desc "Here is the code to create the clone"

run "cat px-snap-pvc.yaml"
run "kubectl -n ${namespace} create -f px-snap-pvc.yaml"
run "kubectl -n ${namespace} get pvc"

desc ""
desc "Here is the postgres app pointing to that newly restored volume"
run "cat postgres-app-restore.yaml"
run "kubectl -n ${namespace} create -f postgres-app-restore.yaml"

desc "Let's watch it come up, hit CTRL-C when it's up"
run "watch kubectl -n ${namespace} get pods -l app=postgres-snap -o wide"

desc "Finally, let's validate that we have our data, again!"
##########
# get count
##########
desc ""
desc "Let's get the count from the database table"

POD=$(kubectl -n ${namespace} get pods -l app=postgres-snap | grep Running | grep 1/1 | awk '{print $1}')
#POD
run "kubectl -n ${namespace} exec -i $POD -- psql pxdemo<< EOF
select count(*) from pgbench_accounts;
SELECT * from visitor_log;
\q
EOF"
##########

desc "The demo is complete! We have demonstrated recovery from failed nodes/pods, recovery from running out of capacity, and recovering of data from a snapshot after human error"

