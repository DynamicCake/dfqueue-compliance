import ed25519/private_key
import ed25519/public_key
import env
import federation/ping
import gleam/http
import gleam/http/request
import gleam/io
import gleam/json
import gleam/list
import gleam/string
import gleam/time/timestamp
import youid/uuid

pub type Tester

pub fn start_testing(env: env.ProgramEnv) {
  let private_key = private_key.generate()
  let server_key = public_key.derive_key(private_key)

  let base_req =
    request.new()
    |> request.set_scheme(http.Http)
    |> request.set_host(env.host)
    |> request.set_port(env.port)

  let results =
    []
    |> list.prepend(process_result(ping.ping_test, base_req, "ping"))
  // |> list.prepend(process_result(
  //   ping.ping_,
  //   base_req,
  //   "ping_parse_uuid",
  // ))
  // |> list.prepend(process_result(
  //   ping.ping_parse2_test,
  //   base_req,
  //   "ping_parse2",
  // ))

  io.println("A")
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

fn process_result(
  testing: fn(a) -> Result(Nil, e),
  args: a,
  test_name: String,
) -> TestReport {
  let start = timestamp.system_time()
  let res = testing(args)
  let end = timestamp.system_time()
  case res {
    Ok(Nil) -> TestReport(name: test_name, result: Success, start:, end:)
    Error(err) ->
      TestReport(
        name: test_name,
        result: Failure(err: err |> string.inspect),
        start:,
        end:,
      )
  }
}

// pub fn cascade_test_report(name: String) -> TestReport {
//   TestReport(
//     name:,
//     result: Cascade,
//     start: timestamp.system_time(),
//     end: timestamp.system_time(),
//   )
// }

type TestReport {
  TestReport(
    name: String,
    result: TestResult,
    start: timestamp.Timestamp,
    end: timestamp.Timestamp,
  )
}

pub type TestResult {
  Success
  Failure(err: String)
  Cascade
}

pub fn get_key_test(
  base_req: request.Request(String),
  remote_key: public_key.PublicKey,
  testing_key: public_key.PublicKey,
) {
  let uuid = uuid.v4()
  let req =
    base_req
    |> request.set_method(http.Post)
    |> request.set_path("/v0/federation/instance")
    |> request.set_body(
      json.object([
        #(
          "public_key",
          testing_key |> public_key.to_base64_url() |> json.string(),
        ),
        #("challenge", uuid |> uuid.to_string() |> json.string()),
        #("host", todo),
      ]),
    )
  todo
}
