pub fn hello_world() -> String {
  "Hello, from gleam_personnummer!"
}

pub type Date {
  Date(
    year: Int,
    month: Int,
    day: Int,
  )
}

pub type Personnummer {
  Personnummer(
    date: Date,
    serial: Int,
    control: Int,
    separator: String,
    coordination: Bool,
  )
}

pub fn new(pnr_string) {
  let pnr = Personnummer(
    date: Date(1, 1, 1),
    serial: 1,
    control: 1,
    separator: "-",
    coordination: False,
  )

  pnr
}
