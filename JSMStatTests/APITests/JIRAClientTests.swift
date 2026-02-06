import XCTest
@testable import JSMStat

final class JIRAClientTests: XCTestCase {

    func testEndpointURLConstruction() throws {
        let base = URL(string: "https://test.atlassian.net")!

        let serviceDesksURL = try JIRAEndpoints.serviceDesks(baseURL: base)
        XCTAssertEqual(serviceDesksURL.absoluteString, "https://test.atlassian.net/rest/servicedeskapi/servicedesk")

        let searchURL = try JIRAEndpoints.searchJQL(baseURL: base)
        XCTAssertEqual(searchURL.absoluteString, "https://test.atlassian.net/rest/api/3/search/jql")

        let statusesURL = try JIRAEndpoints.statuses(baseURL: base)
        XCTAssertEqual(statusesURL.absoluteString, "https://test.atlassian.net/rest/api/3/statuses/search")

        let prioritiesURL = try JIRAEndpoints.priorities(baseURL: base)
        XCTAssertEqual(prioritiesURL.absoluteString, "https://test.atlassian.net/rest/api/3/priority")
    }

    func testSearchURLWithParameters() throws {
        let base = URL(string: "https://test.atlassian.net")!
        let url = try JIRAEndpoints.searchURL(
            baseURL: base,
            jql: "project = TEST",
            startAt: 0,
            maxResults: 50,
            fields: ["summary", "status"]
        )

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        let queryItems = components.queryItems ?? []

        XCTAssertTrue(queryItems.contains(where: { $0.name == "jql" && $0.value == "project = TEST" }))
        XCTAssertTrue(queryItems.contains(where: { $0.name == "startAt" && $0.value == "0" }))
        XCTAssertTrue(queryItems.contains(where: { $0.name == "maxResults" && $0.value == "50" }))
        XCTAssertTrue(queryItems.contains(where: { $0.name == "fields" && $0.value == "summary,status" }))
    }

    func testConnectionConfigBaseURL() {
        let config = ConnectionConfig(
            siteURL: "https://mysite.atlassian.net/",
            email: "test@example.com",
            apiToken: "token123"
        )

        XCTAssertEqual(config.baseURL?.absoluteString, "https://mysite.atlassian.net")
    }

    func testConnectionConfigAutoHTTPS() {
        let config = ConnectionConfig(
            siteURL: "mysite.atlassian.net",
            email: "test@example.com",
            apiToken: "token123"
        )

        XCTAssertEqual(config.baseURL?.absoluteString, "https://mysite.atlassian.net")
    }
}
