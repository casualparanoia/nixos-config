# Appearance and Theming Philosophy

This document defines the architectural principles for configuring appearance, themes, and UI primitives across this NixOS/Home Manager repository.

1. **Shared Primitives, Not Mandatory Uniformity**
   We explicitly avoid a universal color palette abstraction. It is entirely acceptable for different application domains to use distinct visual themes.

2. **Intentional Overrides**
   The following explicit themes are intentionally applied directly in application configurations:
   - **Helix**: Ayu Dark
   - **WezTerm**: Astromouse
   - **Niri**: its own custom palette
   - **Qt/KDE**: external/manual `qtct` + Kvantum workflow
   - **DMS**: wallpaper-derived dynamic theming is intentionally disabled

3. **Override Priority (Future Design Rule)**
   Currently, appearance choices are configured directly in their owning modules or native application configurations; no domain/default inheritance machinery is implemented.
   In the future, if shared appearance data structures are introduced, the conceptual inheritance model will be:
   - Explicit application theme overrides everything.
   - Domain-specific themes.
   - Shared/default appearance values.
   - Application default.
   There is currently no `my.appearance` inheritance machinery implemented in the repository.

4. **Opt-in Theme Generation**
   If generation of configuration fragments (e.g., KDL or TOML template adapters) is introduced in the future, it must remain strictly opt-in.

5. **Configuration Mediums**
   Both live dotfiles (via `my.dotfiles.mode = "live"`) and declarative Nix-generated files (e.g., `xdg.configFile.text`) are valid ownership models. 
   - Use live dotfiles for complex, frequently iterated native configurations (e.g., Niri, WezTerm).
   - Use Nix-generated config for small, stable declarative settings (e.g., Rofi, Satty). Do not move files merely for visual symmetry.
