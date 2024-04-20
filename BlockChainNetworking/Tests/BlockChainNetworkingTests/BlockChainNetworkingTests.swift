import XCTest
@testable import BlockChainNetworking

final class BlockChainNetworkingTests: XCTestCase {
    
    func testFetchPopularMovies() async {
        do {
            let nwMovies = try await NWNetworkController.fetchPopularMovies(page: 1)
            if nwMovies.results.count > 0 {
                print("✅ [testFetchPopularMovies] test successful!")
            } else {
                XCTFail("🚫 [testFetchPopularMovies] test failed: no items fetched. [this test requires a network connection]")
            }
        } catch {
            XCTFail("🚫 [testFetchPopularMovies] test failed: \(error.localizedDescription) [this test requires a network connection]")
        }
    }
    
    func testFetchMovieDetails() async {
        do {
            let nwMovieDetails = try await NWNetworkController.fetchMovieDetails(id: 200)
            print("✅ [testFetchMovieDetails] test successful!")
        } catch {
            XCTFail("🚫 [testFetchMovieDetails] test failed: \(error.localizedDescription) [this test requires a network connection]")
        }
    }
    
    // This isn't a particularly meaningful test.
    // If there was business logic, we could test it
    // on these test items... This is more to illustrate
    // the concept of mock delegate...
    func testFetchPopularMoviesMockDelegate() async {
        
        do {
            let nwMovies = try await NWMockNetworkController.fetchPopularMovies(page: 1)
            if nwMovies.results.count > 0 {
                print("✅ [testFetchPopularMoviesMockDelegate] test successful!")
            } else {
                XCTFail("🚫 [testFetchPopularMoviesMockDelegate] test failed: no items fetched.")
            }
        } catch {
            XCTFail("🚫 [testFetchPopularMoviesMockDelegate] test failed: \(error.localizedDescription)")
        }
    }
    
    // This isn't a particularly meaningful test.
    // If there was business logic, we could test it
    // on these test items... This is more to illustrate
    // the concept of mock delegate...
    func testFetchMovieDetailsMockDelegate() async {
        do {
            let nwMovieDetails = try await NWMockNetworkController.fetchMovieDetails(id: 200)
            print("✅ [testFetchMovieDetailsMockDelegate] test successful!")
        } catch {
            XCTFail("🚫 [testFetchMovieDetailsMockDelegate] test failed: \(error.localizedDescription)")
        }
    }
    
}
