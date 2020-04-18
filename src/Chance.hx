class Chance {
  var state:UInt;

  public function new(seed:Int) {
    state = seed;
  }

  public function next():UInt {
    state ^= state << 13;
    state ^= state >> 17;
    state ^= state << 5;
    return state;
  }

  public function mod(n:Int):Int {
    return next() % n;
  }

  public function float(?mul:Float = 1):Float {
    return (next() % 0x1000000) / 0xFFFFFF * mul;
  }

  public function rangeI(min:Int, max:Int):Int {
    return min + mod(max + 1 - min);
  }

  public function rangeF(min:Float, max:Float):Float {
    return min + float(max - min);
  }

  public function bool():Bool {
    return next() % 2 == 0;
  }

  public function member<T>(arr:Array<T>):T {
    return arr[mod(arr.length)];
  }

  public function sign():Int {
    return bool() ? 1 : -1;
  }
}
