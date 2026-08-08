///|
/// Errors raised during JSON import and validation.
pub(all) enum JsonImportError {
  InvalidJsonSyntax(String)
  UnsupportedSchemaVersion(String)
  MissingRequiredField(String)
  InvalidFieldType(String)
  UnknownField(String)
  DuplicateExperimentId(String)
  DuplicateRunId(String)
  UnknownExperimentForRun(String)
  InvalidRunStatus(String)
  InvalidParamType(String)
  InvalidMetricDirection(String)
} derive(Eq, Debug)

///|
/// Return a readable diagnostic for a JSON import error.
pub fn JsonImportError::message(self : JsonImportError) -> String {
  match self {
    InvalidJsonSyntax(msg) => "invalid JSON syntax: \{msg}"
    UnsupportedSchemaVersion(v) => "unsupported schema_version: \{v}"
    MissingRequiredField(path) => "missing required field: \{path}"
    InvalidFieldType(path) => "invalid field type at: \{path}"
    UnknownField(path) => "unknown field at: \{path}"
    DuplicateExperimentId(id) => "duplicate experiment id: \{id}"
    DuplicateRunId(id) => "duplicate run id: \{id}"
    UnknownExperimentForRun(run_id) =>
      "run references unknown experiment: \{run_id}"
    InvalidRunStatus(s) => "invalid run status: \{s}"
    InvalidParamType(s) => "invalid parameter type: \{s}"
    InvalidMetricDirection(s) => "invalid metric direction: \{s}"
  }
}

///|
/// Import a tracking store from a JSON string with strict validation.
///
/// The JSON must have `schema_version: 1`, an `experiments` array, and a
/// `runs` array. Unknown fields are rejected. All experiment and run ids
/// must be unique, and every run must reference an existing experiment.
pub fn TrackingStore::from_json(
  input : String,
) -> Result[TrackingStore, JsonImportError] {
  let json = @json.parse(input) catch {
    err => return Err(InvalidJsonSyntax("\{err}"))
  }
  let store = TrackingStore::new()
  guard json is Object(obj) else {
    return Err(InvalidJsonSyntax("expected JSON object"))
  }
  match obj.get("schema_version") {
    None => return Err(MissingRequiredField("schema_version"))
    Some(Number(n, ..)) =>
      if n != 1.0 {
        return Err(UnsupportedSchemaVersion(n.to_string()))
      }
    Some(_) => return Err(InvalidFieldType("schema_version"))
  }
  match obj.get("experiments") {
    None => return Err(MissingRequiredField("experiments"))
    Some(Array(exps)) =>
      for exp_json in exps {
        match parse_experiment_json(exp_json) {
          Err(err) => return Err(err)
          Ok(exp) =>
            match store.create_experiment(exp.id(), exp.name()) {
              Err(DuplicateExperiment(id)) =>
                return Err(DuplicateExperimentId(id))
              Err(_) => abort("unexpected error")
              Ok(_) => ()
            }
        }
      }
    Some(_) => return Err(InvalidFieldType("experiments"))
  }
  match obj.get("runs") {
    None => return Err(MissingRequiredField("runs"))
    Some(Array(runs)) =>
      for run_json in runs {
        match parse_run_json(run_json) {
          Err(err) => return Err(err)
          Ok(run) => {
            match store.get_experiment(run.experiment_id()) {
              Err(_) => return Err(UnknownExperimentForRun(run.id()))
              Ok(_) => ()
            }
            match store.import_run(run) {
              Err(DuplicateRun(id)) => return Err(DuplicateRunId(id))
              Err(_) => abort("unexpected error")
              Ok(_) => ()
            }
          }
        }
      }
    Some(_) => return Err(InvalidFieldType("runs"))
  }
  Ok(store)
}

