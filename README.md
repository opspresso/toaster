# toaster

### Install
```
curl -s toast.sh/install | bash

~/toaster/toast.sh auto {fleet} {phase} {org} {token}
```

### AWS User data
```
#!/bin/bash

runuser -l ec2-user -c 'curl -s toast.sh/install | bash'

runuser -l ec2-user -c '~/toaster/toast.sh auto {fleet} {phase} {org} {token}'
```

```
cat /var/log/cloud-init-output.log
```

### toast.sh
```
~/toaster/toast.sh auto
~/toaster/toast.sh init java
~/toaster/toast.sh deploy fleet
~/toaster/toast.sh deploy target ${no}
```

### remote.sh
```
~/toaster/remote.sh user ip port auto
~/toaster/remote.sh user ip port init java
~/toaster/remote.sh user ip port deploy fleet
~/toaster/remote.sh user ip port deploy target ${no}
```
