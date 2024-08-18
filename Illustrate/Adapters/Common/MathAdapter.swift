import Foundation

func roundToTwoDecimalPlaces(_ value: CGFloat) -> CGFloat {
    let formattedString = String(format: "%.2f", value)
    return CGFloat(Double(formattedString) ?? 0.0)
}

func gcd(_ a: Int, _ b: Int) -> Int {
    var a = a
    var b = b
    while b != 0 {
        let temp = b
        b = a % b
        a = temp
    }
    return a
}
