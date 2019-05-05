public func combine<A>(_ effs: [Eff<A>]) -> Eff<[A]> {
	guard effs.count > 0 else {
		return pure([])
	}

	var results = Array<A>()
	var effChain = effs[0]

	for i in 1..<effs.count {
		effChain = effChain.chain({ nextResult in
			results.append(nextResult)
			return effs[i]
		})
	}

	return effChain.chain({ lastResult in
		results.append(lastResult)
		return pure(results)
	})
}

public func combine<A, B>(_ effs: (Eff<A>, Eff<B>)) -> Eff<(A, B)> {
	return effs.0.chain({ resultA in
		effs.1.chain({ resultB in pure((resultA, resultB))})
	})
}
