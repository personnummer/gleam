# personnummer

[![Package Version](https://img.shields.io/hexpm/v/personnummer)](https://hex.pm/packages/personnummer)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/personnummer/)

```sh
gleam add personnummer
```

```gleam
import personnummer

pub fn main() {
  let assert Ok(pnr) = personnummer.new("19900101-0017")
  io.debug(
    [
      "The person with personal identity number ",
      pnr
        |> personnummer.format(True),
      " is a ",
      case
        pnr
        |> personnummer.is_male()
      {
        True -> "male"
        False -> "female"
      },
      " of age ",
      pnr
        |> personnummer.age
        |> int.to_string(),
    ]
    |> string.concat,
  )
}
```

```sh
"The person with personal identity number 19900101-0017 is a male of age 34"
```

Further documentation can be found at <https://hexdocs.pm/personnummer>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
gleam shell # Run an Erlang shell
```
