import XCTest
@testable import OllmlxCore

final class ModelStoreTests: XCTestCase {
    func testNonexistentModelIsNotCached() {
        let store = ModelStore.shared
        XCTAssertFalse(store.isModelCached("nonexistent/model-xyz-123"))
    }

    func testRefreshCachedReturnsArray() {
        let store = ModelStore.shared
        let models = store.refreshCached()
        // Should return an array (may be empty if no HF models cached)
        XCTAssertNotNil(models)
    }

    // MARK: - Local Path Detection

    func testIsLocalPathWithAbsolutePath() {
        XCTAssertTrue(ModelStore.isLocalPath("/Users/foo/models/llama"))
    }

    func testIsLocalPathWithTildePath() {
        XCTAssertTrue(ModelStore.isLocalPath("~/models/llama"))
    }

    func testIsLocalPathWithRelativePath() {
        XCTAssertTrue(ModelStore.isLocalPath("./models/llama"))
        XCTAssertTrue(ModelStore.isLocalPath("../models/llama"))
    }

    func testIsLocalPathReturnsFalseForHFRepoID() {
        XCTAssertFalse(ModelStore.isLocalPath("mlx-community/Llama-3.2-3B-Instruct-4bit"))
        XCTAssertFalse(ModelStore.isLocalPath("some-org/some-model"))
    }

    func testExpandPathExpandsTilde() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let expanded = ModelStore.expandPath("~/foo/bar")
        XCTAssertEqual(expanded, "\(home)/foo/bar")
    }

    func testExpandPathLeavesAbsolutePathUnchanged() {
        XCTAssertEqual(ModelStore.expandPath("/usr/local/models/foo"), "/usr/local/models/foo")
    }

    func testExpandPathLeavesHFRepoIDUnchanged() {
        let id = "mlx-community/Llama-3.2-3B"
        XCTAssertEqual(ModelStore.expandPath(id), id)
    }

    func testIsModelCachedReturnsFalseForNonexistentLocalPath() {
        let store = ModelStore.shared
        XCTAssertFalse(store.isModelCached("/tmp/ollmlx-test-nonexistent-model-dir-abc123"))
    }

    func testIsModelCachedReturnsFalseForLocalDirWithoutSafetensors() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ollmlx-test-no-safetensors-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        // Directory exists but has no .safetensors files
        let store = ModelStore.shared
        XCTAssertFalse(store.isModelCached(dir.path))
    }

    func testIsModelCachedReturnsTrueForLocalDirWithSafetensors() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ollmlx-test-with-safetensors-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        // Create a dummy .safetensors file
        let weightsFile = dir.appendingPathComponent("model.safetensors")
        try Data().write(to: weightsFile)

        let store = ModelStore.shared
        XCTAssertTrue(store.isModelCached(dir.path))
    }

    // MARK: - HF Progress Parsing

    func testParseHFProgressWithPercentAndSize() {
        let line = "Downloading model.safetensors: 45%|████      | 1.2G/2.7G [00:30<00:37, 40.5MB/s]"
        let progress = ModelStore.parseHFProgress(line: line, model: "test/model")
        XCTAssertNotNil(progress)
        XCTAssertEqual(progress?.modelID, "test/model")
        XCTAssertTrue(progress!.description.contains("45"))
    }

    func testParseHFProgressWithPercentOnly() {
        let line = "Fetching files: 100%"
        let progress = ModelStore.parseHFProgress(line: line, model: "test/model")
        XCTAssertNotNil(progress)
        XCTAssertTrue(progress!.description.contains("100"))
    }

    func testParseHFProgressReturnsNilForNonProgressLine() {
        let line = "Some random log output without progress"
        let progress = ModelStore.parseHFProgress(line: line, model: "test/model")
        XCTAssertNil(progress)
    }

    // MARK: - Byte Size Parsing

    func testParseByteSize() {
        XCTAssertEqual(ModelStore.parseByteSize("1.5G"), 1_500_000_000)
        XCTAssertEqual(ModelStore.parseByteSize("500M"), 500_000_000)
        XCTAssertEqual(ModelStore.parseByteSize("2.7GB"), 2_700_000_000)
        XCTAssertEqual(ModelStore.parseByteSize("100K"), 100_000)
        XCTAssertEqual(ModelStore.parseByteSize("1024B"), 1024)
    }

    func testFormatBytes() {
        XCTAssertEqual(ModelStore.formatBytes(1_500_000_000), "1.5 GB")
        XCTAssertEqual(ModelStore.formatBytes(500_000_000), "500.0 MB")
        XCTAssertEqual(ModelStore.formatBytes(100_000), "100.0 KB")
    }

    // MARK: - Quantisation Inference

    func testIsModelCachedWithSlashes() {
        // Ensure slashes in repo IDs are properly converted to -- in directory names.
        // Uses a model ID guaranteed not to exist on any development machine.
        let store = ModelStore.shared
        XCTAssertFalse(store.isModelCached("ollmlx-test/nonexistent-model-that-will-never-be-cached-abc123"))
    }
}