///|
/// Parse a single experiment from JSON.
fn parse_experiment_json(json : Json) -> Result[Experiment, JsonImportError] {
  guard json is Object(obj) else {
    return Err(InvalidJsonSyntax("expected experiment object"))
  }
  let id = match obj.get("id") {
    None => return Err(MissingRequiredField("experiments[].id"))
    Some(String(s)) => s
    Some(_) => return Err(InvalidFieldType("experiments[].id"))
  }
  let name = match obj.get("name") {
    None => return Err(MissingRequiredField("experiments[].name"))
    Some(String(s)) => s
    Some(_) => return Err(InvalidFieldType("experiments[].name"))
  }
  let exp = Experiment::new(id, name)
  let exp = match obj.get("description") {
    None => exp
    Some(String(s)) => exp.with_description(s)
    Some(_) => return Err(InvalidFieldType("experiments[].description"))
  }
  let exp = match obj.get("created_at") {
    None => exp
    Some(String(s)) => exp.with_created_at(s)
    Some(_) => return Err(InvalidFieldType("experiments[].created_at"))
  }
  let exp = match obj.get("tags") {
    None => exp
    Some(Array(tags)) => {
      let tag_arr : Array[String] = []
      for t in tags {
        match t {
          String(s) => tag_arr.push(s)
          _ => return Err(InvalidFieldType("experiments[].tags[]"))
        }
      }
      exp.with_tags(tag_arr)
    }
    Some(_) => return Err(InvalidFieldType("experiments[].tags"))
  }
  Ok(exp)
}

///|
/// Parse a single run from JSON.
fn parse_run_json(json : Json) -> Result[Run, JsonImportError] {
  guard json is Object(obj) else {
    return Err(InvalidJsonSyntax("expected run object"))
  }
  let id = match obj.get("id") {
    None => return Err(MissingRequiredField("runs[].id"))
    Some(String(s)) => s
    Some(_) => return Err(InvalidFieldType("runs[].id"))
  }
  let exp_id = match obj.get("experiment_id") {
    None => return Err(MissingRequiredField("runs[].experiment_id"))
    Some(String(s)) => s
    Some(_) => return Err(InvalidFieldType("runs[].experiment_id"))
  }
  let status = match obj.get("status") {
    None => return Err(MissingRequiredField("runs[].status"))
    Some(String(s)) =>
      match RunStatus::from_string(s) {
        None => return Err(InvalidRunStatus(s))
        Some(st) => st
      }
    Some(_) => return Err(InvalidFieldType("runs[].status"))
  }
  let start_time = match obj.get("start_time") {
    None => return Err(MissingRequiredField("runs[].start_time"))
    Some(String(s)) => s
    Some(_) => return Err(InvalidFieldType("runs[].start_time"))
  }
  let end_time = match obj.get("end_time") {
    None => ""
    Some(String(s)) => s
    Some(_) => return Err(InvalidFieldType("runs[].end_time"))
  }
  let error_message = match obj.get("error_message") {
    None => ""
    Some(String(s)) => s
    Some(_) => return Err(InvalidFieldType("runs[].error_message"))
  }
  let run = Run::new(id, exp_id)
    .with_start_time(start_time)
    .set_status(status)
    .set_end_time(end_time)
    .with_error_message(error_message)
  let run = match obj.get("tags") {
    None => run
    Some(Array(tags)) => {
      let tag_arr : Array[String] = []
      for t in tags {
        match t {
          String(s) => tag_arr.push(s)
          _ => return Err(InvalidFieldType("runs[].tags[]"))
        }
      }
      run.with_tags(tag_arr)
    }
    Some(_) => return Err(InvalidFieldType("runs[].tags"))
  }
  match obj.get("parameters") {
    None => ()
    Some(Array(params)) =>
      for p_json in params {
        match parse_param_json(p_json) {
          Err(err) => return Err(err)
          Ok(param) => run.add_param(param)
        }
      }
    Some(_) => return Err(InvalidFieldType("runs[].parameters"))
  }
  match obj.get("metrics") {
    None => ()
    Some(Array(metrics)) =>
      for m_json in metrics {
        match parse_metric_json(m_json) {
          Err(err) => return Err(err)
          Ok(metric) => run.add_metric(metric)
        }
      }
    Some(_) => return Err(InvalidFieldType("runs[].metrics"))
  }
  match obj.get("artifacts") {
    None => ()
    Some(Array(artifacts)) =>
      for a_json in artifacts {
        match parse_artifact_json(a_json) {
          Err(err) => return Err(err)
          Ok(artifact) => run.add_artifact(artifact)
        }
      }
    Some(_) => return Err(InvalidFieldType("runs[].artifacts"))
  }
  Ok(run)
}

