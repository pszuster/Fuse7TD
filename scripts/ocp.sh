#!/bin/sh
sudo iptables -F

h=$(hostname -s)
name=igniteworkshop
long=${#name}
num=${h:$long}

DOMAIN=rhtechofficelatam.com
igniteDomain=ignite$num.$DOMAIN
igniteHost=$name.$igniteDomain
profile=fuse7

echo y | oc-cluster destroy $profile
rm -rf /root/.oc

### Start OC
oc-cluster up $profile --public-hostname=$igniteHost --routing-suffix=apps.$igniteDomain

### OC Login
sleep 20s
echo y | oc login https://localhost:8443 --username=admin --password=admin --insecure-skip-tls-verify

oc delete project myproject
chcat -d /root/.oc/profiles/$profile/volumes/vol{01..10}

### IMPORT IMAGE STREAMS
oc create -f https://raw.githubusercontent.com/pszuster/Fuse7TD/master/install/fuse-ignite-image-streams.yml -n openshift

### Create Assets

### DB
#oc new-project db --display-name="Database"
#oc adm policy add-scc-to-user anyuid system:serviceaccount:db:default
#oc create -f https://raw.githubusercontent.com/pszuster/FIS2TD/master/templates/pgsql-db.json
#oc new-app --template=fis2td-db

### CI
#oc new-project ci --display-name="Continuous Integration"
#oc new-app -f https://raw.githubusercontent.com/pszuster/FIS2TD/master/templates/gogs.json --param=HOSTNAME=gogs.$igniteDomain
#oc new-app -f https://raw.githubusercontent.com/pszuster/FIS2TD/master/templates/nexus_v2.json --param=HOSTNAME_HTTP=nexus.$igniteDomain


### WebService
#oc new-project ws --display-name="WebService"
#oc new-app -f https://raw.githubusercontent.com/pszuster/FIS2TD/master/templates/webservice.json --param=HOSTNAME_HTTP=webservice.$igniteDomain


### FTP
oc new-project ftp --display-name="FTP Server"
oc adm policy add-scc-to-user anyuid system:serviceaccount:ftp:default
oc process -f https://raw.githubusercontent.com/pszuster/Fuse7TD/master/ftp/vsftpd-template.json --param=FTP_PASV_ADDR=$igniteHost | oc create -f -

### CRM
oc new-project opencrx --display-name="CRM"
oc adm policy add-scc-to-user anyuid system:serviceaccount:opencrx:default
oc process -f https://raw.githubusercontent.com/pszuster/Fuse7TD/master/crm/opencrx-template.json --param=OpenCRX_URL=opencrx.$igniteDomain | oc create -f -

