# An analogue to writeShellApplication but for Nushell rather than Bash scripts.
{
  lib,
  nushell,
  writeTextFile,
}:

let
  # It might be nicer to write a nix function that translates nix expressions directly to nushell
  # expressions. But since nix and nu both understand json, using that as an intermediary format is
  # way easier.
  toNu = v: "(\"${lib.escape [ "\"" "\\" ] (builtins.toJSON v)}\" | from json)";

  makeBinPathArray =
    pkgs:
    let
      binOutputs = builtins.filter (x: x != null) (map (pkg: lib.getOutput "bin" pkg) pkgs);
    in
    map (output: output + "/bin") binOutputs;
in

{
  /*
    The name of the script to write.
    Type: String
  */
  name,
  /*
    The shell script's text, not including a shebang.
    Type: String
  */
  text,
  /*
    Inputs to add to the shell script's `$PATH` at runtime.
    Type: [String|Derivation]
  */
  runtimeInputs ? [ ],
  /*
    Extra environment variables to set at runtime.
    Type: AttrSet
  */
  runtimeEnv ? null,
  /*
    `stdenv.mkDerivation`'s `meta` argument.
    Type: AttrSet
  */
  meta ? { },
  /*
    The `checkPhase` to run. Defaults to `nu-check`.

    The script path will be given as `$target` in the `checkPhase`.

    Type: String
  */
  checkPhase ? null,
  /*
    Extra arguments to pass to `stdenv.mkDerivation`.

    :::{.caution}
    Certain derivation attributes are used internally,
    overriding those could cause problems.
    :::

    Type: AttrSet
  */
  derivationArgs ? { },
  /*
    The nushell package to use for the script interpreter.

    Type: Derivation
  */
  nushellPackage ? nushell,
  /*
    Extra arguments to pass into nushell invoker
    Defaults to allowing stdin with "--stdin".

    Type: [String]
  */
  nushellArgs ? [ "--stdin" ],
}:
writeTextFile {
  inherit name meta derivationArgs;
  executable = true;
  destination = "/bin/${name}";
  allowSubstitutes = true;
  preferLocalBuild = false;
  text =
    ''
      #!/usr/bin/env -S ${lib.concatStringsSep " " ([ (lib.getExe nushellPackage) ] ++ nushellArgs)}
    ''
    + lib.optionalString (runtimeEnv != null) ''

      load-env ${toNu runtimeEnv}
    ''
    + lib.optionalString (runtimeInputs != [ ]) ''

      $env.PATH = ${toNu (makeBinPathArray runtimeInputs)} ++ ($env.PATH? | default [])
    ''
    + ''

      ${text}
    '';

  checkPhase =
    if checkPhase == null then
      ''
        runHook preCheck
        ${lib.getExe nushellPackage} --commands "nu-check --debug '$target'"
        runHook postCheck
      ''
    else
      checkPhase;
}
