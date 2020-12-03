
api_version = "1.12.0.0"
local path = "sapp\\output.txt"
local output = "%ip%"

function OnScriptLoad()
    register_callback(cb["EVENT_PREJOIN"], "GetIP")
end

function GetIP(Ply)
    local file = assert(io.open(path, "a+"))
    if (file) then
        local IP = get_var(Ply, "$ip"):match("(%d+.%d+.%d+.%d+)")
        file:write(string.gsub(output, "%%ip%%", IP) .. "\n")
        io.close(file)
    end
end

function OnScriptUnload()
    -- N/A
end
