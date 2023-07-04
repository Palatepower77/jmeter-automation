#!/bin/bash

echo 'Download JMeter'
wget -O jmeter.tgz https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-5.5.tgz
tar -xzf jmeter.tgz

echo 'Run JMeter Test'
./apache-jmeter-5.5/bin/jmeter -JTOKEN=${TOKEN} -n -t Palate_App.jmx -l result.jtl > jmeter_output.log
echo "$(cat jmeter_output.log)"

echo 'Convert JTL to CSV'
sed -e 's/<[^>]*>//g' result.jtl > result.csv

echo 'Upload Result Files as Artifacts'
mkdir artifacts
mv result.csv artifacts/result.csv
mv result.jtl artifacts/result.jtl

# Save the artifact path to an environment file
echo "ARTIFACT_PATH=artifacts" >> $GITHUB_ENV

echo 'Check Result Errors'
jmeter_output=$(cat jmeter_output.log)
summary=$(echo "$jmeter_output" | grep -o "summary +.*")
while read -r line; do
  error_count=$(echo "$line" | grep -o "Err: *[0-9]*" | awk -F' ' '{print $NF}')
  if [ "$error_count" -gt 0 ]; then
    echo "There were errors in the JMeter result"
    exit 1
  fi
done <<< "$summary"
echo "No errors found in the JMeter result"
