-- Custom implementation of pairs and ipairs
local custom_pairs = {}
custom_pairs.__index = custom_pairs
-- Save the original pairs and ipairs
local original_pairs = pairs

-- Define the blacklist for _G keys
local blacklist = {}

-- Convert the blacklist into a lookup table for fast access
local blacklist_lookup = {}
for _, key in ipairs(blacklist) do
    blacklist_lookup[key] = true
end

-- Function to add a key to the blacklist
function custom_pairs.add_to_blacklist(key)
    if not blacklist_lookup[key] then
        table.insert(blacklist, key)
        blacklist_lookup[key] = true
    end
end

-- Function to remove a key from the blacklist
function custom_pairs.remove_from_blacklist(key)
    if blacklist_lookup[key] then
        blacklist_lookup[key] = nil
        for i, v in ipairs(blacklist) do
            if v == key then
                table.remove(blacklist, i)
                break
            end
        end
    end
end

-- Create a filtered version of _G
local function create_filtered_g()
    local filtered_g = {}
    for k, v in original_pairs(_G) do
        if not blacklist_lookup[k] then
            filtered_g[k] = v
        end
    end
    return filtered_g
end

-- Custom pairs function
function custompairs(tbl)
    -- Detect if _G is being accessed
    if tbl == _G then
        local function custom_next(table, key)
            local next_key, next_value = next(table, key)
            while next_key ~= nil and blacklist_lookup[next_key] do
                next_key, next_value = next(table, next_key)
            end
            return next_key, next_value
        end
        return custom_next, tbl, nil
    else
        -- For other tables, fallback to the original pairs
        return original_pairs(tbl)
    end
end

_G.pairs = custompairs
return custom_pairs