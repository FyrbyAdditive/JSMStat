import XCTest
@testable import JSMStat

final class DecodingTests: XCTestCase {

    func testDecodeServiceDesk() throws {
        let json = """
        {
            "id": "1",
            "projectId": "10001",
            "projectName": "IT Help Desk",
            "projectKey": "ITHD"
        }
        """.data(using: .utf8)!

        let desk = try JSONDecoder().decode(ServiceDesk.self, from: json)
        XCTAssertEqual(desk.id, "1")
        XCTAssertEqual(desk.projectKey, "ITHD")
        XCTAssertEqual(desk.projectName, "IT Help Desk")
    }

    func testDecodeIssue() throws {
        let json = """
        {
            "id": "10042",
            "key": "ITHD-42",
            "fields": {
                "summary": "Printer not working",
                "status": {
                    "id": "1",
                    "name": "Open",
                    "statusCategory": {
                        "id": 2,
                        "key": "new",
                        "name": "To Do",
                        "colorName": "blue-gray"
                    }
                },
                "priority": {
                    "id": "3",
                    "name": "Medium",
                    "iconUrl": null,
                    "statusColor": null
                },
                "assignee": {
                    "accountId": "user-123",
                    "displayName": "Jane Smith",
                    "emailAddress": "jane@example.com",
                    "active": true,
                    "avatarUrls": null
                },
                "reporter": {
                    "accountId": "user-456",
                    "displayName": "John Doe",
                    "emailAddress": "john@example.com",
                    "active": true,
                    "avatarUrls": null
                },
                "issuetype": {
                    "id": "10",
                    "name": "Service Request",
                    "description": "A service request",
                    "subtask": false,
                    "iconUrl": null
                },
                "created": "2025-01-15T10:30:00.000+0000",
                "updated": "2025-01-16T14:00:00.000+0000",
                "resolutiondate": null,
                "resolution": null
            }
        }
        """.data(using: .utf8)!

        let issue = try JSONDecoder().decode(Issue.self, from: json)
        XCTAssertEqual(issue.key, "ITHD-42")
        XCTAssertEqual(issue.fields.summary, "Printer not working")
        XCTAssertEqual(issue.fields.status?.name, "Open")
        XCTAssertEqual(issue.fields.status?.categoryKey, "new")
        XCTAssertEqual(issue.fields.priority?.name, "Medium")
        XCTAssertEqual(issue.fields.assignee?.displayName, "Jane Smith")
        XCTAssertEqual(issue.fields.reporter?.displayName, "John Doe")
        XCTAssertEqual(issue.fields.issuetype?.name, "Service Request")
        XCTAssertNil(issue.fields.resolvedDate)
    }

    func testDecodeSearchResult() throws {
        let json = """
        {
            "startAt": 0,
            "maxResults": 50,
            "total": 1,
            "issues": [
                {
                    "id": "10001",
                    "key": "TEST-1",
                    "fields": {
                        "summary": "Test Issue",
                        "status": null,
                        "priority": null,
                        "assignee": null,
                        "reporter": null,
                        "issuetype": null,
                        "created": null,
                        "updated": null,
                        "resolutiondate": null,
                        "resolution": null
                    }
                }
            ]
        }
        """.data(using: .utf8)!

        let result = try JSONDecoder().decode(SearchResult.self, from: json)
        XCTAssertEqual(result.total, 1)
        XCTAssertEqual(result.issues.count, 1)
        XCTAssertEqual(result.issues.first?.key, "TEST-1")
    }

    func testDecodeStatusCategory() throws {
        let json = """
        [
            {"id": 1, "key": "undefined", "name": "No Category", "colorName": "medium-gray"},
            {"id": 2, "key": "new", "name": "To Do", "colorName": "blue-gray"},
            {"id": 4, "key": "indeterminate", "name": "In Progress", "colorName": "yellow"},
            {"id": 3, "key": "done", "name": "Done", "colorName": "green"}
        ]
        """.data(using: .utf8)!

        let categories = try JSONDecoder().decode([StatusCategory].self, from: json)
        XCTAssertEqual(categories.count, 4)
        XCTAssertEqual(categories[1].key, "new")
        XCTAssertEqual(categories[3].key, "done")
    }
}
