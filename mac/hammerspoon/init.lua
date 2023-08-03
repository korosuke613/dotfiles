hs.hotkey.bind({"cmd"}, "t", function()
	hs.application.enableSpotlightForNameSearches(true)
    local iterm2 = hs.application.get("iTerm2")
    if iterm2 == nil then
        hs.application.launchOrFocus("/Applications/iTerm.app")
    elseif iterm2:isFrontmost() then
        iterm2:hide()
    else
        hs.application.launchOrFocus("/Applications/iTerm.app")
    end
end)

-- hs.hotkey.bind({"cmd"}, "t", function()
-- 	hs.application.enableSpotlightForNameSearches(true)
--     local warp = hs.application.get("Warp")
--     if warp == nil then
--         hs.application.launchOrFocus("/Applications/Warp.app")
--     elseif warp:isFrontmost() then
--         warp:hide()
--     else
--         hs.application.launchOrFocus("/Applications/Warp.app")
--     end
-- end)

