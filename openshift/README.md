# terraform-aws-openshift

## install : 1 master
```
ssh -i /c/work/nalbam/keys/_key_pairs/nalbam-seoul.pem ec2-user@52.78.55.113

curl -s toast.sh/install-v3 | bash
sudo ~/toaster/openshift/install.sh
```

## reference
* https://blog.openshift.com/installing-openshift-3-7-1-30-minutes/
* https://github.com/dwmkerr/terraform-aws-openshift
