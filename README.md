# 👻 `ghostty.nvim`

Automatically validate your Ghostty configuration on save

## Demo

https://github.com/user-attachments/assets/16848178-7366-4b81-97e1-82d716747025

## Dependencies

- [Ghostty](https://github.com/ghostty-org/ghostty)

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
    "isak102/ghostty.nvim",
    config = function()
        require("ghostty").setup()
    end,
}
```

## Configuration

The following is the default configuration, and can be passed into the `setup()` function:

```lua
{
    -- The pattern to match the file name. If the file name matches the
    -- pattern, ghostty.nvim will run on save in that buffer.
    file_pattern = "*/ghostty/config",
    -- The ghostty executable to run.
    ghostty_cmd = "ghostty",
    -- The timeout in milliseconds for the check command.
    -- If the command takes longer than this it will be killed.
    check_timeout = 1000,
}
```

## Roadmap

- [ ] Add option to automatically reload ghostty configuration after it has been validated
- [ ] Add `blink.cmp` completion source for config keys (if possible)

## Disclaimer

This plugin is not affiliated with the Ghostty project in any way. Thanks [@mitchellh](https://github.com/mitchellh) and all contributors for building this great terminal!
