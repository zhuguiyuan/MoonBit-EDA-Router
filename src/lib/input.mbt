///|
/// A simple string to ints input source
struct Input {
  buffer : String
  mut pos : Int
  mut error : Bool
  mut eof : Bool
}

///|
/// Construct an input source from string
pub fn Input::from_string(s : String) -> Input {
  { buffer: s, pos: 0, error: false, eof: s.length() == 0 }
}

///|
/// Peak a char from the input source without consuming it
pub fn Input::peak(self : Input) -> Char? {
  if self.eof || self.error {
    return None
  }
  Some(self.buffer[self.pos])
}

///|
/// Take a char form the input source
pub fn Input::consume(self : Input) -> Char? {
  if self.eof || self.error {
    return None
  }
  self.pos = self.pos + 1
  if self.pos >= self.buffer.length() {
    self.eof = true
  }
  Some(self.buffer[self.pos - 1])
}

///|
/// Whether a char is a whitespace
pub fn is_whitesapce(c : Char) -> Bool {
  c == ' ' || c == '\n' || c == '\t'
}

///|
/// Whether a char is a digit
pub fn is_digit(c : Char) -> Bool {
  c >= '0' && c <= '9'
}

///|
/// Get an int from the input source
pub fn Input::next_int(self : Input) -> Int? {
  let buffer = []
  let mut sign = 1
  fn fill_buffer() -> Unit {
    for {
      match self.peak() {
        Some(c) =>
          if is_digit(c) {
            buffer.push(self.consume().unwrap())
          } else {
            return
          }
        None => return
      }
    }
  }

  while not(self.eof || self.error) {
    let curr = self.peak().unwrap()
    if is_whitesapce(curr) {
      ignore(self.consume())
      continue
    } else if is_digit(curr) || curr == '-' || curr == '+' {
      if curr == '+' || curr == '-' {
        ignore(self.consume())
      }
      if curr == '-' {
        sign = -1
      }
      fill_buffer()
      break
    } else {
      self.error = true
      break
    }
  }
  if buffer.length() == 0 {
    self.error = true
    None
  } else {
    Some(sign * str_to_int(String::from_array(buffer)))
  }
}

test "input_ints" {
  let input = Input::from_string("  12  3 21 \n 21 3  ")
  inspect!(input.next_int(), content="Some(12)")
  inspect!(input.next_int(), content="Some(3)")
  inspect!(input.next_int(), content="Some(21)")
  inspect!(input.next_int(), content="Some(21)")
  inspect!(input.next_int(), content="Some(3)")
  inspect!(input.next_int(), content="None")
  inspect!(input.next_int(), content="None")
}

test "input_neg" {
  let input = Input::from_string(" -12  +3 -21 --21 3 ")
  inspect!(input.next_int(), content="Some(-12)")
  inspect!(input.next_int(), content="Some(3)")
  inspect!(input.next_int(), content="Some(-21)")
  inspect!(input.next_int(), content="None")
  inspect!(input.next_int(), content="None")
  inspect!(input.next_int(), content="None")
  inspect!(input.next_int(), content="None")
}

test "input_error" {
  let input = Input::from_string("1 6asjdk 0")
  inspect!(input.next_int(), content="Some(1)")
  inspect!(input.next_int(), content="Some(6)")
  inspect!(input.next_int(), content="None")
  inspect!(input.next_int(), content="None")
}

///|
/// Convert a string to int.
fn str_to_int(s : String) -> Int {
  let mut num : Int = 0
  let mut sign : Int = 1
  let mut i : Int = 0
  if s[0] == '-' {
    sign = -1
    i = 1
  } else if s[0] == '+' {
    i = 1
  }
  for j in i.until(s.length()) {
    if s[j] >= '0' && s[j] <= '9' {
      num = num * 10 + (s[j].to_int() - '0'.to_int())
    } else {
      break
    }
  }
  num * sign
}

test "str_to_int" {
  inspect!(str_to_int("0"), content="0")
  inspect!(str_to_int("14"), content="14")
  inspect!(str_to_int("-42"), content="-42")
}
