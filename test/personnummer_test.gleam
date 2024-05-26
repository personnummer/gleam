import gleam/int
import gleam/list
import gleam/string
import gleeunit
import gleeunit/should
import personnummer

pub fn main() {
  gleeunit.main()
}

pub fn valid_personnummer_test() {
  [
    "19900101-0017", "196408233234", "000101-0107", "510818-9167",
    "19130401+2931",
  ]
  |> list.map(fn(pnr_str) {
    let assert Ok(pnr) = personnummer.new(pnr_str)

    should.be_true(
      pnr
      |> personnummer.valid(),
    )
  })
}

pub fn invalid_date_test() {
  ["19901301-1111", "20240229-1111"]
  |> list.map(fn(pnr_str) {
    let assert Ok(pnr) = personnummer.new(pnr_str)

    should.be_false(
      pnr
      |> personnummer.valid(),
    )
  })
}

pub fn invalid_luhn_test() {
  ["19900101-1111", "20160229-1111", "6403273814", "20150916-0006"]
  |> list.map(fn(pnr_str) {
    let assert Ok(pnr) = personnummer.new(pnr_str)

    should.be_false(
      pnr
      |> personnummer.valid(),
    )
  })
}

pub fn gender_test() {
  [
    #("19090903-6600", True),
    #("19900101-0017", False),
    #("800101-3294", False),
    #("000903-6609", True),
    #("800101+3294", False),
  ]
  |> list.map(fn(tc) {
    let #(pnr_str, expect_is_female) = tc
    let assert Ok(pnr) = personnummer.new(pnr_str)

    should.equal(
      pnr
        |> personnummer.is_female(),
      expect_is_female,
    )
  })
}

pub fn age_test() {
  let #(#(current_year, current_month, current_day), _) = personnummer.now()
  let forty_years_ago = { current_year - 40 } % 1900

  let #(y1, m1, d1) = case current_month > 1 {
    True -> #(forty_years_ago, current_month - 1, current_day)
    False -> #(forty_years_ago - 1, 12, 31)
  }

  let #(y2, m2, d2) = case current_month < 12 {
    True -> #(forty_years_ago, current_month + 1, current_day)
    False -> #(forty_years_ago + 1, 1, 1)
  }

  let assert Ok(forty) =
    string.concat([
      int.to_string(y1),
      int.to_string(m1)
        |> string.pad_left(to: 2, with: "0"),
      int.to_string(d1)
        |> string.pad_left(to: 2, with: "0"),
      "0000",
    ])
    |> personnummer.new()

  let assert Ok(forty_one) =
    string.concat([
      int.to_string(forty_years_ago - 1),
      int.to_string(current_month)
        |> string.pad_left(to: 2, with: "0"),
      int.to_string(current_day)
        |> string.pad_left(to: 2, with: "0"),
      "0000",
    ])
    |> personnummer.new()

  let assert Ok(thirty_nine) =
    string.concat([
      int.to_string(y2),
      int.to_string(m2)
        |> string.pad_left(to: 2, with: "0"),
      int.to_string(d2)
        |> string.pad_left(to: 2, with: "0"),
      "0000",
    ])
    |> personnummer.new()

  should.equal(
    forty
      |> personnummer.age(),
    40,
  )

  should.equal(
    forty_one
      |> personnummer.age(),
    41,
  )

  should.equal(
    thirty_nine
      |> personnummer.age(),
    39,
  )
}
