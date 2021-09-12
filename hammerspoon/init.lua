hs.hotkey.bind({"cmd"}, "t", function()
    local iterm2 = hs.application.get("iTerm2")
    if iterm2 == nil then
        hs.application.launchOrFocus("/Applications/iTerm.app")
    elseif iterm2:isFrontmost() then
        iterm2:hide()
    else
        hs.application.launchOrFocus("/Applications/iTerm.app")
    end
end)

