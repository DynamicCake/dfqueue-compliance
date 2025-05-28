// Created by Sören Schwert licensed under Apache-2.0
// https://github.com/sisou/nimiq_gleam/commit/f56421d3edffe8ed1c77559719734e1edb52196f

import ed25519/bindings
import ed25519/private_key.{type PrivateKey}
import gleam/bit_array
import gleam/bytes_tree.{type BytesTree}
import gleam/result
import gleam/string

const size = 32

pub opaque type PublicKey {
  PublicKey(buf: BitArray)
}

pub fn derive_key(private: PrivateKey) -> PublicKey {
  private
  |> private_key.serialize_to_bits()
  |> bindings.derive_public_key()
  |> PublicKey()
}

pub fn default() -> PublicKey {
  PublicKey(<<0:unit(8)-size(size)>>)
}

pub fn deserialize(buf: BitArray) -> Result(#(PublicKey, BitArray), String) {
  case buf {
    <<bytes:unit(8)-size(size)-bytes, rest:bits>> ->
      Ok(#(PublicKey(bytes), rest))
    _ -> Error("Invalid Ed25519 public key: out of data")
  }
}

pub fn deserialize_all(buf: BitArray) -> Result(PublicKey, String) {
  case deserialize(buf) {
    Ok(#(key, <<>>)) -> Ok(key)
    Ok(_) -> Error("Invalid Ed25519 public key: trailing bytes")
    Error(err) -> Error(err)
  }
}

pub fn from_hex(hex: String) -> Result(PublicKey, String) {
  case bit_array.base16_decode(hex) {
    Ok(buf) -> deserialize_all(buf)
    Error(_) -> Error("Invalid public key: not a valid hex encoding")
  }
}

pub fn from_base64(base64: String) -> Result(PublicKey, String) {
  case bit_array.base64_decode(base64) {
    Ok(buf) -> deserialize_all(buf)
    Error(_) -> Error("Invalid public key: not a valid base64 encoding")
  }
}

pub fn from_base64_url(base64_url: String) -> Result(PublicKey, String) {
  case bit_array.base64_url_decode(base64_url) {
    Ok(buf) -> deserialize_all(buf)
    Error(_) -> Error("Invalid public key: not a valid base64 url encoding")
  }
}

pub fn from_string(str: String) -> Result(PublicKey, String) {
  from_hex(str)
  |> result.lazy_or(fn() { from_base64(str) })
  |> result.lazy_or(fn() { from_base64_url(str) })
  |> result.map_error(fn(_) { "Invalid public key: unknown format" })
}

pub fn serialize(builder: BytesTree, key: PublicKey) -> BytesTree {
  builder |> bytes_tree.append(key.buf)
}

pub fn serialize_to_bits(key: PublicKey) -> BitArray {
  key.buf
}

pub fn to_hex(key: PublicKey) -> String {
  key
  |> serialize_to_bits()
  |> bit_array.base16_encode()
  |> string.lowercase()
}

pub fn to_base64(key: PublicKey) -> String {
  key |> serialize_to_bits() |> bit_array.base64_encode(True)
}

pub fn to_base64_url(key: PublicKey) -> String {
  key |> serialize_to_bits() |> bit_array.base64_url_encode(True)
}
