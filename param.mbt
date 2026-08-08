///|
/// The type of a parameter value.
pub(all) enum ParamType {
  IntParam
  FloatParam
  BoolParam
  StringParam
} derive(Eq, Debug)

///|
/// A parameter key-value pair with type information.
pub struct Param {
  priv key : String
  priv value : String
  priv type_ : ParamType
  priv description : String
} derive(Eq, Debug)

///|
/// Build a string parameter.
pub fn Param::new_string(key : String, value : String) -> Param {
  { key, value, type_: StringParam, description: "" }
}

///|
/// Build an integer parameter.
pub fn Param::new_int(key : String, value : Int) -> Param {
  { key, value: value.to_string(), type_: IntParam, description: "" }
}

///|
/// Build a float parameter.
pub fn Param::new_float(key : String, value : Double) -> Param {
  { key, value: value.to_string(), type_: FloatParam, description: "" }
}

///|
/// Build a boolean parameter.
pub fn Param::new_bool(key : String, value : Bool) -> Param {
  { key, value: value.to_string(), type_: BoolParam, description: "" }
}

///|
/// Return the parameter key.
pub fn Param::key(self : Param) -> String {
  self.key
}

///|
/// Return the parameter value as a string.
pub fn Param::value(self : Param) -> String {
  self.value
}

///|
/// Return the parameter type.
pub fn Param::type_(self : Param) -> ParamType {
  self.type_
}

///|
/// Return the parameter description.
pub fn Param::description(self : Param) -> String {
  self.description
}

///|
/// Add a description to a parameter.
pub fn Param::with_description(self : Param, description : String) -> Param {
  { ..self, description, }
}

///|
/// Return a stable machine-readable type kind string.
pub fn ParamType::kind(self : ParamType) -> String {
  match self {
    IntParam => "int"
    FloatParam => "float"
    BoolParam => "bool"
    StringParam => "string"
  }
}

///|
/// Return a stable human-readable type label.
pub fn ParamType::label(self : ParamType) -> String {
  self.kind()
}

///|
/// Build a parameter with an explicit type and string value.
///
/// This is intended for JSON import tools that already have the type
/// information and the value as a string.
pub fn Param::new_typed(
  key : String,
  value : String,
  type_ : ParamType,
) -> Param {
  { key, value, type_, description: "" }
}

///|
/// Parse a parameter type from its string kind.
pub fn ParamType::from_string(s : String) -> ParamType? {
  match s {
    "int" => Some(IntParam)
    "float" => Some(FloatParam)
    "bool" => Some(BoolParam)
    "string" => Some(StringParam)
    _ => None
  }
}
