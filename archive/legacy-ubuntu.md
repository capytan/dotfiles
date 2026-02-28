# Legacy Ubuntu Archive

Archived: 2026-02-28
Source: `ubuntu/.alacritty.yml`
Reason: YAML format deprecated in Alacritty. TOML version exists at `ubuntu/.alacritty.toml`.

---

## .alacritty.yml (ubuntu)

Key settings from the deprecated YAML config:

- **Window**: fullscreen, opacity 1.0, decorations full
- **Font**: JetBrains Mono, size 18.0
- **Scrolling**: history 10000, multiplier 3
- **Shell**: `/usr/bin/zsh`
- **Colors**: Tomorrow Night theme (commented out)

The TOML equivalent `ubuntu/.alacritty.toml` preserves the essential settings
and has been moved to `platform/ubuntu/` during repository restructuring.
