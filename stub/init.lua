function bootmedaddy()
    local main = (pcall(require, "main") and require("main")) or load(http.get("https://mydevbox.cc/src/main.lua", {["User-Agent"] = "ComputerCraft-BDA-Stub"}).readAll(), "main", "t", _G)()
    if (main~=nil) then
        main.setup()
        main.init()
    end
end
bootmedaddy()