# Read input from StorageQueue
$requestBody = Get-Content $triggerInput -Raw | ConvertFrom-Json
$posts = Get-Content $inPosts -Raw | ConvertFrom-Json | Select-Object -Expand items
$message = $requestBody.message
$chat = $message.chat
# debug
"user $($chat.username) with id $($chat.id) said $($message.text)"
# maybe our users doesn't have a first name
if($chat.first_name){
    $name = $chat.first_name
} else {
    $name = $chat.username
}
# Create output dictionary
$outObj = @{
    "ChatId" = $chat.Id    
}
# Create button structure (must be an array of arrays)
$InlineButton = @{
        inline_keyboard = @(
            # must be array
        )
}
# Put text into variables to keep the code below simple
$HelpText = "`n`nTry one of the following:

/getrandom - get a random post
/gettags - get all tags
/getcategories - get all categories

Enjoy!
"

$TakText = "`n`nTAK can be downloaded or installed from the PS Gallery:
``````
Save-Module -Name TAK -Path <path> 
Install-Module -Name TAK
``````
The code is available on [GitHub](https://github.com/tomtorggler/TAK), 
the latest commit is from $(Get-date (irm https://github.com/tomtorggler/TAK/commits/master.atom | select -f 1).updated)
"

$InfoText = "`n`nWhere I am, it's _$((Get-Date).DateTime)_.

I'm running PS Edition _$($PSVersionTable.PSEdition)_ on _$($env:Computername)_ in _$($env:REGION_NAME)_.

Read more about me [on the blog](https://ntsystems.it/)
"
# Check if the user's message is known and build responses (use regex because in groups the message is /command@group)
switch -regex($message.text) {
    "/getRandom*" {
        $random = $posts | Get-Random
        $outObj.Add("Text", "Here's [$($Random.Title)]($($Random.Url)) written by $($Random.author) on $($Random.date)")
    }
    "/getTags*" {
        $tags = ($posts.tags | Select-Object -Unique ) -join ", "
        $outObj.Add("Text","Here is a list of **tags**: $tags")
    }
    "/getCategories*" {
        foreach ($i in ($posts.category | Select-Object -Unique | Sort-Object)) {
            $ButtonArray += ,@(
                @{
                    text = $i
                    url = "https://ntsystems.it/categories/#$($i.ToLower())"
                }
            )
        }
        $InlineButton.inline_keyboard = $ButtonArray
        $outObj.Add("Text",("Here is a list of **categories**:"))
        $outObj.Add("ReplyMarkup",$InlineButton)
    }
    "/info*" {
        $outObj.Add("Text",("Hi $name!" + $InfoText))
    }
    "/start*" {
        $outObj.Add("Text",("Hi $name!" + $HelpText))
    }
    "/tak*" {
        $posts = $posts.Where{$_.Category -eq "TAK"} | Sort-Object Title
        foreach ($i in $posts) {
            $ButtonArray += ,@(
                @{
                    text = $i.title
                    url = $i.url
                }
            )
        }
        $InlineButton.inline_keyboard = $ButtonArray
        $outObj.Add("Text",$TakText)
        $outObj.Add("ReplyMarkup",$InlineButton)
    }
    Default {
        $outObj.Add("ReplyId",$message.message_id)
        $outObj.Add("Text",("Sorry $name, I didn't get that!" + $HelpText))
    }
}
# write response to queue 
Out-File -Encoding Ascii -FilePath $outputQueueItem -inputObject ($outObj | ConvertTo-Json -Depth 8)