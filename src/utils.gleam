import gleam/dynamic/decode
import gleam/time/timestamp

pub type TestReport {
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

pub type GenericError {
  GenericError(code: String, message: String)
}

pub fn generic_error_decoder() -> decode.Decoder(GenericError) {
  use code <- decode.field("code", decode.string)
  use message <- decode.field("message", decode.string)
  decode.success(GenericError(code:, message:))
}
