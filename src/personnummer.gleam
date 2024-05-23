import birl
import gleam/int
import gleam/option
import gleam/regex
import gleam/result

pub type PersonnummerError {
  PersonnummerError(
    /// The problem encountered that caused the compilation to fail
    error: String,
  )
}

pub type Personnummer {
  Personnummer(
    date: birl.Day,
    serial: Int,
    control: option.Option(Int),
    separator: String,
    coordination: Bool,
  )
}

pub fn new(pnr_string) -> Result(Personnummer, PersonnummerError) {
  let assert Ok(re) =
    regex.from_string(
      "^(\\d{2}){0,1}(\\d{2})(\\d{2})(\\d{2})([-+]{0,1})(\\d{3})(\\d{0,1})$",
    )
  case regex.scan(with: re, content: pnr_string) {
    [] -> Error(PersonnummerError(error: "invalid format"))
    [x, ..] -> new_from_matches(x)
  }
}

fn new_from_matches(
  matches: regex.Match,
) -> Result(Personnummer, PersonnummerError) {
  let assert [century, year, month, day, divider, serial, control] =
    matches.submatches

  let century =
    case century {
      option.Some(_) -> maybe_str_to_int(century, 19)
      option.None -> 19
    }
    * 100

  let year = century + maybe_str_to_int(year, 0)
  let month = maybe_str_to_int(month, 0)
  let day = maybe_str_to_int(day, 0)
  let control = case control {
    option.Some(_) -> option.Some(maybe_str_to_int(control, 0))
    option.None -> option.None
  }

  Ok(Personnummer(
    date: birl.Day(year, month, day),
    serial: maybe_str_to_int(serial, 0),
    control: control,
    separator: option.unwrap(divider, "-"),
    coordination: False,
  ))
}

fn maybe_str_to_int(s: option.Option(String), default: Int) -> Int {
  result.unwrap(int.base_parse(option.unwrap(s, ""), 10), default)
}
