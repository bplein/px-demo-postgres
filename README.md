# px-demo-postgres
 
This is a basic demo of Portworx, using Postgres as an application in order to exercise local replicas for availability, to demonstrate growing volumes on a live application, and to demonstrate recovery from data loss or corruption through the use of snapshots and clones. 

Note: Uses `util.sh` which is code from early versions of Kubernetes, used purely for demonstration purposes. This code requires "pipe-viewer" aka `pv`, which you need to install on the system running the scripts. This script does not run well from macOS, due to different arguments used by one or more commands.
