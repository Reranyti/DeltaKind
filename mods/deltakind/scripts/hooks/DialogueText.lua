local DialogueText, super = HookSystem.hookScript(DialogueText)

function DialogueText:init(text, x, y, w, h, options)
    options = options or {}

    options["font"] = "deltarune-cyrillic1"
    options["font_size"] = 16

    super.init(self, text, x, y, w, h, options)
end

return DialogueText