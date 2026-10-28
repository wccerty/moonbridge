///|
extern "C" fn exit_process(status : Int32) -> Unit = "exit"

///|
fn[T] fail(message : String) -> T {
  println("moonbridge: \{message}")
  exit_process(1)
  abort(message)
}

///|
async fn main {
  match @cli.run(@env.args()) {
    Ok(_) => ()
    Err(error) => fail(error)
  }
}
