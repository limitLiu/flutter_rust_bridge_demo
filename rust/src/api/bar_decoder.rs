use image::{DynamicImage, ImageBuffer};

use super::err;

pub fn decode(bytes: Vec<u8>, width: u32, height: u32) -> err::Result<String> {
  let decoder = bardecoder::default_decoder();
  let img = ImageBuffer::from_vec(width, height, bytes).unwrap();
  let img = DynamicImage::ImageRgb8(img);
  let results = decoder.decode(&img);
  let result = &results[0];
  match result {
    Ok(r) => Ok(r.to_owned()),
    Err(e) => Err(err::FFIError::QrCode(e.to_string())),
  }
}

