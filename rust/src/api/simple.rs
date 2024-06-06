use super::err::Result;
use serde::Deserialize;

#[derive(Debug, Deserialize)]
pub struct RespErr {
  pub code: i32,
  pub msg: String,
}

#[derive(Debug, Deserialize)]
pub struct Void {}

#[derive(Debug, Deserialize, duplicated_derive::Duplicated)]
pub struct Response {
  pub err: Option<RespErr>,
  pub data: Option<Void>,
}
