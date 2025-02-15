import XCTest
@testable import TestApp
import Apollo
import ApolloTestSupport

final class TestAppTests: XCTestCase {
  func testCacheKeyResolution() throws {
    let store = ApolloStore()
    
    let response = GraphQLResponse(
      operation: AnimalKingdomAPI.DogQuery(),
      body: ["data": [
        "allAnimals": [
          [
            "__typename": "Dog",
            "id": "1",
            "skinCovering": "Fur",
            "species": "Canine",
          ]
        ]
      ]])
    
    let (_, records) = try response.parseResult()
    
    let expectation = expectation(description: "Publish Record then Fetch")
    
    store.publish(records: records!) { _ in
      store.withinReadTransaction { transaction in
        let dog = try! transaction.readObject(
          ofType: AnimalKingdomAPI.DogQuery.Data.AllAnimal.self,
          withKey: "Dog:1")
        
        XCTAssertEqual(dog.id, "1")
        expectation.fulfill()
      }
    }
    
    waitForExpectations(timeout: 1.0)
  }
  
  func test_mockObject_initialization() throws {
    // given
    let mockDog: Mock<Dog> = Mock(id: "100")
    
    // then
    XCTAssertEqual(mockDog.id, "100")
  }
}

class MockNetworkTransport: NetworkTransport {
  func send<Operation>(
    operation: Operation,
    cachePolicy: CachePolicy,
    contextIdentifier: UUID?,
    callbackQueue: DispatchQueue,
    completionHandler: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void
  ) -> Cancellable where Operation : GraphQLOperation {
    return EmptyCancellable()
  }
  var clientName: String { "Mock" }
  var clientVersion: String { "Mock" }
}
