# toaster

### Install
```
curl -sL toast.sh/install | bash

~/toaster/toast.sh auto {fleet} {phase} {org} {token}
```

### AWS User data
```
#!/bin/bash

runuser -l {user} -c 'curl -sL toast.sh/install | bash'

runuser -l {user} -c '~/toaster/toast.sh auto {fleet} {phase} {org} {token}'
```

```
cat /var/log/cloud-init-output.log
```

### Usage
```
~/toaster/toast.sh auto
~/toaster/toast.sh init java
~/toaster/toast.sh deploy fleet
~/toaster/toast.sh deploy target {target}
~/toaster/toast.sh bucket {target}
```

### Remote
```
~/toaster/remote.sh {user} {host} {port} auto
~/toaster/remote.sh {user} {host} {port} init java
~/toaster/remote.sh {user} {host} {port} deploy fleet
~/toaster/remote.sh {user} {host} {port} deploy target {target}
~/toaster/remote.sh {user} {host} {port} bucket {target}
```
