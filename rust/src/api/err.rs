use std::result;

use crate::frb_generated::SseEncode;

#[derive(Debug)]
pub enum FFIError {
  JsonError(sonic_rs::Error),
  QrCode(String),
}

pub type Result<T> = result::Result<T, FFIError>;

impl From<sonic_rs::Error> for FFIError {
  fn from(value: sonic_rs::Error) -> Self {
    FFIError::JsonError(value)
  }
}

impl SseEncode for FFIError {
  fn sse_encode(self, serializer: &mut flutter_rust_bridge::for_generated::SseSerializer) {
    <String>::sse_encode(format!("{:?}", self), serializer);
  }
}

impl std::fmt::Display for FFIError {
  fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
    match *self {
      FFIError::JsonError(ref cause) => write!(f, "{}", cause),
      FFIError::QrCode(ref cause) => write!(f, "{}", cause),
    }
  }
}

