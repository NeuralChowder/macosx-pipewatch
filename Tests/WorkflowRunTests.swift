import XCTest
@testable import PipeWatch

final class WorkflowRunTests: XCTestCase {
    
    func testWorkflowStatusDecoding() throws {
        // Test successful workflow
        let successJSON = """
        {
            "id": 1,
            "name": "CI",
            "status": "completed",
            "conclusion": "success",
            "html_url": "https://github.com/test/repo/actions/runs/1",
            "created_at": "2026-01-14T10:00:00Z",
            "updated_at": "2026-01-14T10:05:00Z",
            "head_branch": "main",
            "event": "push",
            "repository": {
                "full_name": "test/repo"
            }
        }
        """
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let successData = successJSON.data(using: .utf8)!
        let successWorkflow = try decoder.decode(WorkflowRun.self, from: successData)
        
        XCTAssertEqual(successWorkflow.status, .success)
        XCTAssertEqual(successWorkflow.name, "CI")
        XCTAssertEqual(successWorkflow.workflowKey, "test/repo/CI")
    }
    
    func testFailedWorkflowDecoding() throws {
        let failureJSON = """
        {
            "id": 2,
            "name": "Tests",
            "status": "completed",
            "conclusion": "failure",
            "html_url": "https://github.com/test/repo/actions/runs/2",
            "created_at": "2026-01-14T10:00:00Z",
            "updated_at": "2026-01-14T10:05:00Z",
            "head_branch": "feature-branch",
            "event": "pull_request",
            "repository": {
                "full_name": "test/repo"
            }
        }
        """
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let failureData = failureJSON.data(using: .utf8)!
        let failureWorkflow = try decoder.decode(WorkflowRun.self, from: failureData)
        
        XCTAssertEqual(failureWorkflow.status, .failure)
        XCTAssertEqual(failureWorkflow.name, "Tests")
    }
    
    func testInProgressWorkflowDecoding() throws {
        let inProgressJSON = """
        {
            "id": 3,
            "name": "Build",
            "status": "in_progress",
            "conclusion": null,
            "html_url": "https://github.com/test/repo/actions/runs/3",
            "created_at": "2026-01-14T10:00:00Z",
            "updated_at": "2026-01-14T10:05:00Z",
            "head_branch": "main",
            "event": "push"
        }
        """
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let inProgressData = inProgressJSON.data(using: .utf8)!
        let inProgressWorkflow = try decoder.decode(WorkflowRun.self, from: inProgressData)
        
        XCTAssertEqual(inProgressWorkflow.status, .inProgress)
        XCTAssertEqual(inProgressWorkflow.workflowKey, "Build") // No repository, falls back to name
    }
    
    func testRepositoryFullName() {
        let repo = Repository(owner: "testuser", name: "testrepo")
        XCTAssertEqual(repo.fullName, "testuser/testrepo")
    }
    
    func testWorkflowKeyWithRepository() throws {
        let jsonWithRepo = """
        {
            "id": 1,
            "name": "CI",
            "status": "completed",
            "conclusion": "success",
            "html_url": "https://github.com/test/repo/actions/runs/1",
            "created_at": "2026-01-14T10:00:00Z",
            "updated_at": "2026-01-14T10:05:00Z",
            "head_branch": "main",
            "event": "push",
            "repository": {
                "full_name": "owner/repo"
            }
        }
        """
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let data = jsonWithRepo.data(using: .utf8)!
        let workflow = try decoder.decode(WorkflowRun.self, from: data)
        
        XCTAssertEqual(workflow.workflowKey, "owner/repo/CI")
    }
}
