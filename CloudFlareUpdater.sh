#!/bin/sh
if [ $(ping -q -w 1 -c 1 `ip r | grep default | cut -d ' ' -f 3` > /dev/null && echo ok || echo error) != ok ]
then
    exit $?
fi

apikey=""
zoneid=""
email=""
Arecord1=""
Arecord2=""
uri="https://api.cloudflare.com/client/v4/zones/$zoneid/dns_records/"
getrecords=$(curl -X GET $uri -H "Content-Type:application/json" -H "X-Auth-Key:$apikey" -H "X-Auth-Email:$email")
record=$(echo $getrecords | python -c "import sys, json; print json.load(sys.stdin)['result']")
currentrecord=$(echo $(echo $record | awk -F ":" '{print $6}') | awk -F "'" '{print $2}')
# publicip=$(curl http://ipinfo.io/json | python -c "import sys, json; print json.load(sys.stdin)['ip']")
# publicip=curl -s http://whatismijnip.nl |cut -d " " -f 5
publicip=$(curl 'https://api.ipify.org?format=json/' | cut -d '"' -f 4)
if [ $publicip != $currentrecord ]
then
    uri="https://api.cloudflare.com/client/v4/zones/$zoneid/dns_records/$Arecord1"
    body='{"type":"A","name":"davesdesk.io","content":"'$publicip'","ttl":120,"proxiable":true,"proxied":true}'
    curl -X PUT $uri -H "X-Auth-Email:$email" -H "Content-Type:application/json" -H "X-Auth-Key:$apikey" -d $body

    uri="https://api.cloudflare.com/client/v4/zones/$zoneid/dns_records/$Arecord2"
    body='{"type":"A","name":"live.davesdesk.io","content":"'$publicip'","ttl":120,"proxiable":true,"proxied":true}'
    curl -X PUT $uri -H "X-Auth-Email:$email" -H "Content-Type:application/json" -H "X-Auth-Key:$apikey" -d $body

    echo "[ CloudFlare A records updated ] [ $(date '+%Y-%m-%d %H:%M:%S') ] [ PublicIP: $publicip ]" >> /home/pi/CFUpdater.log
fi