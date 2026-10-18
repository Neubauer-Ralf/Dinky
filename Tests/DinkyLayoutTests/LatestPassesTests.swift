import Testing
@testable import DinkyLayout

struct LatestPassesTests {
    @Test func `A pass is current until a newer one includes one of its windows`() {
        let passes = LatestPasses()
        let first = passes.begin([1, 2])
        #expect(passes.isLatest(first, for: [1, 2]))
        let second = passes.begin([3])
        #expect(passes.isLatest(first, for: [1, 2]), "a pass over other windows changes nothing")
        let third = passes.begin([2, 3])
        #expect(!passes.isLatest(first, for: [1, 2]))
        #expect(!passes.isLatest(second, for: [3]))
        #expect(passes.isLatest(third, for: [2, 3]))
    }

    @Test func `A forgotten window no longer makes older passes stale`() {
        let passes = LatestPasses()
        let first = passes.begin([1])
        _ = passes.begin([1])
        passes.forget(1)
        #expect(passes.isLatest(first, for: [1]))
    }
}
