import decoders
import ed25519/public_key
import ed25519/signature
import gleam/bool
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/json
import gleam/result
import utils
import youid/uuid

pub fn ping_test(base_req: request.Request(String)) -> Result(Nil, PingError) {
  let uuid = uuid.v4()
  let req =
    base_req
    |> request.set_method(http.Get)
    |> request.set_path("/v0/federation/instance")
    |> request.set_query([#("challenge", uuid |> uuid.to_string())])
  use res <- result.try(httpc.send(req) |> result.map_error(SendError))
  use <- bool.guard(
    res.status != 200,
    Error(InvalidStatusError(expected: 200, actual: res.status)),
  )
  // check headers
  use json <- result.try(
    json.parse(res.body, signing_response_decoder())
    |> result.map_error(JsonParseError),
  )
  let is_valid =
    signature.validate_signature(
      json.signature,
      uuid |> uuid.to_bit_array,
      json.server_key,
    )
  use <- bool.guard(
    !is_valid,
    Error(InvalidSignature(json.signature, uuid, json.server_key)),
  )

  Ok(Nil)
}

type SigningResponse {
  SigningResponse(
    server_key: public_key.PublicKey,
    signature: signature.Signature,
  )
}

fn signing_response_decoder() -> decode.Decoder(SigningResponse) {
  use server_key <- decode.field("server_key", decoders.decode_public_key())
  use signature <- decode.field("signature", decoders.decode_signature())
  decode.success(SigningResponse(server_key:, signature:))
}

fn ping_parse_uuid(base_req: request.Request(String)) -> Result(Nil, PingError) {
  let uuid = uuid.v4()
  let req =
    base_req
    |> request.set_method(http.Get)
    |> request.set_path("/v0/federation/instance")
    |> request.set_query([#("challenge", "parse failure")])
  use res <- result.try(httpc.send(req) |> result.map_error(SendError))
  use <- bool.guard(
    res.status != 400,
    Error(InvalidStatusError(400, res.status)),
  )
  use json <- result.try(
    res.body
    |> json.parse(utils.generic_error_decoder())
    |> result.map_error(JsonParseError),
  )

  Ok(Nil)
}

pub type PingError {
  SendError(httpc.HttpError)
  InvalidStatusError(expected: Int, actual: Int)
  JsonParseError(json.DecodeError)
  InvalidSignature(signature.Signature, uuid.Uuid, public_key.PublicKey)
}
