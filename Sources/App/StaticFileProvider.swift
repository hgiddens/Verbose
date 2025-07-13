import Foundation
import Hummingbird
import NIOCore

struct StaticFileProvider: FileProvider {
    let resourceURL: URL = Bundle.module.resourceURL ?? Bundle.module.bundleURL
    private let staticSubdirectory: String = "static"

    struct FileAttributes: FileMiddlewareFileAttributes {
        let isFolder: Bool
        let size: Int
        let modificationDate: Date

        init?(values: URLResourceValues) {
            guard
                let isFolder = values.isDirectory,
                let size = values.fileSize,
                let modificationDate = values.contentModificationDate
            else {
                return nil
            }

            self.isFolder = isFolder
            self.size = size
            self.modificationDate = modificationDate
        }
    }

    typealias FileIdentifier = String

    func getFileIdentifier(_ path: String) -> String? {
        guard path.hasPrefix("/\(staticSubdirectory)/") else {
            return nil
        }

        let staticPath = String(path.dropFirst(1))
        guard !staticPath.contains("..") else {
            return nil
        }

        let fullPath = "\(resourceURL.path)/\(staticPath)"
        let url = URL(fileURLWithPath: fullPath)

        guard url.path.hasPrefix("\(resourceURL.path)/\(staticSubdirectory)/") else {
            return nil
        }

        return fullPath
    }

    func getAttributes(id: String) async throws -> FileAttributes? {
        let url = URL(fileURLWithPath: id)

        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        let resourceValues = try url.resourceValues(forKeys: [
            .isDirectoryKey,
            .fileSizeKey,
            .contentModificationDateKey,
        ])

        return FileAttributes(values: resourceValues)
    }

    func loadFile(id: String, context: some RequestContext) async throws -> ResponseBody {
        let url = URL(fileURLWithPath: id)
        let data = try Data(contentsOf: url)
        return .init(byteBuffer: ByteBuffer(bytes: data))
    }

    func loadFile(id: String, range: ClosedRange<Int>, context: some RequestContext) async throws
        -> ResponseBody
    {
        let url = URL(fileURLWithPath: id)
        let data = try Data(contentsOf: url)

        let startIndex = data.index(data.startIndex, offsetBy: range.lowerBound)
        let endIndex = data.index(data.startIndex, offsetBy: min(range.upperBound, data.count - 1))

        let rangeData = data[startIndex...endIndex]
        return .init(byteBuffer: ByteBuffer(bytes: Data(rangeData)))
    }
}
