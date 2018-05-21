# POST method: $req
$requestBody = Get-Content $req -Raw 

# Wirte input to Queue
Out-File -FilePath $outputQueueItem -Encoding Ascii -inputObject $requestBody

# Respond to the incoming web request
Out-File -Encoding Ascii -FilePath $res -inputObject $true