@testable import SampleApp

struct MockCategoryService: CategoryService {
    let result: [String]
    let error: Error?

    init(result: [String] = ["beauty", "electronics"], error: Error? = nil) {
        self.result = result
        self.error = error
    }

    func fetch() async throws -> [String] {
        if let error { throw error }
        return result
    }
}
