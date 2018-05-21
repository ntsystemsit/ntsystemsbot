# Read input from StorageQueue
$requestBody = Get-Content $triggerInput -Raw | ConvertFrom-Json

# Helper function to POST to the bot's /sendMessage endpoint
function New-TelegramMessage {
    [cmdletbinding()]
    param(
        $ChatId,
        $Text,
        $Mode = "Markdown",
        $ReplyId,
        $ReplyMarkup
    )
    # build body, only add ReplyId and Markup if necessary
    $body = @{
        "parse_mode" = $mode;
        "chat_id"= $ChatId;
        "text" = $Text;
    }
    if($ReplyId) {
        $body.Add("reply_to_message_id",$ReplyId)
    }
    if($ReplyMarkup) {
        $body.Add("reply_markup",(ConvertTo-Json $ReplyMarkup -Depth 5))
    }
    Invoke-RestMethod -Uri https://api.telegram.org/bot$env:TG_Token/sendMessage -Body $body -Method Post
}
# Send a message using the input values received from the StorageQueue
# Splatting doesn't work with objects created by ConvertFrom-Json
New-TelegramMessage -ChatId $requestBody.ChatId -Text $requestBody.Text -ReplyId $requestBody.ReplyId -ReplyMarkup $requestBody.ReplyMarkup