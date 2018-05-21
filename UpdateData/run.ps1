# Get Posts as simple text blob, worker converts from json
(Invoke-WebRequest https://ntsystems.it/api/v1/posts/ -UseBasicParsing).content | Out-File -Encoding ascii -FilePath $outPosts
