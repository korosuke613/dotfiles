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
