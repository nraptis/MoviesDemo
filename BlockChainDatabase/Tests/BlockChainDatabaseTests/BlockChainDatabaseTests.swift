import XCTest
@testable import BlockChainDatabase
@testable import BlockChainNetworking

final class BlockChainDatabaseTests: XCTestCase {
    
    typealias NWMovie = BlockChainNetworking.NWMovie
    
    func testSyncOneMovie() async {
        
        let dummyMovie = NWMovie(id: 100,
                                 poster_path: "www.fake.com",
                                 release_date: "1999",
                                 title: "International Crisis 1000",
                                 vote_average: 99.9,
                                 vote_count: 100_000_000)
        
        let database = DBDatabaseController()
        await database.loadPersistentStores()
        
        do {
            try await database.magnetize()
            
            try await database.sync(nwMovies: [dummyMovie])
            let fetched = try await database.fetchMovies()
            
            guard fetched.count > 0 else {
                XCTFail("🚫 [testSyncOneMovie] test failed: zero results from database")
                return
            }
            
            let first = fetched[0]
            guard Int(first.id) == 100 else {
                XCTFail("🚫 [testSyncOneMovie] test failed: wrong id")
                return
            }
            
            print("✅ [testSyncOneMovie] test successful!")
            
        } catch {
            XCTFail("🚫 [testSyncOneMovie] test failed: \(error.localizedDescription)")
        }
    }
    
}
