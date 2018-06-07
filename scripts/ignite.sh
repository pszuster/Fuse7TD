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

sleep 30s

## Create extensions

listaJars="syndesis-extensions-master/syndesis-connector-datashape/target/syndesis-connector-datashape-1.0.0.jar syndesis-extensions-master/syndesis-extension-split/target/syndesis-extension-split-1.0.0.jar"
for i in $listaJars; do
	##Get AuthCodeURL
	callback_url=$(curl -w %{redirect_url} "https://admin:admin@$igniteHost:8443/oauth/authorize?approval_prompt=force&client_id=system:serviceaccount:ignite:syndesis-oauth-client&redirect_uri=https://fuse-i
gnite.$igniteDomain/oauth/callback&response_type=code&scope=user:info user:check-access&state=4e45f6c611d5d3a025a3b719f3f84fc9:/api/v1/extensions" -k -s)

	##Get Oauth_proxy cookie
	curl "$callback_url" -H 'Connection: keep-alive' -H 'Upgrade-Insecure-Requests: 1' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8' -H 'DNT: 1' -H "Refer
er: https://$igniteHost:8443/" -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: en-US,en;q=0.9,es;q=0.8,pt-BR;q=0.7,pt;q=0.6' -H 'Cookie: _oauth_proxy_csrf=4e45f6c611d5d3a025a3b719f3f84fc9' --compres
sed --insecure -s --cookie-jar cookies.txt
	##Upload extension file
	extensionJson=$(curl "https://fuse-ignite.$igniteDomain/api/v1/extensions" -H "Origin: https://fuse-ignite.$igniteDomain" -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: en-US,en;q=0.9,es;q=
0.8,pt-BR;q=0.7,pt;q=0.6' -H 'Content-Type: multipart/form-data; boundary=----WebKitFormBoundarygViWhUvjBoryY9Ph' -H 'Accept: */*' -H "Referer: https://fuse-ignite.$igniteDomain/customizations/extensions/import"
 -H 'Connection: keep-alive' -H 'SYNDESIS-XSRF-TOKEN: awesome' -H 'DNT: 1' -F "file=@$i" --compressed --insecure -b cookies.txt -s)

	extensionID=$(echo $extensionJson | jq -r '.id')

	##Install extension
	curl "https://fuse-ignite.$igniteDomain/api/v1/extensions/$extensionID/install" -H "Origin: https://fuse-ignite.$igniteDomain" -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: en-US,en;q=0.9,
es;q=0.8,pt-BR;q=0.7,pt;q=0.6' -H 'Content-Type: application/json' -H 'Accept: application/json, text/plain, */*' -H "Referer: https://fuse-ignite.$igniteDomain/customizations/extensions/import" -H 'Connection: 
keep-alive' -H 'SYNDESIS-XSRF-TOKEN: awesome' -H 'DNT: 1' --data-binary '{}' --compressed --insecure -b cookies.txt
done


