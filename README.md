# ChallengeMeli
Challenge Tecnico Gestión Operativa

Para realizar la ejecución de los scripts se deberá setear la variable de entorno 'AMBIENTE' con los siguientes valores de acuerdo con su necesidad.

-MOCK: 

#export AMBIENTE=dev

Ejecución del scrrpt

#./challengeGOper_1.sh

#./challengeGOper_2.sh

-PRODUCCION: 

#export AMBIENTE=prod

Ejecución del scrrpt

#./challengeGOper_1.sh 	<SERVER_GENERATED_AUTHORIZATION_CODE>

#./challengeGOper_2.sh 	<SERVER_GENERATED_AUTHORIZATION_CODE>

Parametro <SERVER_GENERATED_AUTHORIZATION_CODE> : Se obtiene de 'https://auth.mercadolibre.com.ar/authorization?response_type=code&client_id=<APP_ID>&redirect_uri=<YOUR_URL>'
