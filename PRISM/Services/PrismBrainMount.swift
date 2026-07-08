import Foundation
import CortexEcosystemBrain

enum PrismBrainMount {
    @discardableResult
    static func ensure(fileManager: FileManager = .default) -> CortexBrainSurfaceAttachment? {
        CortexBrainSurfaceAttacher.attach(.prism, fileManager: fileManager)
    }

    static func memoryFileURL(fileManager: FileManager = .default) -> URL {
        let root = ensure(fileManager: fileManager)?.namespaceURL
            ?? CortexBrainStorageLocator.namespaceRoot("prism", fileManager: fileManager)
        let memoryDir = root.appendingPathComponent("memory", isDirectory: true)
        try? fileManager.createDirectory(at: memoryDir, withIntermediateDirectories: true)
        return memoryDir.appendingPathComponent("conversation-memory.json")
    }
}
