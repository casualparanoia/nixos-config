# NixOS Configuration

This repository is the source of truth for the machine configuration **and** its engineering documentation.

- NixOS host configurations: `hosts/`
- Reusable NixOS capabilities: `modules/` and `profiles/`
- Home Manager configuration: `home/`
- Local/custom packages: `packages/`
- Helper scripts: `scripts/`
- System knowledge base: [`docs/index.md`](docs/index.md)

The documentation is written as ordinary Markdown and committed with the configuration changes it explains. It is designed to be rendered by Quartz, but Quartz is only a viewer/indexing layer; the Markdown remains canonical.

## Privacy Notice: Facter Reports

> [!WARNING]
> `facter.json` contains detailed hardware and SMBIOS inventory and **must be reviewed before being committed to a public repository**.
>
> It may contain persistent identifiers such as serial numbers, UUIDs, WWNs, MAC addresses, or asset tags. Do not blindly `git commit` or `git push` these files without checking them first. The provided installation scripts only use `git add --intent-to-add` to make the file visible to Nix flake evaluation, keeping the decision to stage and commit entirely manual.
