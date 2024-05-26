import gleam/bool
import gleam/int
import gleam/iterator
import gleam/list
import gleam/option
import gleam/regex
import gleam/result
import gleam/string

/// DateTime represents the type return from Erlang `local_time`.
pub type DateTime =
  #(#(Int, Int, Int), #(Int, Int, Int))

// An external function call to calendar.local_time/0. This is marked as public
// to be able to use from unit tests but is not intended to be used by external
// packages.
// https://www.erlang.org/doc/apps/stdlib/calendar#local_time/0
@external(erlang, "calendar", "local_time")
pub fn now() -> DateTime

/// A representation of a date in time, holding a year, month and day.
pub type Date {
  Date(year: Int, month: Int, day: Int)
}

/// A container for a Personnummer with a date, a serial, a control digit, a
/// separator and a flag to see if it's a coordination number. This type is
/// used to validate if a given Swedish personal number is valid or not among a
/// few other things supported by this library.
pub type Personnummer {
  Personnummer(
    date: Date,
    serial: Int,
    control: option.Option(Int),
    separator: String,
    coordination: Bool,
  )
}

/// If the parsing of a passed st ring is not possible, an error of this type
/// will be returned, saying what went wrong.
pub type PersonnummerError {
  PersonnummerError(
    /// The problem encountered that caused the compilation to fail
    error: String,
  )
}

/// Construct an instance of a Personnummer. A year must be given in either
/// full format with century, or if not 1900 is assumed. The separator can be
/// `-` or `+` (indicating last century, although this will not be considered
/// when parsing. The control digit is optional but if not passed validation
/// will always fail (since that's the digit being validated).
///
/// Example on valid formats:
/// - 19900101-0017
/// - 19190212+1234
/// - 860612-4434
pub fn new(pnr: String) -> Result(Personnummer, PersonnummerError) {
  let assert Ok(re) =
    regex.from_string(
      "^(\\d{2}){0,1}(\\d{2})(\\d{2})(\\d{2})([-+]{0,1})(\\d{3})(\\d{0,1})$",
    )
  case regex.scan(with: re, content: pnr) {
    [] -> Error(PersonnummerError(error: "Invalid format"))
    [x, ..] -> new_from_matches(x)
  }
}

/// Given the passed string matches the regex, we can pretty naively parse the
/// string to integers and create a `Personnummer`. This doesn't consider
/// invalid dates so an object can hold an invalid date.
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
    date: Date(year, month, day % 60),
    serial: maybe_str_to_int(serial, 0),
    control: control,
    separator: option.unwrap(divider, "-"),
    coordination: day % 60 == 60,
  ))
}

/// Format the personnummer to common format. It can either be long (including
/// century) or short (only the year).
pub fn format(pnr: Personnummer, long_format: Bool) -> String {
  let up_to = case long_format {
    True -> 0
    False -> 2
  }

  string.concat([
    pnr.date.year
      |> int.to_string(),
    pnr.date.month
      |> int.to_string()
      |> string.pad_left(to: 2, with: "0"),
    pnr.date.day
      |> int.to_string()
      |> string.pad_left(to: 2, with: "0"),
    pnr.separator,
    pnr.serial
      |> int.to_string()
      |> string.pad_left(to: 3, with: "0"),
    option.unwrap(pnr.control, 0)
      |> int.to_string(),
  ])
  |> string.drop_left(up_to: up_to)
}

/// Check if the personnummer is valid. It's considered valid if the date is a
/// valid date, the serial is > 0 and the checksum passes the luhn algorithm.
pub fn valid(pnr: Personnummer) -> Bool {
  case pnr.control {
    option.None -> False
    option.Some(c) -> {
      let pnr_without_separator =
        format(pnr, False)
        |> string.replace(pnr.separator, "")
      pnr.serial > 0 && valid_date(pnr.date) && luhn(pnr_without_separator) == c
    }
  }
}

/// Check if a date is valid which is mainly checking the number of days in the
/// month and some special leap year checks if the month is February.
fn valid_date(date: Date) -> Bool {
  case date.day >= 1 && date.day <= 31 {
    True ->
      case date.month {
        1 | 3 | 5 | 7 | 8 | 10 | 12 -> True
        4 | 6 | 9 | 11 -> date.day <= 30
        2 ->
          case
            bool.exclusive_or(
              date.year % 400 == 0,
              date.year % 100 != 0 && date.year % 4 == 0,
            )
          {
            True -> date.day <= 29
            False -> date.day <= 28
          }
        _ -> date.day <= 28
      }
    False -> False
  }
}

/// Get the age of the person holding the passed personnummer.
pub fn age(pnr: Personnummer) -> Int {
  let #(#(current_year, current_month, current_day), _) = now()

  case pnr.date.month > current_month {
    True -> current_year - pnr.date.year - 1
    False ->
      case pnr.date.month == current_month && pnr.date.day > current_day {
        True -> current_year - pnr.date.year - 1
        False -> current_year - pnr.date.year
      }
  }
}

/// Check if the personnummer is a coordination number (Samordningsnummer):
/// https://skatteverket.se/privat/folkbokforing/samordningsnummer.4.5c281c7015abecc2e201130b.html
pub fn is_coordination(pnr: Personnummer) -> Bool {
  pnr.coordination
}

/// Returns true if the second to last digit is even which is used for people
/// born as females in Sweden.
pub fn is_female(pnr: Personnummer) -> Bool {
  { pnr.serial % 10 } % 2 == 0
}

/// Returns true if the second to last digit is odd which is used for people
/// born as male in Sweden.
pub fn is_male(pnr: Personnummer) -> Bool {
  !is_female(pnr)
}

/// An implementation of the luhn algorithm:
/// https://en.wikipedia.org/wiki/Luhn_algorithm. This is used in Sweden to
/// determine authenticity of of a personnummer.
fn luhn(digits: String) -> Int {
  10
  - {
    list.zip(
      digits
        |> string.drop_right(up_to: 1)
        |> string.split("")
        |> list.map(fn(n) { result.unwrap(int.base_parse(n, 10), 0) }),
      iterator.from_list([2, 1])
        |> iterator.cycle
        |> iterator.take(string.length(digits))
        |> iterator.to_list(),
    )
    |> list.map(fn(pair) {
      let #(a, b) = pair
      { a * b }
      |> int.to_string()
    })
    |> string.join("")
    |> string.split("")
    |> list.map(fn(n) { result.unwrap(int.base_parse(n, 10), 0) })
    |> int.sum()
  }
  % 10
}

/// A naiv way to convert a string to a digit. The string will unwrap or
/// defaulted to an empty string and if it's not possible to convert the passed
/// default digit will be returned.
///
/// This is safe to do in this code since we only convert digits that we got
/// from our regex submatches that matches on digits.
fn maybe_str_to_int(s: option.Option(String), default: Int) -> Int {
  result.unwrap(int.base_parse(option.unwrap(s, ""), 10), default)
}
