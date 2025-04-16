{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  less,
  installShellFiles,
  zlib,
}:

rustPlatform.buildRustPackage rec {
  pname = "bat";
  version = "0.25.0";

  src = fetchFromGitHub {
    owner = "sharkdp";
    repo = "bat";
    rev = "v${version}";
    hash = "sha256-82IhLhw0TdaMh21phBxcUZ5JI5xOXb0DrwnBmPwyfAQ=";
  };

  useFetchCargoVendor = true;
  cargoHash = "sha256-EnEc+B62dK3q6in8yn5wdeVmBw8XMkP8YKpCN7lCPnc=";

  nativeBuildInputs = [
    pkg-config
    installShellFiles
  ];

  buildInputs = [
    zlib
  ];

  postInstall = ''
    installManPage $releaseDir/build/bat-*/out/assets/manual/bat.1
    installShellCompletion $releaseDir/build/bat-*/out/assets/completions/bat.{bash,fish,zsh}
  '';

  # Skip test cases which depends on `more`
  checkFlags = [
    "--skip=alias_pager_disable_long_overrides_short"
    "--skip=config_read_arguments_from_file"
    "--skip=env_var_bat_paging"
    "--skip=pager_arg_override_env_noconfig"
    "--skip=pager_arg_override_env_withconfig"
    "--skip=pager_basic"
    "--skip=pager_basic_arg"
    "--skip=pager_env_bat_pager_override_config"
    "--skip=pager_env_pager_nooverride_config"
    "--skip=pager_more"
    "--skip=pager_most"
    "--skip=pager_overwrite"
    # Fails if the filesystem performs UTF-8 validation (such as ZFS with utf8only=on)
    "--skip=file_with_invalid_utf8_filename"
  ];

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    testFile=$(mktemp /tmp/bat-test.XXXX)
    echo -ne 'Foobar\n\n\n42' > $testFile
    $out/bin/bat -p $testFile | grep "Foobar"
    $out/bin/bat -p $testFile -r 4:4 | grep 42
    rm $testFile

    runHook postInstallCheck
  '';

  meta = with lib; {
    description = "Cat(1) clone with syntax highlighting and Git integration";
    homepage = "https://github.com/sharkdp/bat";
    changelog = "https://github.com/sharkdp/bat/raw/v${version}/CHANGELOG.md";
    license = with licenses; [
      asl20 # or
      mit
    ];
    mainProgram = "bat";
    maintainers = with maintainers; [
      dywedir
      zowoq
      SuperSandro2000
      sigmasquadron
    ];
  };
}
