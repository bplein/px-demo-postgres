# px-demo-postgres
 
This is a basic demo of Portworx, using Postgres as an application in order to exercise local replicas for availability, to demonstrate growing volumes on a live application, and to demonstrate recovery from data loss or corruption through the use of snapshots and clones. 

Note: Uses `util.sh` which is code from early versions of Kubernetes, used purely for demonstration purposes. This code requires "pipe-viewer" aka `pv`, which you need to install on the system running the scripts. This script does not run well from macOS, due to different arguments used by one or more commands.

This demo is intended to be run on a system with Portworx Enterprise installed on the worker nodes.

To Run: run `./rundemo.sh`. You must hit `return` to make it step through the demo. 

To cleanup: run `cleanup.sh`. Note, this is DESTRUCTIVE to everything in the namespace defined in `rundemo.sh` I might make this safer later.

Set DEMO_AUTO_RUN to not require hitting `ENTER` to step through the demo.
Set DEMO_RUN_FAST to run it at a faster pace. 
See `util.sh` for how these are used. 
