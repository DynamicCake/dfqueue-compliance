import df/tester as df_tester
import dot_env
import dot_env/env
import federation/tester as fed_tester
import gleam/erlang/process
import wisp

pub fn main() -> Nil {
  wisp.configure_logger()
  dot_env.load_default()

  let env = get_env()

  case env.role {
    DFServer -> df_tester.start_testing()
    Federation ->
      fed_tester.start_testing(
        env.host,
        env.port,
        env.other_host,
        env.other_port,
      )
  }

  process.sleep_forever()
}

fn get_env() -> ProgramEnv {
  let assert Ok(role) = env.get_string("ROLE")
  let assert Ok(host) = env.get_string("HOST")
  let assert Ok(exposed_port) = env.get_string("EXPOSED_PORT")
  let role = case role {
    "dfserver" -> DFServer
    "federation" -> Federation
    _ -> panic as "role must be 'dfserver' or 'federation'"
  }
  let port = env.get_int_or("PORT", 8080)
  let #(other_host, other_port) = case role {
    DFServer -> {
      let assert Ok(host) = env.get_string("FEDERATION_HOST")
      let assert Ok(port) = env.get_int("FEDERATION_PORT")
      #(host, port)
    }
    Federation -> {
      let assert Ok(host) = env.get_string("DF_HOST")
      let assert Ok(port) = env.get_int("DF_PORT")
      #(host, port)
    }
  }
  ProgramEnv(exposed_port:, role:, host:, port:, other_host:, other_port:)
}

type ProgramEnv {
  ProgramEnv(
    role: TesterRole,
    exposed_port: String,
    host: String,
    port: Int,
    other_host: String,
    other_port: Int,
  )
}

pub type TesterRole {
  DFServer
  Federation
}
