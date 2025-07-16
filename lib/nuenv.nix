{
  # The Nuenv build function. Essentially a wrapper around Nix's core derivation function.
  mkNushellDerivation =
    nushell: # nixpkgs.nushell (from overlay)
    sys: # nixpkgs.system (from overlay)

    {

      /*
        The name of the derivation
        Type: String
      */
      name,
      /*
        The derivation's sources
        Type: Path | Derivation
      */
      src,
      /*
        Packages provided to the realisation process
        Type: [Derivation]
      */
      packages ? [ ],
      /*
        The build system
        Type: String
      */
      system ? sys,
      /*
        The build script itself
        Type: String
      */
      build ? "",
      /*
        Run in debug mode
        Type: Boolean
      */
      debug ? true,
      /*
        Outputs to provide
        Type: [String]
      */
      outputs ? [ "out" ],
      /*
        Nushell environment passed to build phases
        Type: Path
      */
      envFile ? ../nuenv/user-env.nu,
      /*
        Catch user-supplied env vars
        Type: AttrSet
      */
      ...
    }@attrs:

    let
      # Gather arbitrary user-supplied environment variables
      reservedAttrs = [
        "build"
        "debug"
        "envFile"
        "name"
        "outputs"
        "packages"
        "src"
        "system"
        "__nu_builder"
        "__nu_debug"
        "__nu_env"
        "__nu_extra_attrs"
        "__nu_nushell"
      ];

      extraAttrs = removeAttrs attrs reservedAttrs;
    in
    derivation (
      {
        # Core derivation info
        inherit
          envFile
          name
          outputs
          packages
          src
          system
          ;

        # Realisation phases (just one for now)
        inherit build;

        # Build logic
        builder = "${nushell}/bin/nu"; # Use Nushell instead of Bash
        args = [ ../nuenv/bootstrap.nu ]; # Run a bootstrap script that then runs the builder

        # When this is set, Nix writes the environment to a JSON file at
        # $NIX_BUILD_TOP/.attrs.json. Because Nushell can handle JSON natively, this approach
        # is generally cleaner than parsing environment variables as strings.
        __structuredAttrs = true;

        # Attributes passed to the environment (prefaced with __nu_ to avoid naming collisions)
        __nu_builder = ../nuenv/builder.nu;
        __nu_debug = debug;
        __nu_env = [ ../nuenv/env.nu ];
        __nu_extra_attrs = extraAttrs;
        __nu_nushell = "${nushell}/bin/nu";
      }
      // extraAttrs
    );

  # An analogue to writeScriptBin but for Nushell rather than Bash scripts.
  mkNushellScript =
    nushell: # nixpkgs.nushell (from overlay)
    writeTextFile: # Utility function (from overlay)

    {
      /*
        The name of the script derivation

        Type: String
      */
      name,
      /*
        The Nushell script content

        Type: String
      */
      script,
      /*
        The binary name (defaults to derivation name)

        Type: String
      */
      bin ? name,
    }:

    let
      nu = "${nushell}/bin/nu";
    in
    writeTextFile {
      inherit name;
      destination = "/bin/${bin}";
      text = ''
        #!${nu}

        ${script}
      '';
      executable = true;
    };

  # A mkShell wrapper that provides Nushell-based development shells
  mkNushellShell =
    nushell: # nixpkgs.nushell (from overlay)
    mkShell: # nixpkgs.mkShell (from overlay)

    {
      /*
        The name of the shell environment
        Type: String
      */
      name ? "nuenv-shell",
      /*
        Packages to include in the shell environment
        Type: [Derivation]
      */
      packages ? [ ],
      /*
        Additional shell hook commands to run on shell initialization
        Type: String
      */
      shellHook ? "",
      /*
        Whether to start with Nushell by default
        Type: Boolean
      */
      startNushell ? true,
      /*
        Catch user-supplied env vars
        Type: AttrSet
      */
      ...
    }@attrs:

    let
      # Filter out our custom attributes
      reservedAttrs = [
        "envFile"
        "startNushell"
      ];

      # Pass through all other attributes to mkShell
      shellAttrs = removeAttrs attrs reservedAttrs;

      # Construct the shell hook
      nuShellHook =
        if startNushell then
          ''
            echo "Starting Nushell with Nuenv environment..."
            exec ${nushell}/bin/nu
          ''
        else
          "";

      # Combine user shell hook with our Nushell hook
      combinedShellHook = shellHook + nuShellHook;
    in
    mkShell (
      shellAttrs
      // {
        inherit name packages;
        shellHook = combinedShellHook;
      }
    );
}
