// Created by Sören Schwert licensed under Apache-2.0
// https://github.com/sisou/nimiq_gleam/commit/f56421d3edffe8ed1c77559719734e1edb52196f

import ed25519/bindings
import ed25519/private_key.{type PrivateKey}
import ed25519/public_key.{type PublicKey}
import gleam/bit_array
import gleam/bytes_tree.{type BytesTree}
import gleam/result
import gleam/string

const size = 64

pub opaque type Signature {
  Signature(buf: BitArray)
}

pub fn create(
  private: PrivateKey,
  public: PublicKey,
  data: BitArray,
) -> Signature {
  Signature(bindings.signature(
    data,
    private_key.serialize_to_bits(private),
    public_key.serialize_to_bits(public),
  ))
}

pub fn validate_signature(
  sig: Signature,
  bits: BitArray,
  key: public_key.PublicKey,
) -> Bool {
  let assert True =
    public_key.serialize_to_bits(key) |> bit_array.byte_size() == 32
  bindings.valid_signature(sig.buf, bits, public_key.serialize_to_bits(key))
}

pub fn default() -> Signature {
  Signature(<<0:unit(8)-size(size)>>)
}

pub fn deserialize(buf: BitArray) -> Result(#(Signature, BitArray), String) {
  case buf {
    <<bytes:unit(8)-size(size)-bytes, rest:bits>> ->
      Ok(#(Signature(bytes), rest))
    _ -> Error("Invalid signature: out of data")
  }
}

pub fn deserialize_all(buf: BitArray) -> Result(Signature, String) {
  case deserialize(buf) {
    Ok(#(sig, <<>>)) -> Ok(sig)
    Ok(_) -> Error("Invalid signature: trailing bytes")
    Error(err) -> Error(err)
  }
}

pub fn from_hex(hex: String) -> Result(Signature, String) {
  case bit_array.base16_decode(hex) {
    Ok(buf) -> deserialize_all(buf)
    Error(_) -> Error("Invalid signature: not a valid hex encoding")
  }
}

pub fn from_base64(base64: String) -> Result(Signature, String) {
  case bit_array.base64_decode(base64) {
    Ok(buf) -> deserialize_all(buf)
    Error(_) -> Error("Invalid signature: not a valid base64 encoding")
  }
}

pub fn from_base64_url(base64_url: String) -> Result(Signature, String) {
  case bit_array.base64_url_decode(base64_url) {
    Ok(buf) -> deserialize_all(buf)
    Error(_) -> Error("Invalid signature: not a valid base64 url encoding")
  }
}

pub fn from_string(str: String) -> Result(Signature, String) {
  from_hex(str)
  |> result.lazy_or(fn() { from_base64(str) })
  |> result.lazy_or(fn() { from_base64_url(str) })
  |> result.map_error(fn(_) { "Invalid signature: unknown format" })
}

pub fn serialize(builder: BytesTree, sig: Signature) -> BytesTree {
  builder |> bytes_tree.append(sig.buf)
}

pub fn serialize_to_bits(sig: Signature) -> BitArray {
  sig.buf
}

pub fn to_hex(sig: Signature) -> String {
  sig
  |> serialize_to_bits()
  |> bit_array.base16_encode()
  |> string.lowercase()
}

pub fn to_base64(sig: Signature) -> String {
  sig |> serialize_to_bits() |> bit_array.base64_encode(True)
}

pub fn to_base64_url(sig: Signature) -> String {
  sig |> serialize_to_bits() |> bit_array.base64_url_encode(True)
}
