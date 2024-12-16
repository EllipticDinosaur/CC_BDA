local http_success = {}

function http_success.onHttpSuccess(url, responseBody)
    return { "http_success", url, responseBody }
end

return http_success
