# toaster

### Install
```
curl -s toast.sh/install | bash

~/toaster/toast.sh auto {fleet} {phase} {org}
```

### AWS User data
```
#!/bin/bash

runuser -l ec2-user -c 'curl -s toast.sh/install | bash'

runuser -l ec2-user -c '~/toaster/toast.sh auto {fleet} {phase} {org}'
```

```
cat /var/log/cloud-init-output.log
```

### Deploy
```
~/toaster/toast.sh auto
~/toaster/toast.sh init httpd
~/toaster/toast.sh init java
~/toaster/toast.sh deploy fleet
~/toaster/toast.sh deploy project com.yanolja yanolja.api 0.0.0 war
~/toaster/toast.sh deploy project com.yanolja yanolja.web 0.0.0 php web.yanolja.com
```

### Remote
```
~/toaster/remote.sh user ip port auto
~/toaster/remote.sh user ip port init httpd
~/toaster/remote.sh user ip port init java
~/toaster/remote.sh user ip port deploy fleet
~/toaster/remote.sh user ip port deploy project com.yanolja yanolja.api 0.0.0 war
~/toaster/remote.sh user ip port deploy project com.yanolja yanolja.web 0.0.0 php web.yanolja.com
```
