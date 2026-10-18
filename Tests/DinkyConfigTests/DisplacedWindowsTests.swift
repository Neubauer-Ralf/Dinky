import Testing
@testable import DinkyConfig

struct DisplacedWindowsTests {
    @Test func `Nothing to do without a display change`() {
        var displaced = DisplacedWindows()
        #expect(displaced.arranged(enabled: true, completed: true) == .nothing)
        #expect(!displaced.pending)
    }

    @Test func `A completed arrangement returns them`() {
        var displaced = DisplacedWindows()
        displaced.displaysChanged()
        #expect(displaced.pending)
        #expect(displaced.arranged(enabled: true, completed: true) == .returnThem)
        #expect(!displaced.pending)
        #expect(displaced.arranged(enabled: true, completed: true) == .nothing, "a later arrangement returns nothing")
    }

    @Test func `An arrangement that stopped short leaves them`() {
        var displaced = DisplacedWindows()
        displaced.displaysChanged()
        #expect(displaced.arranged(enabled: true, completed: false) == .leaveThem)
        #expect(!displaced.pending)
    }

    @Test func `A display change while disabled is forgotten`() {
        var displaced = DisplacedWindows()
        displaced.displaysChanged()
        #expect(displaced.arranged(enabled: false, completed: false) == .leaveThem)
        #expect(!displaced.pending, "homes are noted again, so enabling later returns nothing")
        #expect(displaced.arranged(enabled: true, completed: true) == .nothing)
    }
}
