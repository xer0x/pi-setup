# Build lean-ctx from crates.io
#
# First build will fail with a hash mismatch — copy the correct hash
# from the error message into `cargoHash` below.
{
  lib,
  rustPlatform,
  fetchCrate,
  pkg-config,
  stdenv,
  apple-sdk_15 ? null,
}:

rustPlatform.buildRustPackage rec {
  pname = "lean-ctx";
  version = "2.1.3";

  src = fetchCrate {
    inherit pname version;
    hash = "sha256-l3yGda1hSd++TS7R7gGJl5/ks82lfsYTl7Y6xzedYfY=";
  };

  cargoHash = "sha256-aM4Z0huG3KmVzGADkpPeT2JOYxEbXZYvPiBUayhKoHE=";

  nativeBuildInputs = [ pkg-config ];

  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    apple-sdk_15
  ];

  # tree-sitter is the default feature and includes many language parsers
  buildFeatures = [ "tree-sitter" ];

  meta = {
    description = "Context Intelligence Engine — reduces LLM token consumption";
    homepage = "https://leanctx.com";
    license = lib.licenses.mit;
    mainProgram = "lean-ctx";
  };
}
