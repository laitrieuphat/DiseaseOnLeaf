// MARK: - Helper to read TensorFlow output

import Foundation


extension Array {
    /// Initializes an array from a Data object, assuming the data contains elements of type `Element`.
    init?(unsafeData: Data) {
        guard unsafeData.count % MemoryLayout<Element>.stride == 0 else { return nil }
        self = unsafeData.withUnsafeBytes { ptr in
            return [Element](
                UnsafeBufferPointer<Element>(
                    start: ptr.baseAddress!.assumingMemoryBound(to: Element.self),
                    count: unsafeData.count / MemoryLayout<Element>.stride
                )
            )
        }
    }
}

extension Array where Element == Float {
    /// Returns the top K results as an array of tuples (index, score), sorted by score descending.
    func topK(k: Int) -> [(index: Int, score: Float)] {
        let enumerated = self.enumerated()
        // Sort by score (element) descending
        let sorted = enumerated.sorted { $0.element > $1.element }
        // Take the top K elements
        return sorted.prefix(k).map { (index: $0.offset, score: $0.element) }
    }
}

