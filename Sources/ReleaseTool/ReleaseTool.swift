import ArgumentParser
import Foundation
import Subprocess

@main
struct ReleaseTool: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "release-tool",
        abstract: "Automated release tool for MacCalendarSync"
    )

    @Flag(help: "Perform a dry run without actually creating a release")
    var dryRun = false

    mutating func run() async throws {
        print("Starting release process\(dryRun ? " (DRY RUN)" : "")...")

        // Generate version tag
        let versionTag = try await generateVersionTag()
        print("Generated version tag: \(versionTag)")

        // Check if release already exists
        if try await releaseExists(tag: versionTag) {
            print("Release \(versionTag) already exists, skipping...")
            return
        }

        // Build and test
        try await buildAndTest()

        // Create release
        try await createRelease(tag: versionTag, dryRun: dryRun)

        if !dryRun {
            print("Release \(versionTag) created successfully!")
        }
    }

    private func generateVersionTag() async throws -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd"
        let date = dateFormatter.string(from: Date())

        // Get existing releases for today
        let existingReleases = try await runCommand(
            "gh", "release", "list", "--limit", "100", "--json", "tagName",
            "--jq", ".[] | select(.tagName | startswith(\"\(date).\")) | .tagName"
        )

        let releaseCount =
            existingReleases.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? 0 : existingReleases.split(separator: "\n").count
        let count = releaseCount + 1
        return "\(date).\(count)"
    }

    private func releaseExists(tag: String) async throws -> Bool {
        // Get the last release
        let lastRelease = try? await runCommand(
            "gh", "release", "list", "--limit", "1", "--json", "tagName", "--jq", ".[0].tagName")
        
        guard let lastRelease = lastRelease, 
              !lastRelease.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            // No previous releases, so we should create one if there are commits
            return false
        }
        
        // Check if there are commits since the last release
        let commits = try await runCommand(
            "git", "log", "--oneline", "\(lastRelease.trimmingCharacters(in: .whitespacesAndNewlines))..HEAD")
        
        // If no commits since last release, consider the release as "already existing"
        return commits.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func buildAndTest() async throws {
        print("Building and testing...")
        _ = try await runCommand("swift", "build", "-c", "release")
        _ = try await runCommand("swift", "test", "--enable-swift-testing")
        print("Build and test completed successfully")
    }

    private func createRelease(tag: String, dryRun: Bool) async throws {
        if dryRun {
            print("DRY RUN: Would create release \(tag)")
            print(String(repeating: "=", count: 50))
        } else {
            print("Creating release \(tag)...")
        }

        // Get recent commits for release notes
        let lastRelease = try? await runCommand(
            "gh", "release", "list", "--limit", "1", "--json", "tagName", "--jq", ".[0].tagName")

        let commits: String
        if let lastRelease = lastRelease, !lastRelease.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            commits = try await runCommand(
                "git", "log", "--oneline", "\(lastRelease.trimmingCharacters(in: .whitespacesAndNewlines))..HEAD",
                "--pretty=format:- %s")
        } else {
            commits = try await runCommand("git", "log", "--oneline", "-n", "5", "--pretty=format:- %s")
        }

        // Create release notes
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd"
        let date = dateFormatter.string(from: Date())

        let releaseNotes = """
            # MacCalendarSync \(tag)

            Automated release created on \(date).

            ## Changes
            \(commits)

            ## Installation

            ### Homebrew (Recommended)
            ```bash
            brew tap ataias/mac-calendar-sync
            brew install mac-calendar-sync
            ```

            ### Manual Installation
            1. Download the source code from this release
            2. Extract and run:
            ```bash
            make install
            ```

            ## Requirements
            - macOS 15.0 or later
            - Swift 6.0 or later (for building from source)
            """

        if dryRun {
            print("Preview of release notes:")
            print(releaseNotes)
            print(String(repeating: "=", count: 50))
        } else {
            // Write release notes to temporary file
            let releaseNotesURL = FileManager.default.temporaryDirectory.appendingPathComponent(
                "release_notes.md")
            try releaseNotes.write(to: releaseNotesURL, atomically: true, encoding: .utf8)

            // Create the release
            _ = try await runCommand(
                "gh", "release", "create", tag,
                "--title", "MacCalendarSync \(tag)",
                "--notes-file", releaseNotesURL.path,
                "--generate-notes"
            )

            // Clean up temporary file
            try? FileManager.default.removeItem(at: releaseNotesURL)
        }
    }

    private func runCommand(_ arguments: String...) async throws -> String {
        let result = try await Subprocess.run(
            .name(arguments[0]),
            arguments: Arguments(Array(arguments.dropFirst())),
            environment: .inherit,
            output: .data(limit: 524288),
            error: .data(limit: 524288)
        )

        if result.terminationStatus.isSuccess {
            return String(data: result.standardOutput, encoding: .utf8) ?? ""
        } else {
            let errorMessage = String(data: result.standardError, encoding: .utf8) ?? "Unknown error"
            throw CommandError.failed(command: arguments.joined(separator: " "), error: errorMessage)
        }
    }
}

enum CommandError: Error {
    case failed(command: String, error: String)
}
