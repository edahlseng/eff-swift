import Foundation
import utils

// TODO: If Swift support GADTs, then this could be much more cleanly written?

public class Eff<Value> {
	// The below are needed to work around the fact that generics in Swift are invarint
	// TODO
	func next(_ x: Any) -> Eff<Value> {
        fatalError("Subclasses need to implement the `next()` method.")
    }

	func getEffect() -> Any {
		fatalError("Subclasses need to implement the `getEffect()` method.")
	}
}

public class pure<A>: Eff<A> {
	public let value: A

	override func next(_: Any) -> Eff<A> {
		return pure(value)
	}

	override func getEffect() -> Any {
		return 0 // dummy value
	}

	public init(_ v: A) {
		value = v
	}
}

// TODO: improve names over A, B, C
public class impure<A, B>: Eff<A> {
	let effect: Any
	let continuation: (B) -> Eff<A>

	override func next(_ x: Any) -> Eff<A> {
		guard let xOfType = x as? B else {
			fatalError("wrong type. Expected \(x) to be \(B.self)") // TODO: does this mean an interpreter error? If so, let's mention that, to make debugging easier
		}
		return continuation(xOfType)
	}

	override func getEffect() -> Any {
		return effect
	}

	init(effect e: Any, continuation c: @escaping (B) -> Eff<A>) {
		effect = e
		continuation = c
	}
}

// -----------------------------------------------------------------------------
// Chain
// -----------------------------------------------------------------------------

// TODO: curry this function
public func chain<A, B>(_ effectfulMonad: Eff<A>, _ nextContinuation: @escaping (A) -> Eff<B>) -> Eff<B> {
	if let pureEffectfulMonad = effectfulMonad as? pure<A> {
		return nextContinuation(pureEffectfulMonad.value)
	}

	// if let impureEffectfulMonad = effectfulMonad as? impure<A, Any> {
		return impure(effect: effectfulMonad.getEffect(), continuation: { (x:Any) in chain(effectfulMonad.next(x), nextContinuation) } )
	// }
}

extension Eff {
	public func chain<B>(_ nextContinuation: @escaping (Value) -> Eff<B>) -> Eff<B> {
		return eff.chain(self, nextContinuation);
	}
}

public func >=> <A, B, C>(_ leftHandSide: @escaping (A) -> Eff<B>, _ rightHandSide: @escaping (B) -> Eff<C>) -> (A) -> Eff<C> {
  return { a in
	  chain(leftHandSide(a), rightHandSide)
  }
}

// -----------------------------------------------------------------------------
// Chain
// -----------------------------------------------------------------------------

public func map<A, B>(_ f: @escaping (A) -> B) -> (Eff<A>) -> Eff<B> {
	return { effectfulMonad in
		chain(effectfulMonad, { a in pure(f(a)) })
	}
}

// -----------------------------------------------------------------------------
// Interpret & Run
// -----------------------------------------------------------------------------

public typealias Handler = (Any) -> (((Any) -> Void) -> Void)?

public func run<A>(_ handlers: [Handler]) -> (@escaping (A) -> Void) -> (Eff<A>) -> Void {
	func interpret<A>(_ index: Int, _ callback: @escaping (A) -> Void) -> (Eff<A>) -> Void {
		return { effectfulMonad in // Guaranteed to be an Eff<A> here because the chain operations don't change the <A> part
			if let pureEffectfulMonad = effectfulMonad as? pure<A> {
				return callback(pureEffectfulMonad.value)
			}

			if index >= handlers.count {
				fatalError("Encountered an unhandled effect: \(effectfulMonad.getEffect())")
			}

			guard let computedHandler = handlers[index](effectfulMonad.getEffect()) else {
				return interpret(index + 1, callback)(effectfulMonad)
			}

			return computedHandler({ x in interpret(0, callback)(effectfulMonad.next(x)) })
		}
	}

	return { callback in
		interpret(0, callback) //as (Eff<A>) -> Void
	}
}

// TODO; Using effect protocol until we can specify generics directly in swift (link to tracker)
// TODO: should be able te romev thunk from continuation definition
public func send<A, Effect> (_ effect: Effect) -> impure<A, A> {
	return impure(effect: effect, continuation: { (a: A) in pure.init(a)})
}
