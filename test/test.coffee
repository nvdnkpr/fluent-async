should = require "should"
assert = require "assert"
{ok, equal} = assert
_ = require "underscore"
fluent = require "../lib"

describe "parses options", ->
  it "throws an error if nothing added", ->
    ( -> fluent.create().add()).should.throw()

  it "throws an error if only name provided", ->
    ( -> fluent.create().add("name")).should.throw()

  it "throws an error if only function provided", ->
    ( -> fluent.create().add(->)).should.throw()

  it "throws an error if wrong arguments provided", ->
    ( -> fluent.create().add((->), "name")).should.throw()
    ( -> fluent.create().add("name", [1])).should.throw()

  it "doesn't throw an error if correct arguments provided", ->
    ( -> fluent.create().add( "name", (->))).should.not.throw()

  it "handles the optional dependancies", ->
    ( -> fluent.create().add( "name",  (->), [1,2,3])).should.not.throw()

  it "handles single object argument", ->
    ( -> fluent.create().add( "name": ->)).should.not.throw()

describe "works with data", ->
  it "correctly passes initial data as dependency", (done) ->
    test2 = (num, cb) ->
      cb.should.be.a.Function
      num.should.equal(123)
      cb()
    fluent.create({test:123})
      .add("test2", test2, "test")
      .run(done)

  it "correctly passes initial data as dependency when first arg is object", (done) ->
    test2 = (num, cb) ->
      cb.should.be.a.Function
      num.should.equal(123)
      cb()
    fluent.create({test:123})
    .add({test2}, "test")
    .run(done)

  it "correctly passes initial data as dependency when second arg is an array", (done) ->
    test2 = (num, cb) ->
      cb.should.be.a.Function
      num.should.equal(123)
      cb()
    fluent.create({test:123})
    .add({test2}, ["test"])
    .run(done)

  it "accepts data via data method", (done) ->
    test2 = (num, cb) ->
      cb.should.be.a.Function
      num.should.equal(123)
      cb()
    fluent.create()
      .data("test", 123)
      .add({test2}, "test")
      .run(done)

  it "doesn't matter the order of calling", (done) ->
    test2 = (num, cb) ->
      cb.should.be.a.Function
      num.should.equal(123)
      cb()
    fluent.create()
      .add({test2},"test")
      .data("test", 123)
      .run(done)

  it "can use then instead of add", (done) ->
    test2 = (num, cb) ->
      cb.should.be.a.Function
      num.should.equal(123)
      cb()
    fluent.create()
    .then({test2},"test")
    .data("test", 123)
    .run(done)

  it "works with multiple data properties", (done) ->
    test3 = (num, num2, cb) ->
      cb.should.be.a.Function
      num.should.equal(123)
      num2.should.equal(456)
      cb()
    fluent.create()
    .data("test", 123)
    .data("test2", 456)
    .add({test3},"test", "test2")
    .run(done)


describe "callback safety", ->
  it "ensures callbacks can only be called once", (done) ->
    test2 = (num, cb) ->
      cb.should.be.a.Function
      num.should.equal(123)
      ( -> cb()).should.not.throw()
      ( -> cb()).should.throw()
    fluent.create()
      .add({test2},"test")
      .data("test", 123)
      .run(done)

describe "can specify outputs", ->
  it "get single output from data", (done) ->
    fn = (err, number) ->
      number.should.equal(2)
      done(err)
    fluent.create({a:1, b:2})
      .run(fn, "b")

  it "get single output from fns", (done) ->
    b = (cb) -> cb(null, 3)

    fn = (err, number) ->
      number.should.equal(3)
      done(err)
    fluent.create()
      .add({b})
      .run(fn, "b")

describe "can generate async functions", ->
  it "generates an async function that is called once", (done) ->
    b = (cb) -> cb(null, 3)

    fn = fluent.create()
      .add({b})
      .generate("b","string")

    fn {string:"test"}, (err, number, string) ->
      number.should.equal(3)
      string.should.equal("test")
      done(err)

  it "generates an async function that is called multiple times", (done) ->
    b = (cb) ->
      setTimeout ->
        cb(null, 3)
      , 1

    fn = fluent.create()
    .add({b})
    .generate("b","string")

    fn {string:"test"}, (err, number, string) ->
      number.should.equal(3)
      string.should.equal("test")
    fn {string:"test2"}, (err, number, string) ->
      number.should.equal(3)
      string.should.equal("test2")
    fn {string:"test3"}, (err, number, string) ->
      number.should.equal(3)
      string.should.equal("test3")
      done()

  it "generates an async function whose options can't be tampered with", (done) ->
    b = (cb) ->
      setTimeout ->
        cb(null, 3)
      , 1

    instance = fluent.create().add({b})

    fn = instance.generate("b","string")

    fn {string:"test"}, (err, number, string) ->
      number.should.equal(3)
      string.should.equal("test")

    ok _.isFunction instance.opts.b
    instance.opts.b = 5
    ok _.isNumber instance.opts.b

    fn {string:"test2"}, (err, number, string) ->
      number.should.equal(3)
      string.should.equal("test2")
    fn {string:"test3"}, (err, number, string) ->
      number.should.equal(3)
      string.should.equal("test3")
      done()

  it "generates an async function which doesn't keep stale data", (done) ->
    b = (cb) ->
      setTimeout ->
        cb(null, 3)
      , 1

    instance = fluent.create().add({b})

    fn = instance.generate("b","string")

    fn {string:"test"}, (err, number, string) ->
      number.should.equal(3)
      string.should.equal("test")

    fn (err, number, string) ->
      number.should.equal(3)
      ok not string
    fn {string:"test3"}, (err, number, string) ->
      number.should.equal(3)
      string.should.equal("test3")
      done()


  it "generates an async function with no initial data", (done) ->
    b = (cb) -> cb(null, 3)

    fn = fluent.create()
    .add({b})
    .generate()

    fn done

  it "generates an async function with no initial data that receives results object", (done) ->
    b = (cb) -> cb(null, 3)

    fn = fluent.create()
    .add({b})
    .generate()

    fn (err, res) ->
      res.b.should.equal 3
      done(err)

describe "has a strict mode", ->
  it "throws an error when there is a missing dependency", (done) ->
    b = (cb) -> cb(null, 3)

    cb = (err) ->
      err.should.be.a.Error
      done()

    fluent.create()
      .strict()
      .add({b})
      .run(cb, "c")

  it "only throws an error in strict mode", (done) ->
    b = (cb) -> cb(null, 3)

    cb = (err) ->
      ok not err
      done()

    fluent.create()
    .add({b})
    .run(cb, "c")

  it "throws an error when there is a missing dependency on one of the functions", (done) ->
    notCalled = true
    b = (a, cb) ->
      notCalled = false
      cb(null, 3)

    cb = (err) ->
      err.should.be.a.Error
      ok notCalled
      done()

    fluent.create({a:null})
      .strict()
      .add({b}, "a")
      .run(cb)

  it "handles false values", (done) ->
    notCalled = true
    b = (a, cb) ->
      notCalled = false
      cb(null, 3)

    cb = (err) ->
      ok not notCalled
      done(err)

    fluent.create({a:false})
      .strict()
      .add({b}, "a")
      .run(cb)


  it "handles incomplete deps", (done) ->
    notCalled = true
    b = (a, d, cb) ->
      notCalled = false
      cb(null, 3)

    cb = (err) ->
      ok notCalled
      err.should.be.a.Error
      done()

    fluent.create()
      .strict()
      .add({b}, "a", "d")
      .run(cb)
