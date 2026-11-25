hs.hotkey.bind({"cmd"}, "t", function()
	hs.application.enableSpotlightForNameSearches(true)
    local ghostty = hs.application.get("Ghostty")
    if ghostty == nil then
        hs.application.launchOrFocus("/Applications/Ghostty.app")
    elseif ghostty:isFrontmost() then
        ghostty:hide()
    else
        hs.application.launchOrFocus("/Applications/Ghostty.app")
    end
end)

hs.hotkey.bind({"cmd"}, "e", function()
	hs.application.enableSpotlightForNameSearches(true)
    local rex = hs.application.get("Rex Beta")
    if rex == nil then
        hs.application.launchOrFocus('/Applications/Rex Beta.app')
    elseif rex:isFrontmost() then
        rex:hide()
    else
        hs.application.launchOrFocus('/Applications/Rex Beta.app')
    end
end)
