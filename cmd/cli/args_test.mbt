///|
test "header command parses package, output, guard, and recursion" {
  match
    @cli.parse_cli_args([
      "moonbridge", "header", "--package", "examples/scalar_exports", "--out", "generated/api.h",
      "--guard", "SCALAR_API_H", "--recursive",
    ]) {
    Ok(options) => {
      assert_true(options.command is @cli.GenerateHeader)
      assert_eq(options.package_path, "examples/scalar_exports")
      assert_eq(options.output_path, "generated/api.h")
      assert_eq(options.header_guard, "SCALAR_API_H")
      assert_true(options.recursive)
    }
    Err(error) => fail(error)
  }
}

///|
test "manifest and report default to standard output" {
  match @cli.parse_cli_args(["moonbridge", "manifest", "--package", "pkg"]) {
    Ok(options) => {
      assert_true(options.command is @cli.GenerateManifest)
      assert_eq(options.output_path, "-")
      assert_true(!options.recursive)
    }
    Err(error) => fail(error)
  }
  match @cli.parse_cli_args(["moonbridge", "report", "--package", "pkg"]) {
    Ok(options) => {
      assert_true(options.command is @cli.GenerateReport)
      assert_eq(options.output_path, "-")
    }
    Err(error) => fail(error)
  }
  assert_true(
    @cli.parse_cli_args([
      "moonbridge", "manifest", "--package", "pkg", "--guard", "CUSTOM_H",
    ])
    is Err(_),
  )
  assert_true(
    @cli.parse_cli_args([
      "moonbridge", "report", "--package", "pkg", "--guard", "REPORT_H",
    ])
    is Err(_),
  )
}

///|
test "header and check commands require safe file destinations" {
  assert_true(
    @cli.parse_cli_args(["moonbridge", "header", "--package", "pkg"]) is Err(_),
  )
  assert_true(
    @cli.parse_cli_args([
      "moonbridge", "header", "--package", "pkg", "--out", "-",
    ])
    is Err(_),
  )
  assert_true(
    @cli.parse_cli_args([
      "moonbridge", "check", "--package", "pkg", "--out", "-",
    ])
    is Err(_),
  )
  assert_true(
    @cli.parse_cli_args([
      "moonbridge", "check", "--package", "pkg", "--out", "api.h",
    ])
    is Ok(_),
  )
}

///|
test "argument parser rejects duplicate, empty, missing, and unknown options" {
  assert_true(
    @cli.parse_cli_args([
      "moonbridge", "header", "--package", "pkg", "--package", "other", "--out",
      "api.h",
    ])
    is Err(_),
  )
  assert_true(
    @cli.parse_cli_args([
      "moonbridge", "header", "--package", "pkg", "--out", "api.h", "--out", "other.h",
    ])
    is Err(_),
  )
  assert_true(
    @cli.parse_cli_args([
      "moonbridge", "header", "--package", "pkg", "--out", "api.h", "--guard", "A_H",
      "--guard", "B_H",
    ])
    is Err(_),
  )
  assert_true(
    @cli.parse_cli_args(["moonbridge", "header", "--package", "pkg", "--out"])
    is Err(_),
  )
  assert_true(
    @cli.parse_cli_args([
      "moonbridge", "header", "--package", "pkg", "--out", "api.h", "--mystery",
      "x",
    ])
    is Err(_),
  )
  assert_true(
    @cli.parse_cli_args([
      "moonbridge", "header", "--package", "", "--out", "api.h",
    ])
    is Err(_),
  )
  assert_true(
    @cli.parse_cli_args([
      "moonbridge", "header", "--package", "pkg", "--out", "api.h", "--recursive",
      "--recursive",
    ])
    is Err(_),
  )
}

///|
test "help and version commands accept no additional options" {
  assert_true(@cli.parse_cli_args(["moonbridge", "--help"]) is Ok(_))
  assert_true(@cli.parse_cli_args(["moonbridge", "--version"]) is Ok(_))
  assert_true(
    @cli.parse_cli_args(["moonbridge", "--version", "--recursive"]) is Err(_),
  )
  assert_true(@cli.parse_cli_args(["moonbridge", "invented"]) is Err(_))
  assert_eq(@cli.cli_version(), "0.3.0")
}

///|
test "compare command parses package snapshots and breaking change policy" {
  match
    @cli.parse_cli_args([
      "moonbridge", "compare", "--old", "releases/v1", "--new", "releases/v2", "--recursive",
      "--deny-breaking",
    ]) {
    Ok(options) => {
      assert_true(options.command is @cli.CompareAbi)
      assert_eq(options.previous_package_path, "releases/v1")
      assert_eq(options.current_package_path, "releases/v2")
      assert_eq(options.output_path, "-")
      assert_true(options.recursive)
      assert_true(options.deny_breaking)
    }
    Err(error) => fail(error)
  }
  assert_true(
    @cli.parse_cli_args([
      "moonbridge", "compare", "--old", "v1", "--new", "v2", "--out", "abi.txt",
    ])
    is Ok(_),
  )
  assert_true(
    @cli.parse_cli_args(["moonbridge", "compare", "--old", "v1"]) is Err(_),
  )
  assert_true(
    @cli.parse_cli_args([
      "moonbridge", "compare", "--old", "v1", "--new", "v2", "--package", "pkg",
    ])
    is Err(_),
  )
  assert_true(
    @cli.parse_cli_args([
      "moonbridge", "report", "--package", "pkg", "--deny-breaking",
    ])
    is Err(_),
  )
}
