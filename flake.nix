{
  description = "Static musl development tools bundle for remote servers";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system}.pkgs;
        # Use pkgsStatic to get statically linked musl binaries
        pkgsStatic = nixpkgs.legacyPackages.${system}.pkgsStatic;

        customBat = import ./bat.nix {
            inherit (pkgsStatic) lib fetchFromGitHub rustPlatform;
            inherit (pkgsStatic) less installShellFiles pkg-config zlib;
        };

        # Select only the tools we want, using static musl versions
        tools = [
          pkgs.fzf
          pkgsStatic.ripgrep
          pkgsStatic.fd
          pkgsStatic.skim
          (pkgsStatic.zoxide.override { withFzf = false; })
          pkgsStatic.less
          customBat
#          pkgs.neovim-unwrapped
        ];

        # Create a package that combines all the tools
        dev-tools = pkgsStatic.symlinkJoin {
          name = "dev-tools-bundle-static";
          paths = tools;

          # Create a setup script that can be sourced to add the tools to PATH
          postBuild = ''
            # Create a setup script
            mkdir -p $out/etc
            cat > $out/etc/setup.sh << EOF
            #!/bin/sh
            export PATH="\$PATH:$out/bin"
            export MANPATH="\$MANPATH:$out/share/man"
            EOF

            # Make it executable
            chmod +x $out/etc/setup.sh

            # Create a README
            cat > $out/README.md << EOF
            # Static Development Tools Bundle

            This package contains the following statically linked (musl) tools:
            - ripgrep (rg) - A fast grep alternative
            - fd - A simple, fast and user-friendly alternative to 'find'
            - skim (sk) - A fuzzy finder
            - fzf - A command-line fuzzy finder

            These tools are statically compiled with musl libc and should work on any Linux system
            without requiring any additional libraries.

            ## Usage

            To use these tools, you can either:

            1. Add the \`bin\` directory to your PATH:
               \`\`\`
               export PATH="\$PATH:$(dirname \$0)/bin"
               \`\`\`

            2. Source the setup script:
               \`\`\`
               source "$(dirname \$0)/etc/setup.sh"
               \`\`\`

            This will also add the manpages to your MANPATH.
            EOF
          '';
        };
      in
      {
        packages = {
          # Individual static packages
          ripgrep = pkgsStatic.ripgrep;
          fd = pkgsStatic.fd;
          skim = pkgsStatic.skim;
          zoxide = (pkgsStatic.zoxide.override { withFzf = false; });
          less = pkgsStatic.less;
          customBat = customBat;
          bat = customBat;
          fzf = pkgs.fzf;
#          neovim = pkgs.neovim-unwrapped;


          # The combined static package
          dev-tools = dev-tools;

          bash = pkgsStatic.bash;
          # Make the combined package the default
          default = dev-tools;
        };
      }
    );
}