///|
/// Parse a parameter from JSON.
fn parse_param_json(json : Json) -> Result[Param, JsonImportError] {
  guard json is Object(obj) else {
    return Err(InvalidJsonSyntax("expected parameter object"))
  }
  let key = match obj.get("key") {
    None => return Err(MissingRequiredField("parameters[].key"))
    Some(String(s)) => s
    Some(_) => return Err(InvalidFieldType("parameters[].key"))
  }
  let value = match obj.get("value") {
    None => return Err(MissingRequiredField("parameters[].value"))
    Some(String(s)) => s
    Some(_) => return Err(InvalidFieldType("parameters[].value"))
  }
  let type_str = match obj.get("type") {
    None => return Err(MissingRequiredField("parameters[].type"))
    Some(String(s)) => s
    Some(_) => return Err(InvalidFieldType("parameters[].type"))
  }
  let ptype = match ParamType::from_string(type_str) {
    None => return Err(InvalidParamType(type_str))
    Some(t) => t
  }
  Ok(Param::new_typed(key, value, ptype))
}

///|
/// Parse a metric from JSON.
fn parse_metric_json(json : Json) -> Result[Metric, JsonImportError] {
  guard json is Object(obj) else {
    return Err(InvalidJsonSyntax("expected metric object"))
  }
  let key = match obj.get("key") {
    None => return Err(MissingRequiredField("metrics[].key"))
    Some(String(s)) => s
    Some(_) => return Err(InvalidFieldType("metrics[].key"))
  }
  let value = match obj.get("value") {
    None => return Err(MissingRequiredField("metrics[].value"))
    Some(Number(n, ..)) => n
    Some(_) => return Err(InvalidFieldType("metrics[].value"))
  }
  let step = match obj.get("step") {
    None => return Err(MissingRequiredField("metrics[].step"))
    Some(Number(n, ..)) => n.to_int()
    Some(_) => return Err(InvalidFieldType("metrics[].step"))
  }
  let timestamp = match obj.get("timestamp") {
    None => return Err(MissingRequiredField("metrics[].timestamp"))
    Some(String(s)) => s
    Some(_) => return Err(InvalidFieldType("metrics[].timestamp"))
  }
  let metric = Metric::new(key, value, step, timestamp)
  let metric = match obj.get("direction") {
    None => metric
    Some(String(s)) =>
      match MetricDirection::from_string(s) {
        None => return Err(InvalidMetricDirection(s))
        Some(dir) => metric.with_direction(dir)
      }
    Some(_) => return Err(InvalidFieldType("metrics[].direction"))
  }
  Ok(metric)
}

///|
/// Parse an artifact from JSON.
fn parse_artifact_json(json : Json) -> Result[Artifact, JsonImportError] {
  guard json is Object(obj) else {
    return Err(InvalidJsonSyntax("expected artifact object"))
  }
  let name = match obj.get("name") {
    None => return Err(MissingRequiredField("artifacts[].name"))
    Some(String(s)) => s
    Some(_) => return Err(InvalidFieldType("artifacts[].name"))
  }
  let path = match obj.get("path") {
    None => return Err(MissingRequiredField("artifacts[].path"))
    Some(String(s)) => s
    Some(_) => return Err(InvalidFieldType("artifacts[].path"))
  }
  let size = match obj.get("size") {
    None => return Err(MissingRequiredField("artifacts[].size"))
    Some(Number(n, ..)) => n.to_int()
    Some(_) => return Err(InvalidFieldType("artifacts[].size"))
  }
  let artifact = Artifact::new(name, path, size)
  let artifact = match obj.get("checksum") {
    None => artifact
    Some(String(s)) => artifact.with_checksum(s)
    Some(_) => return Err(InvalidFieldType("artifacts[].checksum"))
  }
  Ok(artifact)
}
