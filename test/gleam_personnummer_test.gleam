import gleam_personnummer
import gleam/should

pub fn hello_world_test() {
  gleam_personnummer.hello_world()
  |> should.equal("Hello, from gleam_personnummer!")
}
