#!/bin/sh

server_generated_authorization_code=${1}
filename="shipment_id.txt"
endpoint="https://api.mercadolibre.com"
csv=Ejercicio2.csv

# FUNCTIONS ###########################################################################################################
#######################################################################################################################

function obtener_token () {

if [ "$AMBIENTE" == "prod" ]; then

	urlAuthotizationCode=http://auth.mercadolibre.com.ar/authorization?response_type=code&client_id=892829410716603&redirect_uri=https://www.mercadolibre.com.ar

	APP_ID=892829410716603
	secret_key=46d9oQHAlX9FCHPmLbb4XTK55RATJkth
	server_generated_authorization_code=$1
	redirect_uri=https://www.mercadolibre.com.ar


	LOGIN=$(curl -s -X POST -H "accept: application/json" -H "content-type: application/x-www-form-urlencoded" "$endpoint/oauth/token" -d "grant_type=authorization_code" -d "client_id=$APP_ID" -d "client_secret=$secret_key" -d "code=$server_generated_authorization_code" -d "redirect_uri=$redirect_uri")

	if [[ ${LOGIN} != *"access_token"* ]];then
		echo -e "\nError: El 'SERVER_GENERATED_AUTHORIZATION_CODE' es invalido. Generarlo nuevamente.";
		exit 2;
	fi
	
	access_token=$(echo ${LOGIN##*access_token\":\"} | cut -d '"' -f 1)

else
	if [ "$AMBIENTE" == "dev" ]; then
		access_token=APP_USR-892829410716603-051220-f69d351f2855e9d3adf8960f870f5550-84451188
	else
		echo -e "\nError: Debe setear la variable de entorno 'AMBIENTE' con el valor 'prod' o 'dev'";
		exit 2
	fi
fi

echo -e "\nToken obtenido:  ${access_token}\n";

}



function obtener_estado_envio () {

shipmentId=$1

echo -e "\n-Obteniendo estado envio\n"

echo curl -s -X GET -H "Authorization: Bearer $access_token" "$endpoint/shipments/$shipmentId";

if [ "$AMBIENTE" == "prod" ]; then
	datosProd=$(curl -s -X GET -H "Authorization: Bearer $access_token" "$endpoint/shipments/$shipmentId")
	
	if [[ ${datosProd} != *"id"* ||  ${datosProd} == *"resource not found"*  ]];then
		echo -e "\nError: No se pudo obtener datos de productos.\n";
		exit 2;
	else

		arrEstadoActEnvios=( "$(jq -r '.[] | "\(.status|@sh)"' <<< "[$datosProd]"| tr -d "'")")
		arrEstadoActEnvios+=( "$(jq -r '.[] | "\(.lead_time.shipping_method.type|@sh)"' <<< "[$datosProd]"| tr -d "'")")

		obtener_origen "[$datosProd]"
		
		
		fechaestimada=$(jq -r '.[] | "\(.lead_time.estimated_delivery_time.date|@sh)"' <<< "[$datosProd]"| tr -d "'")
		
		arrEstadoActEnvios+=( "${fechaestimada}" )

		fechafinal=$(jq -r '.[] | "\(.lead_time.estimated_delivery_final.date|@sh)"' <<< "[$datosProd]"| tr -d "'")
				
	fi
else
	arrEstadoActEnvios=( "$(jq -r '.[] | "\(.status|@sh)"' "`pwd`/json/${shipmentId}_shipments.json"| tr -d "'")" )
	arrEstadoActEnvios+=( "$(jq -r '.[] | "\(.lead_time.shipping_method.type|@sh)"' "`pwd`/json/${shipmentId}_shipments.json"| tr -d "'")" )

	obtener_origen "`pwd`/json/${shipmentId}_shipments.json"
	
	fechaestimada=$(jq -r '.[] | "\(.lead_time.estimated_delivery_time.date|@sh)"' "`pwd`/json/${shipmentId}_shipments.json"| tr -d "'")
	
	arrEstadoActEnvios+=( "${fechaestimada}" )

	
	fechafinal=$(jq -r '.[] | "\(.lead_time.estimated_delivery_final.date|@sh)"' "`pwd`/json/${shipmentId}_shipments.json"| tr -d "'")
		
fi

registrar_delay ${fechaestimada} ${fechafinal}

}

function obtener_origen () {
jsonin=$1
	
if [ "$AMBIENTE" == "prod" ]; then
	
	origenEnvio=$(jq -r '.[] | "\(.origin.sender_id|@sh)"' <<< "$jsonin"| tr -d "'")
else
	origenEnvio=$(jq -r '.[] | "\(.origin.sender_id|@sh)"' "$jsonin"| tr -d "'")
fi
		
if [ "$origenEnvio" == "4321345667" ]; then
	origenEnvio="Deposito ML"
else
	origenEnvio="Vendedor"
fi

}


function registrar_delay () {

fechaestimada=$1
fechafinal=$2
hhmmss=""

cd=`date --date="${fechafinal}" +%s`
fe=`date --date="${fechaestimada}" +%s`

if [ $cd -gt $fe ]; then
	segundos_a_hhmmss $((cd-fe))
else
	hhmmss="null"
fi

}

function segundos_a_hhmmss()
{

tiempo=$1
hh=$(($tiempo/3600))
mm=$((($tiempo%3600)/60))
ss=$(($tiempo%60))
hhmmss=$(printf "%02d:%02d:%02d\n" $hh $mm $ss)

}

function ordenar_registros ()
{

arrFe=("${!1}")
arrRs=("${!2}")

for ((i=0;i<${#arrFe[@]};i++))
{
	for ((j=i;j<${#arrFe[@]};j++))
    {
		a=`date --date="${arrFe[$i]}" +%s`
		b=`date --date="${arrFe[$j]}" +%s`

		if [ $a -le $b ]; then
			aux=${arrFe[$i]};
			arrFe[$i]=${arrFe[$j]};
			arrFe[$j]=$aux;
			
			aux=${arrRs[$i]};
			arrRs[$i]=${arrRs[$j]};
			arrRs[$j]=$aux;
				  
		fi
	}

}

arrRegistrosShipment=("${arrRs[@]}")

}

function generar_csv () {
line=("${!1}")

echo;

for ((i=0;i<${#line[@]};i++))
{
	outputGencsv=$(echo ${line[$i]} >> $csv)
}

if [ ! -f "$csv" ]; then
	echo "No se pudo generar el archivo '$filecsv'"
	exit 4
fi

}

# MAIN ################################################################################################################
#######################################################################################################################


if [ "$AMBIENTE" == "prod" ]; then

	if [ $# -eq 0 ]; then
		echo -e "\n\e[0;31m###Debe insertar el siguiente parametro en la linea de comando###\e[0m";
		echo -e "\n./challengeGOper_2.sh <SERVER_GENERATED_AUTHORIZATION_CODE>";
		echo -e "\n\e[1;34m<SERVER_GENERATED_AUTHORIZATION_CODE> = Se obtiene de 'https://auth.mercadolibre.com.ar/authorization?response_type=code&client_id=\e[0;31m<APP_ID>\e[0m\e[1;34m&redirect_uri=\e[0m\e[0;31m<YOUR_URL>\e[0m\e[1;34m' \e[0m\n";
		exit 1;
	fi

fi


obtener_token ${server_generated_authorization_code}


while read shipment_id; do

echo -e "\n\e[0;31mshipment_id ${shipment_id}:\e[0m"


obtener_estado_envio ${shipment_id}


arrFechaEstimada+=( "${arrEstadoActEnvios[2]}" )
arrRegistrosShipment+=( "${arrEstadoActEnvios[0]},${arrEstadoActEnvios[1]},${origenEnvio},${arrEstadoActEnvios[2]},${hhmmss}" )


done < "${filename}"

ordenar_registros arrFechaEstimada[@] arrRegistrosShipment[@]

generar_csv arrRegistrosShipment[@]

