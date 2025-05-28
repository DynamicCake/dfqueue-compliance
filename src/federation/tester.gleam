import decoders
import ed25519/public_key
import ed25519/signature
import gleam/bool
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/io
import gleam/json
import gleam/result
import gleam/string
import youid/uuid

pub type Tester

pub fn start_testing(
  target_host: String,
  target_port: Int,
  df_host: String,
  df_port: Int,
) {
  let base_req =
    request.new()
    |> request.set_scheme(http.Http)
    |> request.set_host(target_host)
    |> request.set_port(target_port)
  let assert Ok(Nil) = ping_test(base_req)
  io.println("abc")
  // ^^^ this is important because it flushes stdout

  // let secret_key =
  //   crypto.strong_random_bytes(42) |> bit_array.base64_encode(True)
  // let assert Ok(subj) =
  //   wisp_mist.handler(todo, secret_key)
  //   |> mist.new
  //   |> mist.bind("0.0.0.0")
  //   |> mist.port(port)
  //   |> mist.start_http
}

fn ping_test(base_req: request.Request(String)) -> Result(Nil, String) {
  let uuid = uuid.v4()
  let req =
    base_req
    |> request.set_method(http.Get)
    |> request.set_path("/v0/federation/instance")
    |> request.set_query([#("challenge", uuid |> uuid.to_string())])
  use res <- result.try(httpc.send(req) |> result.map_error(string.inspect))
  use <- bool.guard(res.status == 200, Error("Status should be 200"))
  // check headers
  use json <- result.try(
    json.parse(res.body, signing_response_decoder())
    |> result.map_error(string.inspect),
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
