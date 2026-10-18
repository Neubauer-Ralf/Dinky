import Testing
@testable import DinkyLayout

private let tiled = WindowPosition(frame: rect(0, 0, 600, 600), spaceID: 7)

struct FailedRestoresTests {
    @Test func `A window still where the failed restore left it was not moved`() {
        var failed = FailedRestores()
        failed.remember(1, at: tiled)
        #expect(!failed.movedByHand(1, now: tiled))
    }

    @Test func `A new frame or another Space counts as moved by hand`() {
        var failed = FailedRestores()
        failed.remember(1, at: tiled)
        #expect(failed.movedByHand(1, now: WindowPosition(frame: rect(50, 0, 600, 600), spaceID: 7)))
        #expect(failed.movedByHand(1, now: WindowPosition(frame: tiled.frame, spaceID: 8)))
    }

    @Test func `A window no restore failed for is never moved by hand`() {
        let failed = FailedRestores()
        #expect(!failed.movedByHand(1, now: tiled))
    }

    @Test func `A later failed attempt replaces where the earlier one left the window`() {
        var failed = FailedRestores()
        failed.remember(1, at: tiled)
        let later = WindowPosition(frame: rect(0, 0, 800, 600), spaceID: 7)
        failed.remember(1, at: later)
        #expect(!failed.movedByHand(1, now: later))
        #expect(failed.movedByHand(1, now: tiled))
    }

    @Test func `Keeping some windows forgets the others, clearing forgets all`() {
        var failed = FailedRestores()
        failed.remember(1, at: tiled)
        failed.remember(2, at: tiled)
        failed.keep([2, 3])
        #expect(failed.ids == [2])
        failed.clear()
        #expect(failed.ids.isEmpty)
    }
}
