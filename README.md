# toaster

### Install
```
sudo yum install -y git

git clone https://github.com/yanolja/toaster.git

~/toaster/toast auto dev demo
```

### AWS User data
```
#!/bin/bash

yum install -y git

runuser -l ec2-user -c 'git clone https://github.com/yanolja/toaster.git'

runuser -l ec2-user -c 'cp ~/toaster/package/toast.txt ~/.toast'

runuser -l ec2-user -c 'echo "PHASE=dev" >> ~/.toast'
runuser -l ec2-user -c 'echo "FLEET=demo" >> ~/.toast'

runuser -l ec2-user -c '~/toaster/toast auto'
```

```
cat /var/log/cloud-init-output.log
```

### Deploy
```
~/toaster/toast deploy fleet
~/toaster/toast deploy project com.yanolja yanolja.api 0.0.0 war
~/toaster/toast deploy project com.yanolja yanolja.web 0.0.0 php web.yanolja.com
```

### Remote
```
~/toaster/remote user ip port auto
~/toaster/remote user ip port init java8
~/toaster/remote user ip port deploy fleet
```
