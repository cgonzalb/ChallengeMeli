#!/bin/sh

amb="";
server_generated_authorization_code=${1}
filename=./ordenes.txt
csv=Ejercicio1.csv
endpoint=https://api.mercadolibre.com



# FUNCTIONS ###########################################################################################################
#######################################################################################################################


function obtener_token () {

if [ "$amb" == "PROD" ]; then

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
	
	access_token=APP_USR-892829410716603-051220-f69d351f2855e9d3adf8960f870f5550-84451188
fi

echo -e "\nToken obtenido:  ${access_token}\n";

}


function obtener_datos_productos () {

order=$1

echo -e "\n-Obteniendo datos de productos\n"

echo curl -s -X GET -H "Authorization: Bearer $access_token" "$endpoint/orders/$order";

if [ "$amb" == "PROD" ]; then
	datosProd=$(curl -s -X GET -H "Authorization: Bearer $access_token" "$endpoint/orders/$order")
	
	if [[ ${datosProd} != *"id"* ||  ${datosProd} == *"resource not found"*  ]];then
		echo -e "\nError: No se pudo obtener datos de productos.\n";
		exit 2;
	else
		arrDatosProductos=( "$(jq -r '.[] | "\(.order_items | .[].item.title|@sh)"' <<< "[$datosProd]"| tr -d "'")")
		arrDatosProductos+=( "$(jq -r '.[] | "\(.order_items | .[].item.variation_id|@sh)"' <<< "[$datosProd]"| tr -d "'")" )
		arrDatosProductos+=( "$(jq -r '.[] | "\(.payments | .[].id|@sh)"' <<< "[$datosProd]"| tr -d "'")" )
		arrDatosProductos+=( "$(jq -r '.[] | "\(.shipping.id|@sh)"' <<< "[$datosProd]"| tr -d "'")" )
	fi
else
	arrDatosProductos=( "$(jq -r '.[] | "\(.order_items | .[].item.title|@sh)"' "`pwd`/json/${order}_obtener_datos_productos.json"| tr -d "'")" )
	arrDatosProductos+=( "$(jq -r '.[] | "\(.order_items | .[].item.variation_id|@sh)"' "`pwd`/json/${order}_obtener_datos_productos.json"| tr -d "'")" )
	arrDatosProductos+=( "$(jq -r '.[] | "\(.payments | .[].id|@sh)"' "`pwd`/json/${order}_obtener_datos_productos.json"| tr -d "'")" )
	arrDatosProductos+=( "$(jq -r '.[] | "\(.shipping.id|@sh)"' "`pwd`/json/${order}_obtener_datos_productos.json"| tr -d "'")" )

fi

}


function obtener_detalle_pago () {

payment_id=$1

echo -e "\n-Obteniendo detalle de pago\n"

echo curl -s -X GET -H "Authorization: Bearer $access_token" "$endpoint/v1/payments/$payment_id";

if [ "$amb" == "PROD" ]; then
	paymentOut=$(curl -s -X GET -H "Authorization: Bearer $access_token" "$endpoint/v1/payments/$payment_id")

	if [[ ${paymentOut} != *"id"* ||  ${paymentOut} == *"resource not found"*  ]];then
		echo -e "\nError: No se pudo obtener el detalle de pago.\n";
		exit 2;
	else
		arrDetallePago=( "$(jq -r '.[] | "\(.transaction_details.total_paid_amount|@sh)"' <<< "[$paymentOut]"| tr -d "'")")
		arrDetallePago+=( "$(jq -r '.[] | "\(.payment_type_id|@sh)"' <<< "[$paymentOut]"| tr -d "'")" )
	fi
else
	arrDetallePago=( "$(jq -r '.[] | "\(.transaction_details.total_paid_amount|@sh)"' "`pwd`/json/${payment_id}_obtener_detalle_pago.json"| tr -d "'")" )
	arrDetallePago+=( "$(jq -r '.[] | "\(.payment_type_id|@sh)"' "`pwd`/json/${payment_id}_obtener_detalle_pago.json"| tr -d "'")" )
fi	

}


function obtener_tipo_logistica () {

shipment_id=$1

echo -e "\n-Obteniendo tipo de logistica\n"

echo curl -s -X GET -H "Authorization: Bearer $access_token" "$endpoint/shipments/$shipment_id/lead_time";

if [ "$amb" == "PROD" ]; then
	tipoLogisout=$(curl -s -X GET -H "Authorization: Bearer $access_token" "$endpoint/shipments/$shipment_id/lead_time")
	
	if [[ ${tipoLogisout} != *"id"* ||  ${tipoLogisout} == *"resource not found"*  ]];then
		echo -e "\nError: No se pudo obtener los datos del tipo de logistica.\n";
		exit 2;
	else	
		arrTipoLogistica=$(jq -r '.[] | "\(.shipping_method.type|@sh)"' <<< "[$tipoLogisout]"| tr -d "'")
	fi
else
	arrTipoLogistica=$(jq -r '.[] | "\(.shipping_method.type|@sh)"' "`pwd`/json/${shipment_id}_obtener_tipo_logistica.json"| tr -d "'")
fi

}


function obtener_datos_envio () {

shipment_id=$1

echo -e "\n-Obteniendo datos de envio\n"

echo curl -s -X GET -H "Authorization: Bearer $access_token" "$endpoint/shipments/$shipment_id";

if [ "$amb" == "PROD" ]; then
	shipmentout=$(curl -s -X GET -H "Authorization: Bearer $access_token" "$endpoint/shipments/$shipment_id")
	
	if [[ ${shipmentout} != *"id"* ||  ${shipmentout} == *"resource not found"*  ]];then
		echo -e "\nError: No se pudo obtener los datos de envio.\n";
		exit 2;
	else	
		
		obtener_origen "${shipmentout}"
		
		obtener_destino "${shipmentout}"
				
	fi
else

	obtener_origen "`pwd`/json/${shipment_id}_obtener_datos_envio.json"
	
	obtener_destino "`pwd`/json/${shipment_id}_obtener_datos_envio.json"

fi

}

function obtener_origen () {
jsonin=$1
	
if [ "$amb" == "PROD" ]; then
	
	origdomicilio=$(jq -r '.[] | "\(.origin.sender_id|@sh)"' <<< "$jsonin"| tr -d "'")
else
	origdomicilio=$(jq -r '.[] | "\(.origin.sender_id|@sh)"' "$jsonin"| tr -d "'")
fi
		
if [ "$origdomicilio" = "4321345667" ]; then
	arrDatosEnvio=( "Deposito ML" )
else
	arrDatosEnvio=( "Vendedor" )
fi

}


function obtener_destino () {
jsonin=$1

if [ "$amb" == "PROD" ]; then

	destdomicilio=( "$(jq -r '.[] | "\(.destination.shipping_address.address_id|@sh)"' <<< "$jsonin"| tr -d "'")" )
	destagencia=( "$(jq -r '.[] | "\(.destination.shipping_address.agency.carrier_id|@sh)"' <<< "$jsonin"| tr -d "'")" )

	if [ "$destdomicilio" != "null" ]; then
		arrDatosEnvio+=( "Domicilio: $(jq -r '.[] | "\(.destination.shipping_address.address_line|@sh)"' <<< "$jsonin"| tr -d "'")" )
		
	else
		if [ "$destagencia" != "null" ]; then
			arrDatosEnvio+=( "Agencia: $(jq -r '.[] | "\(.destination.shipping_address.agency.agency_id|@sh)"' <<< "$jsonin"| tr -d "'")_${destagencia}" )
		else
			arrDatosEnvio+=( "No se registra agencia ni domicilio" )
		fi	
	fi

else

	destdomicilio=( "$(jq -r '.[] | "\(.destination.shipping_address.address_id|@sh)"' "$jsonin"| tr -d "'")" )
	destagencia=( "$(jq -r '.[] | "\(.destination.shipping_address.agency.carrier_id|@sh)"' "$jsonin"| tr -d "'")" )

	if [ "$destdomicilio" != "null" ]; then
		arrDatosEnvio+=( "Domicilio: $(jq -r '.[] | "\(.destination.shipping_address.address_line|@sh)"' "$jsonin"| tr -d "'")" )
		
	else
		if [ "$destagencia" != "null" ]; then
			arrDatosEnvio+=( "Agencia: $(jq -r '.[] | "\(.destination.shipping_address.agency.agency_id|@sh)"' "$jsonin"| tr -d "'")_${destagencia}" )
		else
			arrDatosEnvio+=( "No se registra agencia ni domicilio" )
		fi	
	fi
fi

}

function obtener_costo_envio () {
echo;
}


function obtener_carrier () {

shipment_id=$1

echo -e "\n-Obteniendo datos del Carrier\n"

echo curl -s -X GET -H "Authorization: Bearer $access_token" "$endpoint/shipments/$shipment_id/carrier";

if [ "$amb" == "PROD" ]; then
	carrierOut=$(curl -s -X GET -H "Authorization: Bearer $access_token" "$endpoint/shipments/$shipment_id/carrier")
	
	if [[ ${carrierOut} != *"name"* ||  ${carrierOut} == *"resource not found"*  ]];then
		echo -e "\nError: No se pudo obtener los datos del Carrier.\n";
		exit 2;
	else	
		arrDatosCarrier=$(jq -r '.[] | "\(.name|@sh)"' <<< "[$carrierOut]"| tr -d "'")
	fi
else
	arrDatosCarrier=$(jq -r '.[] | "\(.name|@sh)"' "`pwd`/json/${shipment_id}_obtener_carrier.json"| tr -d "'")
fi

}

function obtener_tiempo_envio () {
order_id=$1

echo -e "\n-Obteniendo tiempos de envio\n"

echo curl -s -X GET -H "Authorization: Bearer $access_token" "$endpoint/orders/$order_id/shipments";

if [ "$amb" == "PROD" ]; then
	tiempoOut=$(curl -s -X GET -H "Authorization: Bearer $access_token" "$endpoint/orders/$order_id/shipments")

	if [[ ${tiempoOut} != *"id"* ||  ${tiempoOut} == *"resource not found"*  ]];then
		echo -e "\nError: No se pudo obtener los datos del Carrier.\n";
		exit 2;
	else	
		diaentrega=( "$(jq -r '.[] | "\(.status_history.date_delivered|@sh)"' <<< "[$tiempoOut]"| tr -d "'")" )
		promesaentrega=( "$(jq -r '.[] | "\(.shipping_option.estimated_delivery_time.date|@sh)"' <<< "[$tiempoOut]"| tr -d "'")" )
		fechafinal=( "$(jq -r '.[] | "\(.shipping_option.estimated_delivery_time.offset.date|@sh)"' <<< "[$tiempoOut]"| tr -d "'")" )
		
	fi
else
	diaentrega=( "$(jq -r '.[] | "\(.status_history.date_delivered|@sh)"' "`pwd`/json/${order_id}_obtener_tiempo_envio.json"| tr -d "'")" )
	promesaentrega=( "$(jq -r '.[] | "\(.shipping_option.estimated_delivery_time.date|@sh)"' "`pwd`/json/${order_id}_obtener_tiempo_envio.json"| tr -d "'")" )
	fechafinal=( "$(jq -r '.[] | "\(.shipping_option.estimated_delivery_time.offset.date|@sh)"' "`pwd`/json/${order_id}_obtener_tiempo_envio.json"| tr -d "'")" )
fi	

cumple_entrega ${diaentrega} ${promesaentrega} ${fechafinal}

arrTiempoEnvio=( "${diaentrega}" )
arrTiempoEnvio+=( "${promesaentrega}" )
arrTiempoEnvio+=( "${fechafinal}" )
arrTiempoEnvio+=( "${env_tiemform}" )
	
}

function cumple_entrega () {

diaentrega=$1
promesaentrega=$2
fechafinal=$3
current_date=`date +%Y-%m-%dT%H:%M:%S%z`

if [ "$diaentrega" != "null" ]; then
	cd=`date --date="${diaentrega}" +%s`
else
	cd=`date --date="${current_date}" +%s`
fi

fe=`date --date="${promesaentrega}" +%s`
ff=`date --date="${fechafinal}" +%s`


if [ $cd -ge $fe ]; then
	if [ $cd -le $ff ]; then
		env_tiemform="Envio en tiempo y forma"
	else
		env_tiemform="Envio fuera del plazo"
	fi
else
	env_tiemform="Envio fuera del plazo"
fi

}

function generar_csv () {
line=$1
filecsv=$2

echo;
outputGencsv=$(echo $line >> $filecsv)

if [ ! -f "$filecsv" ]; then
	echo "No se pudo generar el archivo '$filecsv'"
	exit 4
fi

}

# MAIN ################################################################################################################
#######################################################################################################################

if [ "$amb" == "PROD" ]; then

	if [ $# -eq 0 ]; then
		echo -e "\n\e[0;31m###Debe insertar el siguiente parametro en la linea de comando###\e[0m";
		echo -e "\n./challengeGOper_1.sh <SERVER_GENERATED_AUTHORIZATION_CODE>";
		echo -e "\n\e[1;34m<SERVER_GENERATED_AUTHORIZATION_CODE> = Se obtiene de 'https://auth.mercadolibre.com.ar/authorization?response_type=code&client_id=\e[0;31m<APP_ID>\e[0m\e[1;34m&redirect_uri=\e[0m\e[0;31m<YOUR_URL>\e[0m\e[1;34m' \e[0m\n";
		exit 1;
	fi

fi

obtener_token ${server_generated_authorization_code}


while read order_id; do

echo -e "\n\e[0;31mORDEN ${order_id}:\e[0m"


obtener_datos_productos ${order_id};

obtener_detalle_pago ${arrDatosProductos[2]};

obtener_tipo_logistica ${arrDatosProductos[3]};

obtener_datos_envio ${arrDatosProductos[3]};

obtener_carrier ${arrDatosProductos[3]};

obtener_tiempo_envio ${order_id};



generar_csv "${order_id},${arrDatosProductos[0]},${arrDatosProductos[1]},${arrDetallePago[0]},${arrDetallePago[1]},${arrTipoLogistica},${arrDatosEnvio[0]},${arrDatosEnvio[1]},NO ENCONTRE JSON EJEMPLO PARA PUNTO 3.d,${arrDatosCarrier},${arrTiempoEnvio[0]},${arrTiempoEnvio[1]},${arrTiempoEnvio[2]},${arrTiempoEnvio[3]}" ${csv};

done < "${filename}"
