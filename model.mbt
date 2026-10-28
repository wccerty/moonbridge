///|
/// MoonBit values with a documented, scalar C ABI mapping.
pub(all) enum AbiType {
  Bool
  Int32
  UInt32
  Int64
  UInt64
  Float
  Double
  Unit
}

///|
/// Convert a source type spelling to the deliberately small supported ABI.
pub fn parse_abi_type(type_name : String) -> Result[AbiType, String] {
  match type_name.trim().to_owned() {
    "Bool" => Ok(Bool)
    "Int32" => Ok(Int32)
    "UInt32" => Ok(UInt32)
    "Int64" => Ok(Int64)
    "UInt64" => Ok(UInt64)
    "Float" => Ok(Float)
    "Double" => Ok(Double)
    "Unit" => Ok(Unit)
    unsupported => Err("unsupported C ABI type: \{unsupported}")
  }
}

///|
/// The fixed-width C spelling for a supported MoonBit scalar.
pub fn AbiType::c_spelling(self : AbiType) -> String {
  match self {
    Bool => "int32_t"
    Int32 => "int32_t"
    UInt32 => "uint32_t"
    Int64 => "int64_t"
    UInt64 => "uint64_t"
    Float => "float"
    Double => "double"
    Unit => "void"
  }
}

///|
/// The canonical spelling used by MoonBit source declarations and manifests.
pub fn AbiType::moonbit_spelling(self : AbiType) -> String {
  match self {
    Bool => "Bool"
    Int32 => "Int32"
    UInt32 => "UInt32"
    Int64 => "Int64"
    UInt64 => "UInt64"
    Float => "Float"
    Double => "Double"
    Unit => "Unit"
  }
}

///|
/// The scalar width in bits; `Unit` has no value width.
pub fn AbiType::bit_width(self : AbiType) -> Int32 {
  match self {
    Bool => 32
    Int32 | UInt32 | Float => 32
    Int64 | UInt64 | Double => 64
    Unit => 0
  }
}

///|
/// Whether this type participates in integer range checks in a C consumer.
pub fn AbiType::is_integer(self : AbiType) -> Bool {
  match self {
    Int32 | UInt32 | Int64 | UInt64 => true
    _ => false
  }
}

///|
/// Compare ABI variants without relying on the deprecated implicit Eq methods.
pub fn AbiType::same_as(self : AbiType, other : AbiType) -> Bool {
  match (self, other) {
    (Bool, Bool)
    | (Int32, Int32)
    | (UInt32, UInt32)
    | (Int64, Int64)
    | (UInt64, UInt64)
    | (Float, Float)
    | (Double, Double)
    | (Unit, Unit) => true
    _ => false
  }
}

///|
/// A stable, human-readable declaration for diagnostic output.
pub fn Export::signature(self : Export) -> String {
  let output = StringBuilder()
  output.write_string(self.moonbit_name)
  output.write_char('(')
  for i = 0; i < self.parameters.length(); i = i + 1 {
    if i > 0 {
      output.write_string(", ")
    }
    output.write_string(self.parameters[i].moonbit_spelling())
  }
  output.write_string(") -> ")
  output.write_string(self.result.moonbit_spelling())
  output.to_string()
}

///|
/// A single exported function after ABI validation.
pub(all) struct Export {
  source_path : String
  source_line : Int32
  moonbit_name : String
  c_name : String
  parameters : Array[AbiType]
  parameter_names : Array[String]
  result : AbiType
}

///|
/// C requires ASCII identifiers. Restrict names before emitting a header.
pub fn is_c_identifier(name : String) -> Bool {
  if is_c_keyword(name) || name.has_prefix("_") || name.contains("__") {
    return false
  }
  let chars = name.to_array()
  if chars.length() == 0 {
    return false
  }
  for i = 0; i < chars.length(); i = i + 1 {
    let ch = chars[i]
    let valid = if i == 0 {
      ch.is_ascii_alphabetic()
    } else {
      ch == '_' || ch.is_ascii_alphabetic() || ch.is_ascii_digit()
    }
    if !valid {
      return false
    }
  }
  true
}

///|
/// Reject C and C++ keywords because headers are emitted for both languages.
fn is_c_keyword(name : String) -> Bool {
  match name {
    "alignas"
    | "alignof"
    | "and"
    | "and_eq"
    | "asm"
    | "auto"
    | "bitand"
    | "bitor"
    | "bool"
    | "break"
    | "case"
    | "catch"
    | "char"
    | "char8_t"
    | "char16_t"
    | "char32_t"
    | "class"
    | "compl"
    | "concept"
    | "const"
    | "consteval"
    | "constexpr"
    | "constinit"
    | "const_cast"
    | "continue"
    | "co_await"
    | "co_return"
    | "co_yield"
    | "decltype"
    | "default"
    | "delete"
    | "do"
    | "double"
    | "dynamic_cast"
    | "else"
    | "enum"
    | "explicit"
    | "export"
    | "extern"
    | "false"
    | "float"
    | "for"
    | "friend"
    | "goto"
    | "if"
    | "inline"
    | "int"
    | "long"
    | "mutable"
    | "namespace"
    | "new"
    | "noexcept"
    | "not"
    | "not_eq"
    | "nullptr"
    | "operator"
    | "or"
    | "or_eq"
    | "private"
    | "protected"
    | "public"
    | "register"
    | "restrict"
    | "reinterpret_cast"
    | "requires"
    | "return"
    | "short"
    | "signed"
    | "sizeof"
    | "static"
    | "static_assert"
    | "static_cast"
    | "struct"
    | "switch"
    | "template"
    | "this"
    | "thread_local"
    | "throw"
    | "true"
    | "try"
    | "typedef"
    | "typeid"
    | "typename"
    | "union"
    | "unsigned"
    | "using"
    | "virtual"
    | "void"
    | "volatile"
    | "wchar_t"
    | "while"
    | "xor"
    | "xor_eq" => true
    _ => false
  }
}
