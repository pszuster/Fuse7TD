#!/bin/sh

h=$(hostname -s)
name=igniteworkshop
long=${#name}
num=${h:$long}

DOMAIN=rhtechofficelatam.com
igniteDomain=ignite$num.$DOMAIN
igniteHost=$name.$igniteDomain


## IGNITE
oc new-project ignite --display-name="Fuse Ignite"
oc create -f https://raw.githubusercontent.com/pszuster/Fuse7TD/master/install/serviceaccount-as-oauthclient-restricted.yml -n ignite
oc create -f https://raw.githubusercontent.com/pszuster/Fuse7TD/master/install/fuse-ignite-ocp.yml -n ignite

var=$(oc sa get-token syndesis-oauth-client -n ignite)
echo $var
oc new-app --template "fuse-ignite" --param=ROUTE_HOSTNAME=fuse-ignite.$igniteDomain --param=OPENSHIFT_PROJECT=ignite --param=OPENSHIFT_OAUTH_CLIENT_SECRET=$var --param=IMAGE_STREAM_NAMESPACE=openshift


