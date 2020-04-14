RUN_ID=$(python3 _kfp.py ml-train-iris)
echo "RUN ID: ${RUN_ID}"

SUCCESS="Succeeded"
STATUS="Start"
while [ "${STATUS}" != "${SUCCESS}" ]; do
  STATUS=$(kfp run list | grep "${RUN_ID}" | awk -F "|" '{ print $4 }')
  if [ "${STATUS}" == "" ]; then
    echo "Status: Pending"
  else
    echo "Status: ${STATUS}"
  fi
  sleep 5
done

echo "${STATUS}!"
