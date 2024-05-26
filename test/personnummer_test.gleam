import gleam/list
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
