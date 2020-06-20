#!/bin/bash
echo "Running Tests"

  TESTPROJECTS=(
      "data"
      "common"
      "controller"
  )

for ITEM in "${!TESTPROJECTS[@]}"
do
  TEST="${TESTPROJECTS[${ITEM}]}"
  cd "./tests.${TEST}"
  echo "Running ${TEST} Tests"
  
  # Remove comments from settings file and make sure that provider is file as CosmosDB emulator cannot be used in Linux Agent  
  if [ -f "appsettings.test.json" ]; then 
    TMPFILE=$(mktemp)
    cat appsettings.test.json \
      | sed -e '/^[[:blank:]]*\/\//d' -e's/,[[:blank:]]*\/\/.*$/,/' \
      | jq '."Microsoft.ProviderHub.ProviderCommon.DocumentDataProviderType"="cosmosdb"' \
      | jq '."Microsoft.ProviderHub.ProviderCommon.CosmosDbEndpoint"="https://host.docker.internal:8081/"' \
      | jq '."Microsoft.ProviderHub.ProviderCommon.RPSaaSGlobalData.global.CosmosDbEndpoint"="https://host.docker.internal:8081/"' \
      | jq '."Microsoft.ProviderHub.ProviderCommon.Microsoft.UserRP1.global.CosmosDbEndpoint"="https://host.docker.internal:8081/"' > "${TMPFILE}" && mv "${TMPFILE}" appsettings.test.json
  fi

  dotnet test --no-build --logger "trx;LogFileName=/test/TestResults/testresults.${TEST}.trx" --diag:/test/TestResults/Monitoring.${TEST}.Linux.Tests.log.tx --blame --verbosity normal -o . 

  EX=$?

  # Check exit code and exit with it if it is non-zero so that build will fail
  if [ "$EX" -ne "0" ]; then
      echo "Failed Running ${TEST} Tests."
      exit $EX
  fi

  echo "Finished Running ${TEST} Tests"
  cd ..
done

exit 0