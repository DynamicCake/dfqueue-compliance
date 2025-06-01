import dot_env/env

pub fn get_env() -> ProgramEnv {
  let assert Ok(role) = env.get_string("ROLE")
  let assert Ok(host) = env.get_string("HOST")
  let role = case role {
    "dfserver" -> DFServer
    "federation" -> Federation
    _ -> panic as "role must be 'dfserver' or 'federation'"
  }
  let port = env.get_int_or("PORT", 8080)
  let assert Ok(fed_host) = env.get_string("FEDERATION_HOST")
  let assert Ok(fed_port) = env.get_int("FEDERATION_PORT")
  let assert Ok(df_host) = env.get_string("DF_HOST")
  let assert Ok(df_port) = env.get_int("DF_PORT")

  case role {
    DFServer -> {
      ProgramEnv(
        role:,
        host:,
        port:,
        my_host: df_host,
        my_port: df_host,
        other_host: fed_host,
        other_port: fed_port,
      )
    }
    Federation -> {
      ProgramEnv(
        role:,
        host:,
        port:,
        my_host: fed_host,
        my_port: fed_host,
        other_host: df_host,
        other_port: df_port,
      )
    }
  }
}

pub type ProgramEnv {
  ProgramEnv(
    role: TesterRole,
    host: String,
    port: Int,
    my_host: String,
    my_port: String,
    other_host: String,
    other_port: Int,
  )
}

pub type TesterRole {
  DFServer
  Federation
}
