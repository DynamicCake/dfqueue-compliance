import df/tester as df_tester
import dot_env
import env
import federation/tester as fed_tester
import gleam/erlang/process
import wisp

pub fn main() -> Nil {
  wisp.configure_logger()
  dot_env.load_default()

  let env = env.get_env()

  case env.role {
    env.DFServer -> df_tester.start_testing()
    env.Federation -> fed_tester.start_testing(env)
  }

  process.sleep_forever()
}
