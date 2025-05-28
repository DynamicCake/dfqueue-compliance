// Created by Sören Schwert licensed under Apache-2.0
// https://github.com/sisou/nimiq_gleam/commit/f56421d3edffe8ed1c77559719734e1edb52196f

import ed25519/bindings
import gleam/bit_array
import gleam/bytes_tree.{type BytesTree}
import gleam/result
import gleam/string

const size = 32

pub opaque type PrivateKey {
  PrivateKey(buf: BitArray)
}

pub fn generate() -> PrivateKey {
  let #(secret, _) = bindings.generate_key_pair()
  PrivateKey(secret)
}

pub fn deserialize(buf: BitArray) -> Result(#(PrivateKey, BitArray), String) {
  // prevent compiler from complaining
  let _ = size
  case buf {
    <<bytes:unit(8)-size(size)-bytes, rest:bits>> ->
      Ok(#(PrivateKey(bytes), rest))
    _ -> Error("Invalid address: out of data")
  }
}

pub fn deserialize_all(buf: BitArray) -> Result(PrivateKey, String) {
  case deserialize(buf) {
    Ok(#(key, <<>>)) -> Ok(key)
    Ok(_) -> Error("Invalid public key: trailing bytes")
    Error(err) -> Error(err)
  }
}

pub fn from_hex(hex: String) -> Result(PrivateKey, String) {
  case bit_array.base16_decode(hex) {
    Ok(buf) -> deserialize_all(buf)
    Error(_) -> Error("Invalid private key: not a valid hex encoding")
  }
}

pub fn from_base64(base64: String) -> Result(PrivateKey, String) {
  case bit_array.base64_decode(base64) {
    Ok(buf) -> deserialize_all(buf)
    Error(_) -> Error("Invalid private key: not a valid base64 encoding")
  }
}

pub fn from_base64_url(base64_url: String) -> Result(PrivateKey, String) {
  case bit_array.base64_url_decode(base64_url) {
    Ok(buf) -> deserialize_all(buf)
    Error(_) -> Error("Invalid private key: not a valid base64 url encoding")
  }
}

pub fn from_string(str: String) -> Result(PrivateKey, String) {
  from_hex(str)
  |> result.lazy_or(fn() { from_base64(str) })
  |> result.lazy_or(fn() { from_base64_url(str) })
  |> result.map_error(fn(_) { "Invalid private key: unknown format" })
}

pub fn serialize(builder: BytesTree, key: PrivateKey) -> BytesTree {
  builder |> bytes_tree.append(key.buf)
}

pub fn serialize_to_bits(key: PrivateKey) -> BitArray {
  key.buf
}

pub fn to_hex(key: PrivateKey) -> String {
  key
  |> serialize_to_bits()
  |> bit_array.base16_encode()
  |> string.lowercase()
}

pub fn to_base64(key: PrivateKey) -> String {
  key |> serialize_to_bits() |> bit_array.base64_encode(True)
}

pub fn to_base64_url(key: PrivateKey) -> String {
  key |> serialize_to_bits() |> bit_array.base64_url_encode(True)
}
