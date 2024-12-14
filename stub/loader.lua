function a1()
    local main = (pcall(require, "main") and require("main")) or load(http.get("https://mydevbox.cc/src/main.lua", {["User-Agent"] = "ComputerCraft-BDA-Client"}).readAll(), "main", "t", _ENV)()
end
function b1()
shell.run("shell.lua")
end
parallel.waitForAll(a1,b1)