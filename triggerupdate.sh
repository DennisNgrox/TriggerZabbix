#! /bin/bash

ZABBIX_USER="Admin"
ZABBIX_PASS="zabbix"
ZABBIX_API="http://192.168.126.142/api_jsonrpc.php"

# PARAMETRO $1 DEVE SER O NOME DO HOST, É POSSÍVEL UTILIZAR * COMO CARACTERE CURINGA, POR EXEMPLO: *server* ... todos os hosts que conter server vai entrar nesse script

ZABBIX_AUTH_TOKEN=$(curl -s -H  'Content-Type: application/json-rpc' -d "{\"jsonrpc\": \"2.0\",\"method\":\"user.login\",\"params\":{\"user\":\""${ZABBIX_USER}"\",\"password\":\""${ZABBIX_PASS}"\"},\"auth\": null,\"id\":0}" $ZABBIX_API |  jq -r .result)

GET_HOST_ID=$(curl -s -H 'Content-Type: application/json-rpc' -d "


{
    \"jsonrpc\": \"2.0\",
    \"method\": \"host.get\",
    \"params\": {
        \"output\" : [\"hostid\"],
        \"search\": {
                \"host\": \"$1\"
        },
        \"searchWildcardsEnabled\": true,
        \"searchByAny\": true
    },
    \"auth\": \"${ZABBIX_AUTH_TOKEN}\",
    \"id\": 1
}" ${ZABBIX_API} | jq .result[].hostid | sed s'/"//g'
)

# SE O VALOR FOR NULO, UM ARQUIVO DE LOG SERÁ GERADO PARA VALIDAR QUAIS HOSTS NÃO FORAM ENCONTRADOS, CASO SEJA ACHADO O SCRIPT CONTINUARÁ EM SUA EXECUÇÃO.

VALIDACAO=$(echo $GET_HOST_ID)

if [ -z $VALIDACAO ]; then
        echo "$1 - Host não encontrado" >> /usr/lib/dennis/hostnaoencontrado.txt
else
TESTE=$(curl -s -H  'Content-Type: application/json-rpc' -d "

{
    \"jsonrpc\": \"2.0\",
    \"method\": \"trigger.get\",
    \"params\": {
        \"hostids\": \"${GET_HOST_ID}\",
        \"output\": [
            \"status\",
                \"triggerid\",
            \"description\"
        ]
    },
    \"auth\": \"${ZABBIX_AUTH_TOKEN}\",
    \"id\": 1
}" ${ZABBIX_API}
)

TRIGGERID=$(echo $TESTE |  jq . | grep -B3 testezada | grep -e "triggerid" | sed s'/"//g' | cut -d: -f2 | sed s'/,//g' | sed s'/[[:space:]]//g')

curl -s -H  'Content-Type: application/json-rpc' -d "

{
    \"jsonrpc\": \"2.0\",
    \"method\": \"trigger.update\",
    \"params\": {
        \"triggerid\": \"${TRIGGERID}\",
        \"status\": \"0\"

    },
    \"auth\": \"${ZABBIX_AUTH_TOKEN}\",
    \"id\": 1
}" ${ZABBIX_API}

fi
