import Foundation
import Testing
@testable import Bitely

@Suite("Formatting")
struct FormattingTests {

    @Test("dayKey formats a date as yyyy-MM-dd")
    func dayKeyFormat() throws {
        var components = DateComponents()
        components.year = 2026
        components.month = 3
        components.day = 14
        components.hour = 12
        let date = try #require(Calendar.current.date(from: components))

        #expect(date.dayKey == "2026-03-14")
    }

    @Test("dayKey zero-pads single-digit months and days")
    func dayKeyPadding() throws {
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 5
        components.hour = 12
        let date = try #require(Calendar.current.date(from: components))

        #expect(date.dayKey == "2026-01-05")
    }

    @Test("dayKey is stable across times of day")
    func dayKeyIgnoresTime() throws {
        var morning = DateComponents()
        morning.year = 2026
        morning.month = 7
        morning.day = 2
        morning.hour = 0
        morning.minute = 1

        var evening = morning
        evening.hour = 23
        evening.minute = 59

        let start = try #require(Calendar.current.date(from: morning))
        let end = try #require(Calendar.current.date(from: evening))

        #expect(start.dayKey == end.dayKey)
        #expect(start.dayKey == "2026-07-02")
    }

    @Test("trimTrailingZeros drops the decimal part of a whole number")
    func trimsWholeNumbers() {
        #expect(2.0.trimTrailingZeros() == "2")
        #expect(12.0.trimTrailingZeros() == "12")
        #expect(0.0.trimTrailingZeros() == "0")
    }

    @Test("trimTrailingZeros keeps a single fractional digit")
    func keepsOneFractionDigit() {
        #expect(1.5.trimTrailingZeros() == "1.5")
        #expect(0.5.trimTrailingZeros() == "0.5")
    }

    @Test("trimTrailingZeros rounds to one fractional digit")
    func roundsToOneDigit() {
        #expect(1.26.trimTrailingZeros() == "1.3")
        #expect(2.04.trimTrailingZeros() == "2")
    }
}
