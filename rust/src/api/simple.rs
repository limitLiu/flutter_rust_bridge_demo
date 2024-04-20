use serde::Deserialize;
use std::result;

use crate::frb_generated::SseEncode;

#[derive(Debug, Deserialize)]
pub struct RespErr {
  pub code: i32,
  pub msg: String,
}

#[derive(Debug, Deserialize)]
pub struct Void {}

pub type Result<T> = result::Result<T, FFIError>;

#[derive(Debug)]
pub enum FFIError {
  JsonError(serde_json::Error),
}

impl std::fmt::Display for FFIError {
  fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
    match *self {
      FFIError::JsonError(ref cause) => write!(f, "{}", cause),
    }
  }
}

impl From<serde_json::Error> for FFIError {
  fn from(value: serde_json::Error) -> Self {
    FFIError::JsonError(value)
  }
}

#[derive(Debug, Deserialize, duplicated_derive::Duplicated)]
pub struct Response {
  pub err: Option<RespErr>,
  pub data: Option<Void>,
}

impl SseEncode for FFIError {
  fn sse_encode(self, serializer: &mut flutter_rust_bridge::for_generated::SseSerializer) {
    <String>::sse_encode(format!("{:?}", self), serializer);
  }
}
