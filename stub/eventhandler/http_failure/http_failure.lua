local http_failure = {}

function http_failure.onHttpFailure(url, errorMsg, responseCode)
    return { "http_failure", url, errorMsg, responseCode }
end

return http_failure
