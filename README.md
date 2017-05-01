# toaster

[![Build Status](https://travis-ci.org/nalbam-ya/toaster.svg?branch=master)](https://travis-ci.org/nalbam-ya/toaster) 

### Install
```
curl -s toast.sh/install | bash

~/toaster/toast.sh auto {fleet} {phase} {org} {token}
```

### AWS User data
```
#!/bin/bash

runuser -l {user} -c 'curl -s toast.sh/install | bash'

runuser -l {user} -c '~/toaster/toast.sh auto {fleet} {phase} {org} {token}'
```

```
cat /var/log/cloud-init-output.log
```

### toast.sh
```
~/toaster/toast.sh auto
~/toaster/toast.sh init java
~/toaster/toast.sh deploy fleet
~/toaster/toast.sh deploy target {target}
~/toaster/toast.sh deploy bucket {target}
```

### remote.sh
```
~/toaster/remote.sh {user} {host} {port} auto
~/toaster/remote.sh {user} {host} {port} init java
~/toaster/remote.sh {user} {host} {port} deploy fleet
~/toaster/remote.sh {user} {host} {port} deploy target {target}
```
