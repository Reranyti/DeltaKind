local Textbox, super = HookSystem.hookScript(Textbox)

function Textbox:init(
    x,
    y,
    width,
    height,
    default_font,
    default_font_size,
    battle_box
)
    default_font = "deltarune-cyrillic1"
    default_font_size = 16

    super.init(
        self,
        x,
        y,
        width,
        height,
        default_font,
        default_font_size,
        battle_box
    )
end

return Textbox