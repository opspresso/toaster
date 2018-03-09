# terraform-aws-openshift

## install : 1 master
```
ssh -i keys/_key_pairs/nalbam-seoul.pem ec2-user@13.125.230.122
 
curl -s toast.sh/install-v3 | bash
sudo ~/toaster/openshift/install.sh
```

## install : 1 bastion, 1 master, 2 node
```
export bastion_ip="13.125.153.54"
 
scp -i keys/_key_pairs/nalbam-seoul.pem keys/_key_pairs/nalbam-seoul.pem ec2-user@${bastion_ip}:~/.ssh/id_rsa
ssh -i keys/_key_pairs/nalbam-seoul.pem ec2-user@${bastion_ip} -t 'curl -s toast.sh/install-v3 | bash'
ssh -i keys/_key_pairs/nalbam-seoul.pem ec2-user@${bastion_ip} -t '~/toaster/openshift/install-bastion.sh'
```

## reference
* https://blog.openshift.com/installing-openshift-3-7-1-30-minutes/
* https://github.com/dwmkerr/terraform-aws-openshift
